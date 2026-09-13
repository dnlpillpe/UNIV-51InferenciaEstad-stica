import 'json_utils.dart';
import 'verify_claim.dart';

/// Alternativa con retroalimentación propia. Si es incorrecta, `tag`
/// declara la confusión conceptual que la hace atractiva.
class ChoiceOption {
  const ChoiceOption({required this.text, this.correct = false, this.feedback = '', this.tag});

  final String text;
  final bool correct;
  final String feedback;
  final String? tag;

  factory ChoiceOption.fromJson(Json j) => ChoiceOption(
        text: jStr(j, 'text'),
        correct: jBool(j, 'correct'),
        feedback: jStr(j, 'feedback'),
        tag: jStrOrNull(j, 'tag'),
      );
}

/// Valor numérico erróneo típico (p. ej. usar σ en lugar de σ/√n).
class NumericTrap {
  const NumericTrap({required this.value, required this.tolerance, required this.feedback, this.tag});

  final double value;
  final double tolerance;
  final String feedback;
  final String? tag;

  factory NumericTrap.fromJson(Json j) => NumericTrap(
        value: jDouble(j, 'value'),
        tolerance: jDouble(j, 'tol', 0.01),
        feedback: jStr(j, 'feedback'),
        tag: jStrOrNull(j, 'tag'),
      );
}

class ConclusionSlot {
  const ConclusionSlot({required this.label, required this.options});

  final String label;
  final List<ChoiceOption> options;

  factory ConclusionSlot.fromJson(Json j) => ConclusionSlot(
        label: jStr(j, 'label'),
        options: jList(j, 'options').map(ChoiceOption.fromJson).toList(),
      );
}

class ClassifyItem {
  const ClassifyItem({required this.text, required this.category, this.feedback = '', this.tag});

  final String text;
  final int category;
  final String feedback;
  final String? tag;

  factory ClassifyItem.fromJson(Json j) => ClassifyItem(
        text: jStr(j, 'text'),
        category: jInt(j, 'category'),
        feedback: jStr(j, 'feedback'),
        tag: jStrOrNull(j, 'tag'),
      );
}

enum ExerciseType { choice, decision, numeric, conclusion, classify }

extension ExerciseTypeLabel on ExerciseType {
  String get label => switch (this) {
        ExerciseType.choice => 'Elige',
        ExerciseType.decision => 'Decide y justifica',
        ExerciseType.numeric => 'Calcula',
        ExerciseType.conclusion => 'Redacta la conclusión',
        ExerciseType.classify => 'Clasifica',
      };
}

/// Ejercicio. Clase sellada: cada tipo tiene su propia interacción.
sealed class Exercise {
  const Exercise({
    required this.id,
    required this.moduleId,
    required this.difficulty,
    required this.prompt,
    required this.explanation,
    this.context,
    this.lessonRef,
    this.verify = const [],
  });

  final String id;
  final String moduleId;
  final int difficulty;
  final String prompt;
  final String explanation;
  final String? context;
  final String? lessonRef;
  final List<VerifyClaim> verify;

  ExerciseType get type;

  /// Todas las etiquetas de confusión que este ejercicio puede detectar.
  Set<String> get detectableTags;

  static Exercise fromJson(Json j) {
    final id = jStr(j, 'id');
    final moduleId = jStr(j, 'module');
    final difficulty = jInt(j, 'difficulty', 1);
    final prompt = jStr(j, 'prompt');
    final explanation = jStr(j, 'explanation');
    final context = jStrOrNull(j, 'context');
    final lessonRef = jStrOrNull(j, 'lessonRef');
    final verify = jList(j, 'verify').map(VerifyClaim.fromJson).toList();
    switch (jStr(j, 'type')) {
      case 'decision':
        return DecisionExercise(
          id: id, moduleId: moduleId, difficulty: difficulty, prompt: prompt,
          explanation: explanation, context: context, lessonRef: lessonRef, verify: verify,
          options: jList(j, 'options').map(ChoiceOption.fromJson).toList(),
          justificationPrompt: jStr(j, 'justificationPrompt', '¿Por qué?'),
          justifications: jList(j, 'justifications').map(ChoiceOption.fromJson).toList(),
        );
      case 'numeric':
        return NumericExercise(
          id: id, moduleId: moduleId, difficulty: difficulty, prompt: prompt,
          explanation: explanation, context: context, lessonRef: lessonRef, verify: verify,
          answer: jDouble(j, 'answer'),
          tolerance: jDouble(j, 'tol', 0.01),
          decimals: jInt(j, 'decimals', 2),
          unit: jStr(j, 'unit'),
          traps: jList(j, 'traps').map(NumericTrap.fromJson).toList(),
          hint: jStrOrNull(j, 'hint'),
        );
      case 'conclusion':
        return ConclusionExercise(
          id: id, moduleId: moduleId, difficulty: difficulty, prompt: prompt,
          explanation: explanation, context: context, lessonRef: lessonRef, verify: verify,
          slots: jList(j, 'slots').map(ConclusionSlot.fromJson).toList(),
          model: jStr(j, 'model'),
        );
      case 'classify':
        return ClassifyExercise(
          id: id, moduleId: moduleId, difficulty: difficulty, prompt: prompt,
          explanation: explanation, context: context, lessonRef: lessonRef, verify: verify,
          categories: jStrings(j, 'categories'),
          items: jList(j, 'items').map(ClassifyItem.fromJson).toList(),
        );
      default:
        return ChoiceExercise(
          id: id, moduleId: moduleId, difficulty: difficulty, prompt: prompt,
          explanation: explanation, context: context, lessonRef: lessonRef, verify: verify,
          options: jList(j, 'options').map(ChoiceOption.fromJson).toList(),
        );
    }
  }
}

