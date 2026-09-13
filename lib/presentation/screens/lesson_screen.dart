import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/models/course_models.dart';
import '../charts/lesson_visuals.dart';
import '../providers/app_providers.dart';
import '../widgets/content_builder.dart';
import '../widgets/option_tile.dart';

/// Lección en tarjetas breves. Las tarjetas «Comprueba» exigen responder
/// antes de avanzar: recuperar la idea es más eficaz que releerla.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lesson});
  final Lesson lesson;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final _controller = PageController();
  int _index = 0;
  final Map<int, int> _answers = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _blocked {
    final card = widget.lesson.cards[_index];
    return card.type == CardType.check && !_answers.containsKey(_index);
  }

  void _next() {
    if (_index < widget.lesson.cards.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    } else {
      ref.read(progressProvider.notifier).completeLesson(widget.lesson.id);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lección completada: ${widget.lesson.title}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.lesson.cards;
    return ContentBuilder(builder: (context, content) {
      final module = content.module(widget.lesson.moduleId);
      final color = module == null ? AppColors.indigo : Color(module.colorValue);
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.lesson.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ThinProgress(value: (_index + 1) / cards.length, color: color, height: 5),
            ),
          ),
        ),
        body: PageView.builder(
          controller: _controller,
          physics: _blocked ? const NeverScrollableScrollPhysics() : null,
          onPageChanged: (i) => setState(() => _index = i),
          itemCount: cards.length,
          itemBuilder: (context, i) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: _CardView(
              card: cards[i],
              color: color,
              answer: _answers[i],
              onAnswer: (a) => setState(() => _answers[i] = a),
              misconceptionName: cards[i].tag == null ? null : content.misconception(cards[i].tag!)?.name,
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(children: [
              if (_index > 0)
                OutlinedButton(
                  onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
              const Spacer(),
              Text('${_index + 1} / ${cards.length}', style: Theme.of(context).textTheme.labelLarge),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: color),
                onPressed: _blocked ? null : _next,
                child: Text(_index == cards.length - 1 ? 'Terminar' : (_blocked ? 'Responde' : 'Siguiente')),
              ),
            ]),
          ),
        ),
      );
    });
  }
}

class _CardView extends StatelessWidget {
  const _CardView({
    required this.card,
    required this.color,
    required this.answer,
    required this.onAnswer,
    this.misconceptionName,
  });

  final LessonCard card;
  final Color color;
  final int? answer;
  final ValueChanged<int> onAnswer;
  final String? misconceptionName;

  (IconData, String, Color) get _style => switch (card.type) {
        CardType.concept => (Icons.lightbulb_rounded, 'IDEA', color),
        CardType.formula => (Icons.functions_rounded, 'FÓRMULA', AppColors.indigoSoft),
        CardType.example => (Icons.work_outline_rounded, 'EJEMPLO', AppColors.teal),
        CardType.warning => (Icons.report_rounded, 'CUIDADO', AppColors.coral),
        CardType.check => (Icons.quiz_rounded, 'COMPRUEBA', const Color(0xFFC27D12)),
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final (icon, kicker, c) = _style;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: c, size: 20),
              const SizedBox(width: 6),
              Text(kicker, style: t.labelMedium?.copyWith(color: c, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              if (misconceptionName != null) ...[
                const SizedBox(width: 8),
                Flexible(child: Pill(misconceptionName!, color: AppColors.coral)),
              ],
            ]),
            const SizedBox(height: 10),
            Text(card.title, style: t.titleLarge),
            const SizedBox(height: 14),
            if (card.visual != null && LessonVisual.known.contains(card.visual)) ...[
              LessonVisual(card.visual!, color: color),
              const SizedBox(height: 16),
            ],
            if (card.formula != null) ...[
              FormulaBox(card.formula!, color: color),
              const SizedBox(height: 14),
            ],
            if (card.body.isNotEmpty) Text(card.body, style: t.bodyLarge),
            if (card.type == CardType.check) ..._check(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _check(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final correct = card.answer ?? 0;
    return [
      Text(card.question ?? '', style: t.titleMedium),
      const SizedBox(height: 12),
      for (var i = 0; i < card.options.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OptionTile(
            text: card.options[i],
            state: answer == null
                ? OptionState.idle
                : i == correct
                    ? OptionState.correct
                    : i == answer
                        ? OptionState.wrong
                        : OptionState.dimmed,
            onTap: answer == null ? () => onAnswer(i) : null,
          ),
        ),
      if (answer != null)
        Callout(
          text: card.explanation ?? '',
          icon: answer == correct ? Icons.check_circle_rounded : Icons.lightbulb_rounded,
          color: answer == correct ? AppColors.teal : AppColors.coral,
          title: answer == correct ? 'Bien' : 'No exactamente',
        ),
    ];
  }
}
