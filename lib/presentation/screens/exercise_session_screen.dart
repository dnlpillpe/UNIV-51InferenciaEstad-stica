import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/engine/grading_engine.dart';
import '../../domain/models/exercise_models.dart';
import '../providers/app_providers.dart';
import '../widgets/exercise_views.dart';
import '../widgets/misconception_chip.dart';

/// Sesión de práctica: un ejercicio a la vez, corrección inmediata y
/// resumen con las confusiones detectadas en la sesión.
class ExerciseSessionScreen extends ConsumerStatefulWidget {
  const ExerciseSessionScreen({super.key, required this.title, required this.exercises, this.colorValue});

  final String title;
  final List<Exercise> exercises;
  final int? colorValue;

  @override
  ConsumerState<ExerciseSessionScreen> createState() => _ExerciseSessionScreenState();
}

class _ExerciseSessionScreenState extends ConsumerState<ExerciseSessionScreen> {
  int _index = 0;
  late AnswerDraft _draft = AnswerDraft(widget.exercises.first);
  GradeResult? _result;
  final List<GradeResult> _results = [];
  final _scroll = ScrollController();

  Exercise get _current => widget.exercises[_index];
  Color get _accent => widget.colorValue == null ? AppColors.indigo : Color(widget.colorValue!);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _check() {
    final r = ref.read(gradingEngineProvider).grade(_current, _draft.toAnswer(_current));
    ref.read(progressProvider.notifier).recordExercise(_current, r);
    setState(() {
      _result = r;
      _results.add(r);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
      }
    });
  }

  void _next() {
    setState(() {
      _index++;
      if (_index < widget.exercises.length) {
        _draft = AnswerDraft(_current);
        _result = null;
      }
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= widget.exercises.length) return _summary(context);
    final e = _current;
    final t = Theme.of(context).textTheme;
    final graded = _result != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ThinProgress(value: (_index + (graded ? 1 : 0)) / widget.exercises.length, color: _accent, height: 5),
          ),
        ),
      ),
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(children: [
            Pill(e.type.label, color: _accent),
            const SizedBox(width: 6),
            Pill('Dificultad ${'●' * e.difficulty}${'○' * (3 - e.difficulty)}', color: Colors.blueGrey),
            const Spacer(),
            Text('${_index + 1} de ${widget.exercises.length}', style: t.labelMedium),
          ]),
          const SizedBox(height: 14),
          if (e.context != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.description_outlined, color: _accent, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(e.context!, style: t.bodyMedium)),
              ]),
            ),
            const SizedBox(height: 14),
          ],
          Text(e.prompt, style: t.titleMedium?.copyWith(height: 1.35)),
          const SizedBox(height: 16),
          ExerciseInteraction(
            key: ValueKey(e.id),
            exercise: e,
            draft: _draft,
            graded: graded,
            accent: _accent,
            onChanged: () => setState(() {}),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            FeedbackPanel(
              result: _result!,
              explanation: e.explanation,
              model: e is ConclusionExercise ? e.model : null,
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: graded ? _next : (_draft.isComplete(e) ? _check : null),
            child: Text(graded
                ? (_index == widget.exercises.length - 1 ? 'Ver resumen' : 'Siguiente')
                : 'Comprobar'),
          ),
        ),
      ),
    );
  }

  Widget _summary(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final n = _results.length;
    final avg = n == 0 ? 0.0 : _results.fold<double>(0, (s, r) => s + r.score) / n;
    final correct = _results.where((r) => r.isCorrect).length;
    final blind = _results.where((r) => r.blindHit).length;
    final tags = <String>{for (final r in _results) ...r.tags};
    final failed = <Exercise>[
      for (var i = 0; i < _results.length; i++)
        if (!_results[i].isCorrect) widget.exercises[i],
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen de la sesión')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(child: ProgressRing(value: avg, color: _accent, size: 120, stroke: 12)),
          const SizedBox(height: 12),
          Center(child: Text('$correct de $n correctos', style: t.titleLarge)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: StatTile(label: 'Puntaje medio', value: '${(avg * 100).round()} %', color: _accent)),
            const SizedBox(width: 8),
            Expanded(child: StatTile(label: 'Aciertos ciegos', value: '$blind', color: const Color(0xFFC27D12), caption: 'decisión bien, razón mal')),
          ]),
          const SectionTitle('Confusiones detectadas'),
          if (tags.isEmpty)
            const Callout(text: 'Ninguna en esta sesión. Tus errores, si los hubo, no apuntan a una confusión catalogada.', icon: Icons.celebration_rounded, color: AppColors.teal)
          else ...[
            Text('Toca cada una para ver la idea correcta y su remedio.', style: t.bodySmall),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final tg in tags) MisconceptionChip(tg)]),
          ],
          const SizedBox(height: 24),
          if (failed.isNotEmpty)
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => ExerciseSessionScreen(title: widget.title, exercises: failed, colorValue: widget.colorValue),
              )),
              icon: const Icon(Icons.replay_rounded),
              label: Text('Repetir los ${failed.length} no resueltos'),
            ),
          const SizedBox(height: 10),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _accent),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }
}
