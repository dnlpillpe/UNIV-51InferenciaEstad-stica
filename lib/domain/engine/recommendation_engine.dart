import '../models/course_content.dart';
import '../models/progress_models.dart';
import 'diagnosis_engine.dart';
import 'mastery_engine.dart';

enum RecommendationKind { lesson, experiment, practice, caseStudy, remedy, done }

class Recommendation {
  const Recommendation({
    required this.kind,
    required this.title,
    required this.reason,
    this.moduleId,
    this.targetId,
  });

  final RecommendationKind kind;
  final String title;
  final String reason;
  final String? moduleId;
  final String? targetId;
}

/// Decide la siguiente actividad sugerida en Inicio.
///
/// Prioridad: 1) una confusión activa fuerte → su remedio; 2) el primer
/// módulo no competente: lección pendiente → experimento → práctica;
/// 3) casos de la carrera del estudiante.
class RecommendationEngine {
  const RecommendationEngine();

  Recommendation next(CourseContent c, ProgressState p) {
    const diag = DiagnosisEngine();
    final active = diag.active(c, p, limit: 1);
    if (active.isNotEmpty && active.first.strength >= 1.5) {
      final m = active.first.misconception;
      final exp = m.remedyExperiment;
      if (exp != null && c.experiment(exp) != null) {
        return Recommendation(
          kind: RecommendationKind.remedy,
          title: c.experiment(exp)!.title,
          reason: 'Varias respuestas tuyas apuntan a «${m.name}». Este experimento lo muestra.',
          moduleId: m.moduleId,
          targetId: exp,
        );
      }
      final les = m.remedyLesson;
      if (les != null && c.lesson(les) != null) {
        return Recommendation(
          kind: RecommendationKind.remedy,
          title: c.lesson(les)!.title,
          reason: 'Varias respuestas tuyas apuntan a «${m.name}». Repasa esta lección.',
          moduleId: m.moduleId,
          targetId: les,
        );
      }
    }

    const mastery = MasteryEngine();
    for (final m in c.modules) {
      final mm = mastery.forModule(m, c, p);
      if (mm.isCompetent) continue;
      for (final l in m.lessons) {
        if (!p.completedLessons.contains(l.id)) {
          return Recommendation(
            kind: RecommendationKind.lesson,
            title: l.title,
            reason: 'Módulo ${m.number} · ${m.title}',
            moduleId: m.id,
            targetId: l.id,
          );
        }
      }
      final lab = c.labOf(m.id);
      if (lab != null) {
        for (final e in lab.experiments) {
          if (!p.completedExperiments.contains(e.id)) {
            return Recommendation(
              kind: RecommendationKind.experiment,
              title: e.title,
              reason: 'Laboratorio · ${lab.title}',
              moduleId: m.id,
              targetId: e.id,
            );
          }
        }
      }
      return Recommendation(
        kind: RecommendationKind.practice,
        title: 'Práctica: ${m.title}',
        reason: 'Llega a 70 % de dominio y de práctica para ser competente en este módulo.',
        moduleId: m.id,
      );
    }

    final career = p.career;
    final pending = c.cases.where((cs) => !p.cases.containsKey(cs.id)).toList();
    if (pending.isNotEmpty) {
      pending.sort((a, b) {
        final am = a.career == career ? 0 : 1;
        final bm = b.career == career ? 0 : 1;
        return am.compareTo(bm);
      });
      final cs = pending.first;
      return Recommendation(
        kind: RecommendationKind.caseStudy,
        title: cs.title,
        reason: 'Caso profesional · ${cs.career}',
        targetId: cs.id,
      );
    }
    return const Recommendation(
      kind: RecommendationKind.done,
      title: 'Curso completo',
      reason: 'Repite los casos o vuelve a los laboratorios con otros parámetros.',
    );
  }
}
