import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/models/lab_models.dart';
import '../../domain/simulation/population.dart';
import '../../domain/stats/descriptive.dart';
import '../../domain/stats/distributions.dart';
import '../charts/chart_kit.dart';
import '../charts/dot_stack_painter.dart';
import '../charts/histogram_painter.dart';
import 'experiment_frame.dart';
import 'lab_controls.dart';
import 'lab_view_models.dart';

/// Laboratorio 2 — Máquina de muestras.
class SamplingLab extends StatefulWidget {
  const SamplingLab({super.key, required this.experiment, required this.color});
  final LabExperiment? experiment;
  final Color color;

  @override
  State<SamplingLab> createState() => _SamplingLabState();
}

class _SamplingLabState extends State<SamplingLab> {
  final model = SamplingLabModel();
  bool _zoom = false;

  @override
  void initState() {
    super.initState();
    model.preset(widget.experiment?.id);
  }

  String? get _measured {
    if (model.observedSeByN.isEmpty) return null;
    final parts = model.observedSeByN.entries
        .map((e) => 'EE observado con n = ${e.key}: ${Fmt.number(e.value, 2)}')
        .join(' · ');
    final skew = model.means.length > 30 ? ' · asimetría de las medias: ${Fmt.number(Descriptive.skewness(model.means), 2)}' : '';
    return '$parts$skew';
  }

  @override
  Widget build(BuildContext context) {
    return ExperimentFrame(
      experiment: widget.experiment,
      runs: model.totalDrawn,
      color: widget.color,
      measured: _measured,
      builder: (context, enabled) => _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final pal = ChartPalette.of(context);
    final pop = model.population;
    final t = Theme.of(context).textTheme;
    final unit = pop.shape.unit;
    final lo = pop.min, hi = math.min(pop.max, pop.mean + 5 * pop.sd);
    final se = model.theoreticalSe;
    final mLo = _zoom ? pop.mean - 4.5 * se : lo;
    final mHi = _zoom ? pop.mean + 4.5 * se : hi;
    final many = model.means.length > 300;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SegmentedButton<PopulationShape>(
          showSelectedIcon: false,
          segments: [for (final s in PopulationShape.values) ButtonSegment(value: s, label: Text(s.label))],
          selected: {model.shape},
          onSelectionChanged: (s) => setState(() => model.setShape(s.first)),
        ),
      ),
      const SizedBox(height: 6),
      DiscreteSlider(
        label: 'n',
        values: SamplingLabModel.sizes,
        value: model.n,
        onChanged: (v) => setState(() => model.setN(v.toInt())),
      ),
      ChartPanel(
        title: '1 · Población: ${pop.shape.context} (${Fmt.integer(pop.size)} valores)',
        subtitle: 'μ = ${Fmt.number(pop.mean, 2)} $unit · σ = ${Fmt.number(pop.sd, 2)} $unit',
        height: 110,
        child: CustomPaint(
          painter: HistogramPainter(
            values: pop.values, min: lo, max: hi, bins: 40, color: pal.population, palette: pal,
            markers: [ChartMarker(pop.mean, pal.parameter, label: 'μ')],
          ),
        ),
      ),
      ChartPanel(
        title: '2 · Última muestra (n = ${model.n})',
        subtitle: model.lastSample.isEmpty
            ? 'Todavía no has extraído muestras.'
            : 'x̄ = ${Fmt.number(Descriptive.mean(model.lastSample), 2)} $unit',
        height: 100,
        child: CustomPaint(
          painter: HistogramPainter(
            values: model.lastSample, min: lo, max: hi, bins: model.n >= 50 ? 30 : 20, color: pal.sample, palette: pal,
            markers: model.lastSample.isEmpty ? const [] : [ChartMarker(Descriptive.mean(model.lastSample), pal.estimate, label: 'x̄')],
            emptyText: 'Pulsa «Extraer»',
          ),
        ),
      ),
      ChartPanel(
        title: '3 · Distribución muestral de x̄ (${Fmt.integer(model.means.length)} medias)',
        subtitle: many ? 'La curva es la normal que predice el TLC: N(μ, σ/√n).' : 'Cada punto es la media de una muestra; el ámbar es la última.',
        height: 150,
        trailing: TextButton.icon(
          onPressed: () => setState(() => _zoom = !_zoom),
          icon: Icon(_zoom ? Icons.zoom_out_rounded : Icons.zoom_in_rounded, size: 18),
          label: Text(_zoom ? 'Eje de la población' : 'Ajustar eje'),
        ),
        child: CustomPaint(
          painter: many
              ? HistogramPainter(
                  values: model.means, min: mLo, max: mHi, bins: 44, color: pal.sampling, palette: pal,
                  curve: (x) => Distributions.normalPdf((x - pop.mean) / se) / se,
                  markers: [ChartMarker(pop.mean, pal.parameter, label: 'μ')],
                )
              : DotStackPainter(
                  values: model.means, min: mLo, max: mHi, color: pal.sampling, palette: pal, columns: 44,
                  markers: [ChartMarker(pop.mean, pal.parameter, label: 'μ')],
                ),
        ),
      ),
      const SizedBox(height: 8),
      RunButtons(
        counts: const [1, 10, 100, 1000],
        verb: 'Extraer',
        color: widget.color,
        onRun: (k) => setState(() => model.draw(k)),
        onReset: () => setState(model.clear),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: StatTile(label: 'EE teórico σ/√n', value: Fmt.number(se, 3), color: pal.parameter)),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'EE observado', value: model.means.length < 2 ? '—' : Fmt.number(model.observedSe, 3), color: pal.sampling)),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Media de las x̄', value: model.means.isEmpty ? '—' : Fmt.number(Descriptive.mean(model.means), 2))),
      ]),
      if (model.observedSeByN.length > 1) ...[
        const SizedBox(height: 10),
        Text('Comparación de tamaños', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        for (final e in model.observedSeByN.entries)
          Text('n = ${e.key}: EE observado ${Fmt.number(e.value, 3)} (teórico ${Fmt.number(pop.sd / math.sqrt(e.key), 3)})', style: t.bodySmall),
      ],
      const SizedBox(height: 6),
      Callout(
        text: 'Observa los tres paneles a la vez: el 1 y el 2 hablan de individuos; solo el 3 habla de medias.',
        icon: Icons.visibility_rounded,
        color: AppColors.violet,
      ),
    ]);
  }
}