Set<String> _tagsOf(Iterable<ChoiceOption> options) =>
    options.map((o) => o.tag).whereType<String>().toSet();

class ChoiceExercise extends Exercise {
  const ChoiceExercise({
    required super.id, required super.moduleId, required super.difficulty,
    required super.prompt, required super.explanation, super.context, super.lessonRef,
    super.verify, required this.options,
  });

  final List<ChoiceOption> options;

  @override
  ExerciseType get type => ExerciseType.choice;

  @override
  Set<String> get detectableTags => _tagsOf(options);
}

/// Decisión + justificación. Regla 60/40: la elección vale 0,6 y el porqué
/// 0,4. Acertar la elección y fallar el porqué es un «acierto ciego».
class DecisionExercise extends Exercise {
  const DecisionExercise({
    required super.id, required super.moduleId, required super.difficulty,
    required super.prompt, required super.explanation, super.context, super.lessonRef,
    super.verify, required this.options, required this.justificationPrompt,
    required this.justifications,
  });

  final List<ChoiceOption> options;
  final String justificationPrompt;
  final List<ChoiceOption> justifications;

  @override
  ExerciseType get type => ExerciseType.decision;

  @override
  Set<String> get detectableTags => {..._tagsOf(options), ..._tagsOf(justifications)};
}

class NumericExercise extends Exercise {
  const NumericExercise({
    required super.id, required super.moduleId, required super.difficulty,
    required super.prompt, required super.explanation, super.context, super.lessonRef,
    super.verify, required this.answer, required this.tolerance, required this.decimals,
    required this.unit, required this.traps, this.hint,
  });

  final double answer;
  final double tolerance;
  final int decimals;
  final String unit;
  final List<NumericTrap> traps;
  final String? hint;

  @override
  ExerciseType get type => ExerciseType.numeric;

  @override
  Set<String> get detectableTags => traps.map((t) => t.tag).whereType<String>().toSet();
}

/// El estudiante arma la conclusión eligiendo un fragmento por casilla.
class ConclusionExercise extends Exercise {
  const ConclusionExercise({
    required super.id, required super.moduleId, required super.difficulty,
    required super.prompt, required super.explanation, super.context, super.lessonRef,
    super.verify, required this.slots, required this.model,
  });

  final List<ConclusionSlot> slots;
  final String model;

  @override
  ExerciseType get type => ExerciseType.conclusion;

  @override
  Set<String> get detectableTags => {for (final s in slots) ..._tagsOf(s.options)};
}

class ClassifyExercise extends Exercise {
  const ClassifyExercise({
    required super.id, required super.moduleId, required super.difficulty,
    required super.prompt, required super.explanation, super.context, super.lessonRef,
    super.verify, required this.categories, required this.items,
  });

  final List<String> categories;
  final List<ClassifyItem> items;

  @override
  ExerciseType get type => ExerciseType.classify;

  @override
  Set<String> get detectableTags => items.map((i) => i.tag).whereType<String>().toSet();
}

// ------------------------------------------------------------- respuestas
sealed class ExerciseAnswer {
  const ExerciseAnswer();
}

class ChoiceAnswer extends ExerciseAnswer {
  const ChoiceAnswer(this.index);
  final int index;
}

class DecisionAnswer extends ExerciseAnswer {
  const DecisionAnswer(this.choice, this.justification);
  final int choice;
  final int justification;
}

class NumericAnswer extends ExerciseAnswer {
  const NumericAnswer(this.value);
  final double value;
}

class ConclusionAnswer extends ExerciseAnswer {
  const ConclusionAnswer(this.picks);
  final List<int> picks;
}

class ClassifyAnswer extends ExerciseAnswer {
  const ClassifyAnswer(this.assignments);
  final List<int> assignments;
}
