import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/engine/grading_engine.dart';
import '../../domain/models/exercise_models.dart';
import 'misconception_chip.dart';
import 'option_tile.dart';

/// Borrador de respuesta, común a todos los tipos de ejercicio.
class AnswerDraft {
  AnswerDraft(Exercise exercise)
      : picks = _emptyPicks(exercise),
        assignments = _emptyAssignments(exercise);

  static List<int?> _emptyPicks(Exercise e) =>
      e is ConclusionExercise ? List<int?>.filled(e.slots.length, null) : <int?>[];

  static List<int?> _emptyAssignments(Exercise e) =>
      e is ClassifyExercise ? List<int?>.filled(e.items.length, null) : <int?>[];

  int? choice;
  int? justification;
  String numeric = '';
  final List<int?> picks;
  final List<int?> assignments;

  bool isComplete(Exercise e) => switch (e) {
        ChoiceExercise _ => choice != null,
        DecisionExercise _ => choice != null && justification != null,
        NumericExercise _ => Fmt.parse(numeric) != null,
        ConclusionExercise _ => picks.every((p) => p != null),
        ClassifyExercise _ => assignments.every((a) => a != null),
      };

  ExerciseAnswer toAnswer(Exercise e) => switch (e) {
        ChoiceExercise _ => ChoiceAnswer(choice!),
        DecisionExercise _ => DecisionAnswer(choice!, justification!),
        NumericExercise _ => NumericAnswer(Fmt.parse(numeric)!),
        ConclusionExercise _ => ConclusionAnswer(picks.map((p) => p!).toList()),
        ClassifyExercise _ => ClassifyAnswer(assignments.map((a) => a!).toList()),
      };
}

/// Interacción de un ejercicio según su tipo.
class ExerciseInteraction extends StatelessWidget {
  const ExerciseInteraction({
    super.key,
    required this.exercise,
    required this.draft,
    required this.graded,
    required this.onChanged,
    required this.accent,
  });

  final Exercise exercise;
  final AnswerDraft draft;
  final bool graded;
  final VoidCallback onChanged;
  final Color accent;

  OptionState _state(List<ChoiceOption> options, int i, int? selected) {
    if (!graded) return selected == i ? OptionState.selected : OptionState.idle;
    if (options[i].correct) return OptionState.correct;
    if (selected == i) return OptionState.wrong;
    return OptionState.dimmed;
  }

  Widget _options(List<ChoiceOption> options, int? selected, ValueChanged<int> onSelect) => Column(
        children: [
          for (var i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OptionTile(
                text: options[i].text,
                state: _state(options, i, selected),
                accent: accent,
                onTap: graded ? null : () => onSelect(i),
              ),
            ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    switch (exercise) {
      case final ChoiceExercise e:
        return _options(e.options, draft.choice, (i) {
          draft.choice = i;
          onChanged();
        });
      case final DecisionExercise e:
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Step(number: 1, label: 'Tu decisión', color: accent),
          _options(e.options, draft.choice, (i) {
            draft.choice = i;
            onChanged();
          }),
          const SizedBox(height: 8),
          _Step(number: 2, label: e.justificationPrompt, color: accent),
          _options(e.justifications, draft.justification, (i) {
            draft.justification = i;
            onChanged();
          }),
        ]);
      case final NumericExercise e:
        return _NumericInput(exercise: e, draft: draft, graded: graded, onChanged: onChanged, accent: accent);
      case final ConclusionExercise e:
        final preview = [
          for (var i = 0; i < e.slots.length; i++)
            draft.picks[i] == null ? '[${e.slots[i].label.toLowerCase()}]' : e.slots[i].options[draft.picks[i]!].text,
        ].join(' ');
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.format_quote_rounded, color: accent),
              const SizedBox(width: 8),
              Expanded(child: Text(preview, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 14),
          for (var s = 0; s < e.slots.length; s++) ...[
            _Step(number: s + 1, label: e.slots[s].label, color: accent),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (var o = 0; o < e.slots[s].options.length; o++)
                _FragmentChip(
                  text: e.slots[s].options[o].text,
                  selected: draft.picks[s] == o,
                  state: !graded
                      ? null
                      : e.slots[s].options[o].correct
                          ? true
                          : (draft.picks[s] == o ? false : null),
                  accent: accent,
                  onTap: graded
                      ? null
                      : () {
                          draft.picks[s] = o;
                          onChanged();
                        },
                ),
            ]),
            const SizedBox(height: 12),
          ],
        ]);
      case final ClassifyExercise e:
        return Column(children: [
          for (var i = 0; i < e.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(e.items[i].text, style: t.bodyLarge?.copyWith(fontWeight: FontWeight.w600))),
                      if (graded)
                        Icon(
                          draft.assignments[i] == e.items[i].category ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: draft.assignments[i] == e.items[i].category ? AppColors.teal : AppColors.coral,
                        ),
                    ]),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (var c = 0; c < e.categories.length; c++)
                        _FragmentChip(
                          text: e.categories[c],
                          selected: draft.assignments[i] == c,
                          state: !graded
                              ? null
                              : c == e.items[i].category
                                  ? true
                                  : (draft.assignments[i] == c ? false : null),
                          accent: accent,
                          compact: true,
                          onTap: graded
                              ? null
                              : () {
                                  draft.assignments[i] = c;
                                  onChanged();
                                },
                        ),
                    ]),
                  ]),
                ),
              ),
            ),
        ]);
    }
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.label, required this.color});
  final int number;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(children: [
          CircleAvatar(radius: 11, backgroundColor: color, child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
        ]),
      );
}

