import 'case_models.dart';
import 'course_models.dart';
import 'exercise_models.dart';
import 'lab_models.dart';
import 'reference_models.dart';

/// Todo el contenido del curso, ya cargado y con índices de búsqueda.
class CourseContent {
  CourseContent({
    required this.modules,
    required this.exercises,
    required this.cases,
    required this.labs,
    required this.misconceptions,
    required this.glossary,
    required this.careers,
  })  : _moduleById = {for (final m in modules) m.id: m},
        _lessonById = {for (final m in modules) for (final l in m.lessons) l.id: l},
        _exerciseById = {for (final e in exercises) e.id: e},
        _caseById = {for (final c in cases) c.id: c},
        _labById = {for (final l in labs) l.id: l},
        _experimentById = {for (final l in labs) for (final e in l.experiments) e.id: e},
        _misconceptionById = {for (final m in misconceptions) m.id: m};

  final List<CourseModule> modules;
  final List<Exercise> exercises;
  final List<CaseStudy> cases;
  final List<Lab> labs;
  final List<Misconception> misconceptions;
  final List<GlossaryTerm> glossary;
  final List<String> careers;

  final Map<String, CourseModule> _moduleById;
  final Map<String, Lesson> _lessonById;
  final Map<String, Exercise> _exerciseById;
  final Map<String, CaseStudy> _caseById;
  final Map<String, Lab> _labById;
  final Map<String, LabExperiment> _experimentById;
  final Map<String, Misconception> _misconceptionById;

  CourseModule? module(String id) => _moduleById[id];
  Lesson? lesson(String id) => _lessonById[id];
  Exercise? exercise(String id) => _exerciseById[id];
  CaseStudy? caseStudy(String id) => _caseById[id];
  Lab? lab(String id) => _labById[id];
  LabExperiment? experiment(String id) => _experimentById[id];
  Misconception? misconception(String id) => _misconceptionById[id];

  List<Exercise> exercisesOf(String moduleId) =>
      exercises.where((e) => e.moduleId == moduleId).toList();

  List<CaseStudy> casesFor(String moduleId) =>
      cases.where((c) => c.moduleRefs.contains(moduleId)).toList();

  Lab? labOf(String moduleId) {
    for (final l in labs) {
      if (l.moduleId == moduleId) return l;
    }
    return null;
  }

  int get lessonCount => modules.fold(0, (s, m) => s + m.lessons.length);
  int get cardCount =>
      modules.fold(0, (s, m) => s + m.lessons.fold(0, (t, l) => t + l.cards.length));
  int get experimentCount => labs.fold(0, (s, l) => s + l.experiments.length);
}
