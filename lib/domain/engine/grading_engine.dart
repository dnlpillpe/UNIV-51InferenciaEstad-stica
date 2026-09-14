import '../models/exercise_models.dart';

class FeedbackItem {
  const FeedbackItem(this.text, {this.positive = false, this.tag, this.label});
  final String text;
  final bool positive;
  final String? tag;

  /// Encabezado opcional (p. ej. el nombre de la casilla de una conclusión).
  final String? label;
}

class GradeResult {
  const GradeResult({
    required this.score,
    required this.feedback,
    required this.tags,
    this.blindHit = false,
    this.isDecision = false,
  });

  /// Puntaje entre 0 y 1.
  final double score;
  final List<FeedbackItem> feedback;

  /// Confusiones detectadas en esta respuesta.
  final List<String> tags;

  /// Decisión correcta con justificación incorrecta.
  final bool blindHit;
  final bool isDecision;

  bool get isCorrect => score >= 0.999;
  bool get isPartial => score > 0 && !isCorrect;
}

/// Corrige cualquier tipo de ejercicio. Dart puro, sin estado.
class GradingEngine {
  const GradingEngine();

  static const double decisionWeight = 0.6;
  static const double justificationWeight = 0.4;

  GradeResult grade(Exercise exercise, ExerciseAnswer answer) {
    return switch (exercise) {
      ChoiceExercise e => _choice(e, answer as ChoiceAnswer),
      DecisionExercise e => _decision(e, answer as DecisionAnswer),
      NumericExercise e => _numeric(e, answer as NumericAnswer),
      ConclusionExercise e => _conclusion(e, answer as ConclusionAnswer),
      ClassifyExercise e => _classify(e, answer as ClassifyAnswer),
    };
  }

  GradeResult _choice(ChoiceExercise e, ChoiceAnswer a) {
    final o = e.options[a.index];
    return GradeResult(
      score: o.correct ? 1 : 0,
      feedback: [FeedbackItem(o.feedback, positive: o.correct, tag: o.tag)],
      tags: [if (!o.correct && o.tag != null) o.tag!],
    );
  }

  GradeResult _decision(DecisionExercise e, DecisionAnswer a) {
    final c = e.options[a.choice];
    final j = e.justifications[a.justification];
    final score = (c.correct ? decisionWeight : 0.0) + (j.correct ? justificationWeight : 0.0);
    return GradeResult(
      score: score,
      isDecision: true,
      blindHit: c.correct && !j.correct,
      feedback: [
        FeedbackItem(c.feedback, positive: c.correct, tag: c.tag, label: 'Decisión'),
        FeedbackItem(j.feedback, positive: j.correct, tag: j.tag, label: 'Justificación'),
      ],
      tags: [
        if (!c.correct && c.tag != null) c.tag!,
        if (!j.correct && j.tag != null) j.tag!,
      ],
    );
  }

  GradeResult _numeric(NumericExercise e, NumericAnswer a) {
    if ((a.value - e.answer).abs() <= e.tolerance) {
      return const GradeResult(
        score: 1,
        feedback: [FeedbackItem('Valor correcto.', positive: true)],
        tags: [],
      );
    }
    for (final t in e.traps) {
      if ((a.value - t.value).abs() <= t.tolerance) {
        return GradeResult(
          score: 0,
          feedback: [FeedbackItem(t.feedback, tag: t.tag)],
          tags: [if (t.tag != null) t.tag!],
        );
      }
    }
    return const GradeResult(
      score: 0,
      feedback: [
        FeedbackItem('El valor no coincide con el esperado. Revisa la fórmula y '
            'sustituye con cuidado; la explicación muestra el cálculo completo.'),
      ],
      tags: [],
    );
  }

  GradeResult _conclusion(ConclusionExercise e, ConclusionAnswer a) {
    var ok = 0;
    final fb = <FeedbackItem>[];
    final tags = <String>[];
    for (var i = 0; i < e.slots.length; i++) {
      final o = e.slots[i].options[a.picks[i]];
      if (o.correct) {
        ok++;
      } else {
        fb.add(FeedbackItem(o.feedback, tag: o.tag, label: e.slots[i].label));
        if (o.tag != null) tags.add(o.tag!);
      }
    }
    if (fb.isEmpty) {
      fb.add(const FeedbackItem('Cada fragmento dice exactamente lo que los datos permiten decir.',
          positive: true));
    }
    return GradeResult(score: ok / e.slots.length, feedback: fb, tags: tags);
  }

  GradeResult _classify(ClassifyExercise e, ClassifyAnswer a) {
    var ok = 0;
    final fb = <FeedbackItem>[];
    final tags = <String>[];
    for (var i = 0; i < e.items.length; i++) {
      final item = e.items[i];
      if (a.assignments[i] == item.category) {
        ok++;
      } else {
        fb.add(FeedbackItem(
          item.feedback.isEmpty
              ? '«${item.text}» va en ${e.categories[item.category]}.'
              : item.feedback,
          tag: item.tag,
          label: item.text,
        ));
        if (item.tag != null) tags.add(item.tag!);
      }
    }
    if (fb.isEmpty) {
      fb.add(const FeedbackItem('Todo bien clasificado.', positive: true));
    }
    return GradeResult(score: ok / e.items.length, feedback: fb, tags: tags);
  }
}
