import '../models/course_content.dart';
import '../models/course_models.dart';
import '../models/progress_models.dart';

enum MasteryLevel {
  notStarted('Sin iniciar'),
  inProgress('En progreso'),
  competent('Competente'),
  mastered('Dominio');

  const MasteryLevel(this.label);
  final String label;
}

class ModuleMastery {
  const ModuleMastery({
    required this.moduleId,
    required this.lessons,
    required this.experiments,
    required this.practice,
    required this.total,
    required this.level,
    required this.practiceDone,
    required this.practiceTotal,
  });

  final String moduleId;

  /// Fracciones entre 0 y 1.
  final double lessons;
  final double experiments;
  final double practice;
  final double total;
  final MasteryLevel level;
  final int practiceDone;

  bool get isCompetent => level == MasteryLevel.competent || level == MasteryLevel.mastered;
  final int practiceTotal;
}

/// Calcula el dominio de cada módulo.
///
/// Dominio = 0,15 lecciones + 0,15 experimentos + 0,70 práctica.
/// La práctica es el promedio del mejor puntaje de cada ejercicio (y de cada
/// caso vinculado al módulo), contando con 0 lo no intentado.
/// «Competente» exige 0,70 en el total y también 0,70 en la práctica. No es
/// 0,60 porque 0,60 es exactamente lo que obtiene quien acierta todas las
/// decisiones y falla todos los porqués (regla 60/40): leer las lecciones y
/// hacer los experimentos no compensa razonar mal.
class MasteryEngine {
  const MasteryEngine();

  static const double competentThreshold = 0.70;
  static const double masteredThreshold = 0.90;
  static const double masteredPractice = 0.85;

  ModuleMastery forModule(CourseModule m, CourseContent c, ProgressState p) {
    final lessons = m.lessons.isEmpty
        ? 0.0
        : m.lessons.where((l) => p.completedLessons.contains(l.id)).length / m.lessons.length;
    final lab = c.labOf(m.id);
    final experiments = (lab == null || lab.experiments.isEmpty)
        ? 0.0
        : lab.experiments.where((e) => p.completedExperiments.contains(e.id)).length /
            lab.experiments.length;
    final exercises = c.exercisesOf(m.id);
    final cases = c.casesFor(m.id);
    final scores = <double>[
      for (final e in exercises) p.exercises[e.id]?.bestScore ?? 0,
      for (final cs in cases) p.cases[cs.id] ?? 0,
    ];
    final done = exercises.where((e) => p.exercises.containsKey(e.id)).length +
        cases.where((cs) => p.cases.containsKey(cs.id)).length;
    final practice = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
    final total = 0.15 * lessons + 0.15 * experiments + 0.70 * practice;
    final started = lessons > 0 || experiments > 0 || done > 0;
    final level = !started
        ? MasteryLevel.notStarted
        : (total >= masteredThreshold && practice >= masteredPractice)
            ? MasteryLevel.mastered
            : (total >= competentThreshold && practice >= competentThreshold)
                ? MasteryLevel.competent
                : MasteryLevel.inProgress;
    return ModuleMastery(
      moduleId: m.id,
      lessons: lessons,
      experiments: experiments,
      practice: practice,
      total: total,
      level: level,
      practiceDone: done,
      practiceTotal: scores.length,
    );
  }

  double overall(CourseContent c, ProgressState p) {
    if (c.modules.isEmpty) return 0;
    final sum = c.modules.fold<double>(0, (s, m) => s + forModule(m, c, p).total);
    return sum / c.modules.length;
  }
}
