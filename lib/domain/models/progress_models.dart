import 'json_utils.dart';

class ExerciseRecord {
  const ExerciseRecord({
    required this.bestScore,
    required this.lastScore,
    required this.attempts,
    required this.lastAt,
  });

  final double bestScore;
  final double lastScore;
  final int attempts;
  final int lastAt;

  ExerciseRecord register(double score, int now) => ExerciseRecord(
        bestScore: score > bestScore ? score : bestScore,
        lastScore: score,
        attempts: attempts + 1,
        lastAt: now,
      );

  Json toJson() => {'b': bestScore, 'l': lastScore, 'a': attempts, 't': lastAt};

  factory ExerciseRecord.fromJson(Json j) => ExerciseRecord(
        bestScore: jDouble(j, 'b'),
        lastScore: jDouble(j, 'l'),
        attempts: jInt(j, 'a'),
        lastAt: jInt(j, 't'),
      );
}

/// Evento de confusión: `weight` positivo cuando se eligió un distractor
/// con esa etiqueta; negativo cuando luego se respondió bien un ítem que
/// podía detectarla (la confusión se va «resolviendo»).
class TagEvent {
  const TagEvent(this.tag, this.weight, this.at);
  final String tag;
  final double weight;
  final int at;

  Json toJson() => {'g': tag, 'w': weight, 't': at};

  factory TagEvent.fromJson(Json j) => TagEvent(jStr(j, 'g'), jDouble(j, 'w', 1), jInt(j, 't'));
}

enum AppThemePreference { system, light, dark }

/// Estado completo del estudiante. Se persiste como un único JSON local.
class ProgressState {
  const ProgressState({
    this.completedLessons = const {},
    this.exercises = const {},
    this.cases = const {},
    this.completedExperiments = const {},
    this.predictions = const {},
    this.tagEvents = const [],
    this.decisionAttempts = 0,
    this.blindHits = 0,
    this.career,
    this.onboardingDone = false,
    this.theme = AppThemePreference.system,
    this.activeDays = const {},
  });

  final Set<String> completedLessons;
  final Map<String, ExerciseRecord> exercises;
  final Map<String, double> cases;
  final Set<String> completedExperiments;

  /// experimento → ¿la predicción inicial fue correcta?
  final Map<String, bool> predictions;
  final List<TagEvent> tagEvents;

  /// Para el indicador de «acierto ciego» (decisión correcta, porqué no).
  final int decisionAttempts;
  final int blindHits;

  final String? career;
  final bool onboardingDone;
  final AppThemePreference theme;

  /// Días con actividad, como AAAAMMDD.
  final Set<int> activeDays;

  static const int maxTagEvents = 400;

  bool get isEmpty =>
      completedLessons.isEmpty && exercises.isEmpty && cases.isEmpty && completedExperiments.isEmpty;

  ProgressState copyWith({
    Set<String>? completedLessons,
    Map<String, ExerciseRecord>? exercises,
    Map<String, double>? cases,
    Set<String>? completedExperiments,
    Map<String, bool>? predictions,
    List<TagEvent>? tagEvents,
    int? decisionAttempts,
    int? blindHits,
    String? career,
    bool clearCareer = false,
    bool? onboardingDone,
    AppThemePreference? theme,
    Set<int>? activeDays,
  }) =>
      ProgressState(
        completedLessons: completedLessons ?? this.completedLessons,
        exercises: exercises ?? this.exercises,
        cases: cases ?? this.cases,
        completedExperiments: completedExperiments ?? this.completedExperiments,
        predictions: predictions ?? this.predictions,
        tagEvents: tagEvents ?? this.tagEvents,
        decisionAttempts: decisionAttempts ?? this.decisionAttempts,
        blindHits: blindHits ?? this.blindHits,
        career: clearCareer ? null : (career ?? this.career),
        onboardingDone: onboardingDone ?? this.onboardingDone,
        theme: theme ?? this.theme,
        activeDays: activeDays ?? this.activeDays,
      );

  /// Borra el aprendizaje pero conserva los ajustes.
  ProgressState resetLearning() => ProgressState(
        career: career,
        onboardingDone: onboardingDone,
        theme: theme,
      );

  Json toJson() => {
        'v': 1,
        'lessons': completedLessons.toList(),
        'exercises': exercises.map((k, v) => MapEntry(k, v.toJson())),
        'cases': cases,
        'experiments': completedExperiments.toList(),
        'predictions': predictions,
        'tags': tagEvents.map((e) => e.toJson()).toList(),
        'decisions': decisionAttempts,
        'blind': blindHits,
        'career': career,
        'onboarding': onboardingDone,
        'theme': theme.name,
        'days': activeDays.toList(),
      };

  factory ProgressState.fromJson(Json j) {
    final ex = <String, ExerciseRecord>{};
    final rawEx = j['exercises'];
    if (rawEx is Map) {
      rawEx.forEach((k, v) {
        if (v is Map) ex[k.toString()] = ExerciseRecord.fromJson(Map<String, dynamic>.from(v));
      });
    }
    final cs = <String, double>{};
    final rawCases = j['cases'];
    if (rawCases is Map) {
      rawCases.forEach((k, v) {
        if (v is num) cs[k.toString()] = v.toDouble();
      });
    }
    final preds = <String, bool>{};
    final rawPreds = j['predictions'];
    if (rawPreds is Map) {
      rawPreds.forEach((k, v) {
        if (v is bool) preds[k.toString()] = v;
      });
    }
    final days = (j['days'] is List)
        ? (j['days'] as List).whereType<num>().map((e) => e.round()).toSet()
        : <int>{};
    return ProgressState(
      completedLessons: jStrings(j, 'lessons').toSet(),
      exercises: ex,
      cases: cs,
      completedExperiments: jStrings(j, 'experiments').toSet(),
      predictions: preds,
      tagEvents: jList(j, 'tags').map(TagEvent.fromJson).toList(),
      decisionAttempts: jInt(j, 'decisions'),
      blindHits: jInt(j, 'blind'),
      career: jStrOrNull(j, 'career'),
      onboardingDone: jBool(j, 'onboarding'),
      theme: AppThemePreference.values.firstWhere(
        (t) => t.name == jStr(j, 'theme', 'system'),
        orElse: () => AppThemePreference.system,
      ),
      activeDays: days,
    );
  }
}
