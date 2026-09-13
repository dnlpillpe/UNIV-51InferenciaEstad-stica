import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/engine/diagnosis_engine.dart';
import '../../domain/engine/grading_engine.dart';
import '../../domain/models/exercise_models.dart';
import '../../domain/models/progress_models.dart';
import 'app_providers.dart';

/// ViewModel del progreso: única puerta de escritura del estado del
/// estudiante. Cada cambio se persiste de inmediato.
class ProgressNotifier extends Notifier<ProgressState> {
  @override
  ProgressState build() => ref.watch(progressRepositoryProvider).read();

  int Function() clock = () => DateTime.now().millisecondsSinceEpoch;

  void _set(ProgressState s) {
    final now = DateTime.fromMillisecondsSinceEpoch(clock());
    final day = now.year * 10000 + now.month * 100 + now.day;
    final withDay = s.activeDays.contains(day) ? s : s.copyWith(activeDays: {...s.activeDays, day});
    state = withDay;
    ref.read(progressRepositoryProvider).write(withDay);
  }

  void completeLesson(String lessonId) {
    if (state.completedLessons.contains(lessonId)) return;
    _set(state.copyWith(completedLessons: {...state.completedLessons, lessonId}));
  }

  /// Registra una respuesta corregida y actualiza el historial de confusiones.
  void recordExercise(Exercise exercise, GradeResult result) {
    final now = clock();
    final prev = state.exercises[exercise.id];
    final rec = prev == null
        ? ExerciseRecord(bestScore: result.score, lastScore: result.score, attempts: 1, lastAt: now)
        : prev.register(result.score, now);
    final events = _withTagEvents(result.tags, result.isCorrect ? exercise.detectableTags : const {}, now);
    _set(state.copyWith(
      exercises: {...state.exercises, exercise.id: rec},
      tagEvents: events,
      decisionAttempts: state.decisionAttempts + (result.isDecision ? 1 : 0),
      blindHits: state.blindHits + (result.blindHit ? 1 : 0),
    ));
  }

  /// Registra un caso terminado. `score` es la fracción de pasos acertados
  /// al primer intento; `tags` las confusiones elegidas por el camino.
  void recordCase(String caseId, double score, List<String> tags, Set<String> resolved) {
    final prev = state.cases[caseId];
    final best = prev == null || score > prev ? score : prev;
    _set(state.copyWith(
      cases: {...state.cases, caseId: best},
      tagEvents: _withTagEvents(tags, resolved, clock()),
    ));
  }

  void completeExperiment(String experimentId, {required bool predictionCorrect}) {
    final preds = state.predictions.containsKey(experimentId)
        ? state.predictions
        : {...state.predictions, experimentId: predictionCorrect};
    _set(state.copyWith(
      completedExperiments: {...state.completedExperiments, experimentId},
      predictions: preds,
    ));
  }

  void setCareer(String? career) =>
      _set(career == null ? state.copyWith(clearCareer: true) : state.copyWith(career: career));

  void setTheme(AppThemePreference theme) => _set(state.copyWith(theme: theme));

  void finishOnboarding({String? career}) =>
      _set(state.copyWith(onboardingDone: true, career: career));

  void resetLearning() => _set(state.resetLearning());

  List<TagEvent> _withTagEvents(List<String> errors, Set<String> resolvedCandidates, int now) {
    final events = [...state.tagEvents];
    for (final t in errors) {
      events.add(TagEvent(t, 1, now));
    }
    if (resolvedCandidates.isNotEmpty) {
      final strengths = const DiagnosisEngine().strengths(state);
      for (final t in resolvedCandidates) {
        if ((strengths[t] ?? 0) > 0 && !errors.contains(t)) {
          events.add(TagEvent(t, -0.5, now));
        }
      }
    }
    if (events.length > ProgressState.maxTagEvents) {
      events.removeRange(0, events.length - ProgressState.maxTagEvents);
    }
    return events;
  }
}