class _FragmentChip extends StatelessWidget {
  const _FragmentChip({
    required this.text,
    required this.selected,
    required this.state,
    required this.accent,
    this.onTap,
    this.compact = false,
  });

  final String text;
  final bool selected;

  /// null = sin corregir o neutro; true = correcto; false = elegido y erróneo.
  final bool? state;
  final Color accent;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = state == true
        ? AppColors.teal
        : state == false
            ? AppColors.coral
            : (selected ? accent : Theme.of(context).dividerColor);
    return Material(
      color: (state != null || selected) ? c.withValues(alpha: 0.14) : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: c, width: (state != null || selected) ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12, vertical: compact ? 7 : 10),
          child: Text(text, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ),
      ),
    );
  }
}

class _NumericInput extends StatefulWidget {
  const _NumericInput({required this.exercise, required this.draft, required this.graded, required this.onChanged, required this.accent});
  final NumericExercise exercise;
  final AnswerDraft draft;
  final bool graded;
  final VoidCallback onChanged;
  final Color accent;

  @override
  State<_NumericInput> createState() => _NumericInputState();
}

class _NumericInputState extends State<_NumericInput> {
  late final TextEditingController _c = TextEditingController(text: widget.draft.numeric);
  bool _hint = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(
        controller: _c,
        enabled: !widget.graded,
        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFeatures: [FontFeature.tabularFigures()]),
        decoration: InputDecoration(
          hintText: e.decimals == 0 ? 'Número entero' : 'Usa coma o punto decimal',
          suffixText: e.unit.isEmpty ? null : e.unit,
          prefixIcon: Icon(Icons.edit_rounded, color: widget.accent),
        ),
        onChanged: (v) {
          widget.draft.numeric = v;
          widget.onChanged();
        },
      ),
      const SizedBox(height: 8),
      Text('La calculadora de la barra inferior está siempre disponible: aquí importa elegir bien la fórmula.',
          style: Theme.of(context).textTheme.bodySmall),
      if (e.hint != null && !widget.graded)
        TextButton.icon(
          onPressed: () => setState(() => _hint = !_hint),
          icon: const Icon(Icons.tips_and_updates_rounded, size: 18),
          label: Text(_hint ? e.hint! : 'Ver pista'),
        ),
      if (widget.graded)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Respuesta: ${Fmt.number(e.answer, e.decimals)}${e.unit.isEmpty ? '' : ' ${e.unit}'}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.teal)),
        ),
    ]);
  }
}

/// Retroalimentación tras corregir: puntaje, comentario por parte,
/// confusiones detectadas y explicación completa.
class FeedbackPanel extends StatelessWidget {
  const FeedbackPanel({super.key, required this.result, required this.explanation, this.model});
  final GradeResult result;
  final String explanation;
  final String? model;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = result.isCorrect
        ? AppColors.teal
        : result.isPartial
            ? const Color(0xFFC27D12)
            : AppColors.coral;
    final title = result.isCorrect
        ? '¡Correcto!'
        : result.blindHit
            ? 'Decisión correcta, razón equivocada'
            : result.isPartial
                ? 'Parcialmente correcto'
                : 'Todavía no';
    final tags = result.tags.toSet().toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(result.isCorrect ? Icons.verified_rounded : Icons.feedback_rounded, color: c, size: 26),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: t.titleMedium?.copyWith(color: c, fontWeight: FontWeight.w900))),
          Text('${(result.score * 100).round()} %', style: t.titleMedium?.copyWith(color: c, fontWeight: FontWeight.w900)),
        ]),
        if (result.blindHit)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Acertar sin la razón correcta es un «acierto ciego»: en un caso real, la misma razón llevaría a otra decisión equivocada.',
                style: t.bodySmall),
          ),
        const SizedBox(height: 10),
        for (final f in result.feedback)
          if (f.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(f.positive ? Icons.check_rounded : Icons.close_rounded, size: 18, color: f.positive ? AppColors.teal : AppColors.coral),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    if (f.label != null) TextSpan(text: '${f.label}: ', style: const TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: f.text),
                  ]), style: t.bodyMedium),
                ),
              ]),
            ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final tg in tags) MisconceptionChip(tg)]),
        ],
        if (model != null) ...[
          const SizedBox(height: 10),
          Text('Conclusión modelo', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('«$model»', style: t.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
        ],
        const Divider(height: 24),
        Text('Explicación', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(explanation, style: t.bodyMedium),
      ]),
    );
  }
}
