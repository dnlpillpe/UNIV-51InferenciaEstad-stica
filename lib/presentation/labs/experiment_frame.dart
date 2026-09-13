import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/models/lab_models.dart';
import '../providers/app_providers.dart';
import '../widgets/option_tile.dart';

/// Marco Predice → Simula → Explica de todos los experimentos.
///
/// 1. El estudiante registra una predicción (los controles están
///    desactivados hasta entonces).
/// 2. Simula al menos `minRuns` repeticiones.
/// 3. Recién entonces puede ver la conclusión: revelarla antes anularía
///    el experimento.
class ExperimentFrame extends ConsumerStatefulWidget {
  const ExperimentFrame({
    super.key,
    required this.experiment,
    required this.runs,
    required this.color,
    required this.builder,
    this.measured,
  });

  /// Nulo en modo libre.
  final LabExperiment? experiment;
  final int runs;
  final Color color;
  final Widget Function(BuildContext context, bool enabled) builder;

  /// Resumen de lo medido en la simulación, mostrado junto a la conclusión.
  final String? measured;

  @override
  ConsumerState<ExperimentFrame> createState() => _ExperimentFrameState();
}

class _ExperimentFrameState extends ConsumerState<ExperimentFrame> {
  int? _prediction;
  bool _locked = false;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    final e = widget.experiment;
    if (e != null && ref.read(progressProvider).completedExperiments.contains(e.id)) {
      _locked = true; // ya hecho: exploración libre, conclusión disponible
    }
  }

  void _reveal() {
    final e = widget.experiment!;
    final correct = _prediction != null && e.predictions[_prediction!].correct;
    ref.read(progressProvider.notifier).completeExperiment(e.id, predictionCorrect: correct);
    setState(() => _revealed = true);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.experiment;
    final t = Theme.of(context).textTheme;
    if (e == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Callout(
          text: 'Modo libre: cambia cualquier parámetro y observa. No hay predicción ni conclusión que desbloquear.',
          icon: Icons.explore_rounded,
        ),
        const SizedBox(height: 12),
        widget.builder(context, true),
      ]);
    }
    final done = ref.watch(progressProvider.select((p) => p.completedExperiments.contains(e.id)));
    final ready = widget.runs >= e.minRuns;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.lightbulb_rounded, color: widget.color),
              const SizedBox(width: 6),
              Text('PREDICE', style: t.labelMedium?.copyWith(color: widget.color, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const Spacer(),
              if (done) const Pill('Completado', color: AppColors.teal, icon: Icons.check_rounded),
            ]),
            const SizedBox(height: 8),
            Text(e.question, style: t.titleMedium?.copyWith(height: 1.35)),
            const SizedBox(height: 12),
            if (!_locked || _prediction != null)
              for (var i = 0; i < e.predictions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OptionTile(
                    text: e.predictions[i].text,
                    accent: widget.color,
                    state: _revealed
                        ? (e.predictions[i].correct
                            ? OptionState.correct
                            : (_prediction == i ? OptionState.wrong : OptionState.dimmed))
                        : (_prediction == i ? OptionState.selected : (_locked ? OptionState.dimmed : OptionState.idle)),
                    onTap: _locked ? null : () => setState(() => _prediction = i),
                  ),
                ),
            if (!_locked)
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: widget.color),
                onPressed: _prediction == null ? null : () => setState(() => _locked = true),
                child: const Text('Registrar predicción y simular'),
              ),
            if (_locked && _prediction == null && !_revealed)
              Text('Ya completaste este experimento: explora libremente o vuelve a ver la conclusión.', style: t.bodySmall),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      if (_locked) ...[
        Callout(text: e.instructions, icon: Icons.touch_app_rounded, color: widget.color, title: 'Simula'),
        const SizedBox(height: 12),
      ],
      AbsorbPointer(
        absorbing: !_locked,
        child: Opacity(opacity: _locked ? 1 : 0.45, child: widget.builder(context, _locked)),
      ),
      const SizedBox(height: 12),
      if (_locked && !_revealed) ...[
        Row(children: [
          Expanded(child: ThinProgress(value: widget.runs / e.minRuns, color: widget.color, height: 8)),
          const SizedBox(width: 10),
          Text('${widget.runs.clamp(0, e.minRuns)} / ${e.minRuns}', style: t.labelLarge),
        ]),
        const SizedBox(height: 10),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: widget.color),
          onPressed: ready || done ? _reveal : null,
          icon: const Icon(Icons.visibility_rounded),
          label: Text(ready || done ? 'Ver la conclusión' : 'Simula más para ver la conclusión'),
        ),
      ],
      if (_revealed) ...[
        Card(
          color: widget.color.withValues(alpha: 0.10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.auto_awesome_rounded, color: widget.color),
                const SizedBox(width: 6),
                Text('EXPLICA', style: t.labelMedium?.copyWith(color: widget.color, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              ]),
              if (_prediction != null) ...[
                const SizedBox(height: 10),
                Callout(
                  text: e.predictions[_prediction!].feedback,
                  title: e.predictions[_prediction!].correct ? 'Tu predicción se confirmó' : 'Tu predicción no se cumplió',
                  icon: e.predictions[_prediction!].correct ? Icons.check_circle_rounded : Icons.change_circle_rounded,
                  color: e.predictions[_prediction!].correct ? AppColors.teal : AppColors.coral,
                ),
              ],
              if (widget.measured != null) ...[
                const SizedBox(height: 10),
                Text('Lo que mediste: ${widget.measured}', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
              const SizedBox(height: 10),
              Text(e.reveal, style: t.bodyLarge),
            ]),
          ),
        ),
      ],
    ]);
  }
}
