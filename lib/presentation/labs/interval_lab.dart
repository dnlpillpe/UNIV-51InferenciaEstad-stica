import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/lab_models.dart';
import '../../domain/simulation/interval_simulator.dart';
import '../charts/interval_rain_painter.dart';
import 'experiment_frame.dart';
import 'lab_controls.dart';
import 'lab_view_models.dart';

/// Laboratorio 3 — Lluvia de intervalos.
class IntervalLab extends StatefulWidget {
  const IntervalLab({super.key, required this.experiment, required this.color});
  final LabExperiment? experiment;
  final Color color;

  @override
  State<IntervalLab> createState() => _IntervalLabState();
}

class _IntervalLabState extends State<IntervalLab> {
  final model = IntervalLabModel();

  @override
  void initState() {
    super.initState();
    model.preset(widget.experiment?.id);
  }

  String? get _measured {
    final parts = <String>[
      if (model.intervals.isNotEmpty)
        '${model.label}: capturan ${Fmt.percent(model.captureRate)} de ${model.intervals.length}',
      for (final h in model.history) '${h.label}: ${Fmt.percent(h.captureRate)} de ${h.count}',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return ExperimentFrame(
      experiment: widget.experiment,
      runs: model.totalRuns,
      color: widget.color,
      measured: _measured,
      builder: (context, enabled) => _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final pal = ChartPalette.of(context);
    final t = Theme.of(context).textTheme;
    final rate = model.captureRate;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Población: puntajes de una prueba con μ = 50 y σ = 10 (desconocidas para los investigadores).', style: t.bodySmall),
      const SizedBox(height: 8),
      SegmentedButton<double>(
        showSelectedIcon: false,
        segments: [for (final l in IntervalLabModel.levels) ButtonSegment(value: l, label: Text('${(l * 100).round()} %'))],
        selected: {model.conf},
        onSelectionChanged: (s) => setState(() => model.setConf(s.first)),
      ),
      const SizedBox(height: 6),
      DiscreteSlider(
        label: 'n',
        values: IntervalLabModel.sizes,
        value: model.n,
        onChanged: (v) => setState(() => model.setN(v.toInt())),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<IntervalMethod>(
          showSelectedIcon: false,
          segments: [for (final m in IntervalMethod.values) ButtonSegment(value: m, label: Text(m.label))],
          selected: {model.method},
          onSelectionChanged: (s) => setState(() => model.setMethod(s.first)),
        ),
      ),
      const SizedBox(height: 4),
      Text('Fórmula: ${model.method.formula}', style: t.bodySmall),
      const SizedBox(height: 8),
      ChartPanel(
        title: 'Últimos ${model.intervals.length.clamp(0, 100)} intervalos',
        subtitle: 'Ámbar: contiene a μ. Coral con punto a la derecha: no la contiene.',
        height: 300,
        child: CustomPaint(
          painter: IntervalRainPainter(intervals: model.intervals, mu: IntervalLabModel.mu, xMin: 30, xMax: 70, palette: pal),
        ),
      ),
      const SizedBox(height: 8),
      RunButtons(
        counts: const [1, 10, 100],
        verb: 'Investigar',
        color: widget.color,
        onRun: (k) => setState(() => model.add(k)),
        onReset: () => setState(model.clear),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: StatTile(
            label: 'Capturan a μ',
            value: model.intervals.isEmpty ? '—' : '${model.captured} / ${model.intervals.length}',
            caption: model.intervals.isEmpty ? null : Fmt.percent(rate),
            color: pal.confidence,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Nivel prometido', value: '${(model.conf * 100).round()} %')),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Ancho medio', value: model.intervals.isEmpty ? '—' : Fmt.number(model.meanWidth, 2))),
      ]),
      if (model.history.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Configuraciones anteriores', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        for (final h in model.history)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Expanded(child: Text(h.label, style: t.bodySmall)),
              Text('${Fmt.percent(h.captureRate)} · ancho ${Fmt.number(h.meanWidth, 2)}',
                  style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
            ]),
          ),
      ],
      const SizedBox(height: 8),
      const Callout(
        text: 'Ningún investigador ve la línea de μ: cada uno tiene un solo intervalo y no sabe si es ámbar o coral.',
        icon: Icons.visibility_off_rounded,
        color: AppColors.m3,
      ),
    ]);
  }
}
