import 'package:flutter_test/flutter_test.dart';
import 'package:inferencia_estadistica/domain/models/case_models.dart';
import 'package:inferencia_estadistica/domain/models/course_models.dart';
import 'package:inferencia_estadistica/domain/models/exercise_models.dart';
import 'package:inferencia_estadistica/presentation/charts/lesson_visuals.dart';

import '../support/test_content.dart';

/// Integridad del contenido: lo que la app promete debe existir.
void main() {
  final c = loadTestContent();

  test('volumen mínimo del MVP', () {
    expect(c.modules.length, 5);
    expect(c.lessonCount, greaterThanOrEqualTo(20));
    expect(c.exercises.length, greaterThanOrEqualTo(50));
    expect(c.cases.length, greaterThanOrEqualTo(10));
    expect(c.experimentCount, greaterThanOrEqualTo(13));
    expect(c.misconceptions.length, greaterThanOrEqualTo(25));
    expect(c.glossary.length, greaterThanOrEqualTo(40));
  });

  test('ids únicos', () {
    final ids = [
      ...c.modules.map((m) => m.id),
      for (final m in c.modules) ...m.lessons.map((l) => l.id),
      ...c.exercises.map((e) => e.id),
      ...c.cases.map((x) => x.id),
      ...c.labs.map((l) => l.id),
      for (final l in c.labs) ...l.experiments.map((e) => e.id),
      ...c.misconceptions.map((m) => m.id),
    ];
    expect(ids.toSet().length, ids.length);
  });

  test('cada módulo tiene laboratorio, lecciones y 10 ejercicios', () {
    for (final m in c.modules) {
      expect(c.lab(m.labId), isNotNull, reason: m.id);
      expect(c.labOf(m.id)?.id, m.labId, reason: m.id);
      expect(m.lessons.length, greaterThanOrEqualTo(4), reason: m.id);
      expect(c.exercisesOf(m.id).length, greaterThanOrEqualTo(10), reason: m.id);
    }
  });

  test('las tarjetas de comprobación tienen respuesta y las ilustraciones existen', () {
    for (final m in c.modules) {
      for (final l in m.lessons) {
        for (final card in l.cards) {
          if (card.type == CardType.check) {
            expect(card.answer, isNotNull, reason: l.id);
            expect(card.answer! < card.options.length, isTrue, reason: l.id);
            expect(card.explanation, isNotNull, reason: l.id);
          }
          if (card.visual != null) {
            expect(LessonVisual.known, contains(card.visual), reason: '${l.id}: ${card.visual}');
          }
          if (card.tag != null) expect(c.misconception(card.tag!), isNotNull, reason: l.id);
        }
      }
    }
  });

  void checkOptions(String where, List<ChoiceOption> options) {
    expect(options.where((o) => o.correct).length, 1, reason: '$where: una sola correcta');
    for (final o in options) {
      if (o.correct) {
        expect(o.tag, isNull, reason: '$where: la correcta no lleva etiqueta');
      } else {
        expect(o.feedback, isNotEmpty, reason: '$where: distractor sin retroalimentación');
      }
      if (o.tag != null) expect(c.misconception(o.tag!), isNotNull, reason: '$where: ${o.tag}');
    }
  }

  test('ejercicios bien formados', () {
    for (final e in c.exercises) {
      expect(c.module(e.moduleId), isNotNull, reason: e.id);
      expect(e.explanation, isNotEmpty, reason: e.id);
      if (e.lessonRef != null) expect(c.lesson(e.lessonRef!), isNotNull, reason: e.id);
      switch (e) {
        case final ChoiceExercise x:
          checkOptions(x.id, x.options);
        case final DecisionExercise x:
          checkOptions('${x.id}/decisión', x.options);
          checkOptions('${x.id}/justificación', x.justifications);
        case final NumericExercise x:
          for (final t in x.traps) {
            expect((t.value - x.answer).abs(), greaterThan(x.tolerance), reason: '${x.id}: trampa = respuesta');
          }
        case final ConclusionExercise x:
          for (final s in x.slots) {
            checkOptions('${x.id}/${s.label}', s.options);
          }
          expect(x.model, isNotEmpty);
        case final ClassifyExercise x:
          final used = x.items.map((i) => i.category).toSet();
          expect(used, {for (var i = 0; i < x.categories.length; i++) i}, reason: '${x.id}: categoría sin ítems');
      }
    }
  });

  test('casos bien formados', () {
    for (final cs in c.cases) {
      expect(cs.steps, isNotEmpty, reason: cs.id);
      for (final s in cs.steps) {
        if (s.type == CaseStepType.choice) checkOptions('${cs.id}/${s.title}', s.options);
        if (s.type == CaseStepType.compute) expect(cs.analysis, isNotNull, reason: cs.id);
      }
      for (final m in cs.moduleRefs) {
        expect(c.module(m), isNotNull, reason: cs.id);
      }
    }
  });

  test('los casos cubren al menos 10 carreras distintas', () {
    expect(c.cases.map((x) => x.career).toSet().length, greaterThanOrEqualTo(10));
  });

  test('experimentos: una predicción correcta y conclusión', () {
    for (final l in c.labs) {
      for (final e in l.experiments) {
        checkOptions(e.id, e.predictions);
        expect(e.reveal, isNotEmpty);
        expect(e.minRuns, greaterThan(0));
      }
    }
  });

  test('toda confusión catalogada la produce algún distractor', () {
    final produced = <String>{
      for (final e in c.exercises) ...e.detectableTags,
      for (final cs in c.cases) ...cs.detectableTags,
    };
    final orphans = c.misconceptions.map((m) => m.id).toSet().difference(produced);
    expect(orphans, isEmpty, reason: 'sin distractor: $orphans');
  });

  test('los remedios apuntan a lecciones y experimentos reales', () {
    for (final m in c.misconceptions) {
      if (m.remedyLesson != null) expect(c.lesson(m.remedyLesson!), isNotNull, reason: m.id);
      if (m.remedyExperiment != null) expect(c.experiment(m.remedyExperiment!), isNotNull, reason: m.id);
      expect(m.remedyLesson != null || m.remedyExperiment != null, isTrue, reason: '${m.id}: sin remedio');
    }
  });
}
