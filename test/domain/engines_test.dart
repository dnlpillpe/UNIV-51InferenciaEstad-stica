import 'package:flutter_test/flutter_test.dart';
import 'package:inferencia_estadistica/domain/engine/diagnosis_engine.dart';
import 'package:inferencia_estadistica/domain/engine/grading_engine.dart';
import 'package:inferencia_estadistica/domain/engine/mastery_engine.dart';
import 'package:inferencia_estadistica/domain/engine/recommendation_engine.dart';
import 'package:inferencia_estadistica/domain/models/exercise_models.dart';
import 'package:inferencia_estadistica/domain/models/progress_models.dart';

import '../support/test_content.dart';

void main() {
  final content = loadTestContent();
  const grading = GradingEngine();

  T ex<T extends Exercise>(String id) => content.exercise(id)! as T;

  group('Corrección', () {
    test('elección: el distractor devuelve su confusión', () {
      final e = ex<ChoiceExercise>('ex_m2_02');
      final wrong = e.options.indexWhere((o) => o.tag == 'precision_lineal_n');
      final r = grading.grade(e, ChoiceAnswer(wrong));
      expect(r.score, 0);
      expect(r.tags, ['precision_lineal_n']);
      final right = e.options.indexWhere((o) => o.correct);
      expect(grading.grade(e, ChoiceAnswer(right)).isCorrect, isTrue);
    });

    test('decisión: regla 60/40 y acierto ciego', () {
      final e = ex<DecisionExercise>('ex_m4_04');
      final c = e.options.indexWhere((o) => o.correct);
      final jBad = e.justifications.indexWhere((o) => o.tag == 'no_rechazar_es_aceptar');
      final jOk = e.justifications.indexWhere((o) => o.correct);
      final blind = grading.grade(e, DecisionAnswer(c, jBad));
      expect(blind.score, closeTo(0.6, 1e-9));
      expect(blind.blindHit, isTrue);
      expect(blind.tags, contains('no_rechazar_es_aceptar'));
      expect(grading.grade(e, DecisionAnswer(c, jOk)).score, closeTo(1, 1e-9));
    });

    test('el acierto ciego sistemático no alcanza el umbral de competencia', () {
      expect(GradingEngine.decisionWeight, lessThan(MasteryEngine.competentThreshold));
    });

    test('numérico: la trampa σ en lugar de σ/√n se reconoce', () {
      final e = ex<NumericExercise>('ex_m2_01');
      expect(grading.grade(e, const NumericAnswer(3)).isCorrect, isTrue);
      final trap = grading.grade(e, const NumericAnswer(15));
      expect(trap.tags, ['de_vs_error_estandar']);
      final other = grading.grade(e, const NumericAnswer(7));
      expect(other.score, 0);
      expect(other.tags, isEmpty);
    });

    test('conclusión: puntaje proporcional a las casillas correctas', () {
      final e = ex<ConclusionExercise>('ex_m3_02');
      final best = [for (final s in e.slots) s.options.indexWhere((o) => o.correct)];
      expect(grading.grade(e, ConclusionAnswer(best)).isCorrect, isTrue);
      final oneWrong = [...best];
      oneWrong[0] = e.slots[0].options.indexWhere((o) => o.tag == 'ic_probabilidad_parametro');
      final r = grading.grade(e, ConclusionAnswer(oneWrong));
      expect(r.score, closeTo(2 / 3, 1e-9));
      expect(r.tags, ['ic_probabilidad_parametro']);
    });

    test('clasificación: cada ítem mal ubicado aporta su etiqueta', () {
      final e = ex<ClassifyExercise>('ex_m4_05');
      final all = [for (final i in e.items) i.category];
      expect(grading.grade(e, ClassifyAnswer(all)).isCorrect, isTrue);
      final swapped = [for (final i in e.items) 1 - i.category];
      final r = grading.grade(e, ClassifyAnswer(swapped));
      expect(r.score, 0);
      expect(r.tags.toSet(), {'errores_tipo_confundidos'});
    });
  });

  group('Dominio', () {
    const mastery = MasteryEngine();
    final m1 = content.module('m1')!;

    test('sin actividad: sin iniciar', () {
      final mm = mastery.forModule(m1, content, const ProgressState());
      expect(mm.level, MasteryLevel.notStarted);
      expect(mm.total, 0);
    });

    test('todo perfecto: dominio', () {
      final p = ProgressState(
        completedLessons: {for (final l in m1.lessons) l.id},
        completedExperiments: {for (final e in content.labOf('m1')!.experiments) e.id},
        exercises: {
          for (final e in content.exercisesOf('m1'))
            e.id: const ExerciseRecord(bestScore: 1, lastScore: 1, attempts: 1, lastAt: 0),
        },
        cases: {for (final c in content.casesFor('m1')) c.id: 1.0},
      );
      final mm = mastery.forModule(m1, content, p);
      expect(mm.total, closeTo(1, 1e-9));
      expect(mm.level, MasteryLevel.mastered);
    });

    test('solo aciertos ciegos: no llega a competente', () {
      final p = ProgressState(
        completedLessons: {for (final l in m1.lessons) l.id},
        completedExperiments: {for (final e in content.labOf('m1')!.experiments) e.id},
        exercises: {
          for (final e in content.exercisesOf('m1'))
            e.id: const ExerciseRecord(bestScore: 0.6, lastScore: 0.6, attempts: 1, lastAt: 0),
        },
        cases: {for (final c in content.casesFor('m1')) c.id: 0.6},
      );
      final mm = mastery.forModule(m1, content, p);
      expect(mm.total, closeTo(0.72, 1e-9));
      expect(mm.practice, closeTo(0.6, 1e-9));
      expect(mm.level, MasteryLevel.inProgress);
      expect(mm.isCompetent, isFalse);
    });
  });

  group('Diagnóstico', () {
    const diag = DiagnosisEngine();

    test('los errores repetidos activan una confusión', () {
      final p = ProgressState(tagEvents: [
        for (var i = 0; i < 3; i++) TagEvent('p_prob_h0', 1, i),
        const TagEvent('alfa_vs_p', 1, 5),
      ]);
      final active = diag.active(content, p);
      expect(active.first.misconception.id, 'p_prob_h0');
      expect(active.first.occurrences, 3);
    });

    test('los aciertos posteriores la desactivan', () {
      final p = ProgressState(tagEvents: [
        const TagEvent('p_prob_h0', 1, 0),
        const TagEvent('p_prob_h0', -0.5, 1),
        const TagEvent('p_prob_h0', -0.5, 2),
      ]);
      expect(diag.active(content, p), isEmpty);
    });

    test('las etiquetas desconocidas se ignoran', () {
      const p = ProgressState(tagEvents: [TagEvent('no_existe', 5, 0)]);
      expect(diag.active(content, p), isEmpty);
    });
  });

  group('Recomendación', () {
    const rec = RecommendationEngine();

    test('al empezar sugiere la primera lección', () {
      final r = rec.next(content, const ProgressState());
      expect(r.kind, RecommendationKind.lesson);
      expect(r.targetId, 'm1_l1');
    });

    test('una confusión fuerte se atiende primero', () {
      final p = ProgressState(tagEvents: [for (var i = 0; i < 3; i++) TagEvent('ic_probabilidad_parametro', 1, i)]);
      final r = rec.next(content, p);
      expect(r.kind, RecommendationKind.remedy);
      expect(r.targetId, 'e3_1');
    });

    test('lecciones hechas → experimento', () {
      final p = ProgressState(completedLessons: {for (final l in content.module('m1')!.lessons) l.id});
      final r = rec.next(content, p);
      expect(r.kind, RecommendationKind.experiment);
      expect(r.targetId, 'e1_1');
    });
  });

  group('Persistencia', () {
    test('ProgressState sobrevive a JSON', () {
      final p = ProgressState(
        completedLessons: const {'m1_l1'},
        exercises: const {'ex_m1_01': ExerciseRecord(bestScore: 0.5, lastScore: 0.5, attempts: 2, lastAt: 9)},
        cases: const {'case_minas': 0.8},
        completedExperiments: const {'e1_1'},
        predictions: const {'e1_1': false},
        tagEvents: const [TagEvent('alfa_vs_p', 1, 3)],
        decisionAttempts: 4,
        blindHits: 1,
        career: 'Economía',
        onboardingDone: true,
        theme: AppThemePreference.dark,
        activeDays: const {20260911},
      );
      final back = ProgressState.fromJson(p.toJson());
      expect(back.completedLessons, p.completedLessons);
      expect(back.exercises['ex_m1_01']!.attempts, 2);
      expect(back.cases['case_minas'], 0.8);
      expect(back.predictions['e1_1'], isFalse);
      expect(back.tagEvents.single.tag, 'alfa_vs_p');
      expect(back.blindHits, 1);
      expect(back.career, 'Economía');
      expect(back.theme, AppThemePreference.dark);
      expect(back.activeDays, {20260911});
    });

    test('reiniciar conserva los ajustes', () {
      const p = ProgressState(completedLessons: {'m1_l1'}, career: 'Biología', onboardingDone: true);
      final r = p.resetLearning();
      expect(r.completedLessons, isEmpty);
      expect(r.career, 'Biología');
      expect(r.onboardingDone, isTrue);
    });
  });
}
