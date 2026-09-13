import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/models/lab_models.dart';
import '../charts/bars_painters.dart';
import '../charts/chart_kit.dart';
import '../charts/histogram_painter.dart';
import 'experiment_frame.dart';
import 'lab_controls.dart';
import 'lab_view_models.dart';

/// Laboratorio 4 — El mundo de H0.
class NullWorldLab extends StatefulWidget {
  const NullWorldLab({super.key, required this.experiment, required this.color});
  final LabExperiment? experiment;
  final Color color;

  @override
  State<NullWorldLab> createState() => _NullWorldLabState();
}

class _NullWorldLabState extends State<NullWorldLab> {
  final model = NullWorldModel();

  static const List<double> effects = [0, 0.1, 0.2, 0.3, 0.5, 0.8];

  @override
  void initState() {
    super.initState();
    model.preset(widget.experiment?.id);
  }

  String? get _measured {
    if (model.mode == NullMode.coin) {
      if (model.coinSims.isEmpty) return null;
      return 'con ${Fmt.integer(model.coinSims.length)} series, ${Fmt.percent(model.simulatedP)} llegó a ${model.observed} o más aciertos '
          '(valor exacto: ${Fmt.number(model.exactP, 3)})';
    }
    if (model.pValues.isEmpty) return null;
    return 'efecto ${Fmt.number(model.effect, 1)}σ, n = ${model.n}: ${Fmt.percent(model.rejectionRate)} de '
        '${Fmt.integer(model.pValues.length)} estudios rechazó H0';
  }

  @override
  Widget build(BuildContext context) {
    return ExperimentFrame(
      experiment: widget.experiment,
      runs: model.runs,
      color: widget.color,
      measured: _measured,
      builder: (context, enabled) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (widget.experiment == null) ...[
          SegmentedButton<NullMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: NullMode.coin, label: Text('p-valor simulado'), icon: Icon(Icons.toll_rounded)),
              ButtonSegment(value: NullMode.studies, label: Text('Errores y potencia'), icon: Icon(Icons.stacked_line_chart_rounded)),
            ],
            selected: {model.mode},
            onSelectionChanged: (s) => setState(() => model.mode = s.first),
          ),
          const SizedBox(height: 10),
        ],
        if (model.mode == NullMode.coin) _coin(context) else _studies(context),
      ]),
    );
  }

  Widget _coin(BuildContext context) {
    final pal = ChartPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('H0: tu compañero adivina al azar (p = 0,5). H1: acierta más que el azar (p > 0,5).', style: t.bodyMedium),
      const SizedBox(height: 6),
      Row(children: [
        Text('Aciertos observados: ${model.observed} de 25', style: const TextStyle(fontWeight: FontWeight.w700)),
        Expanded(
          child: Slider(
            value: model.observed.toDouble(),
            min: 10,
            max: 25,
            divisions: 15,
            label: '${model.observed}',
            onChanged: (v) => setState(() => model.observed = v.round()),
          ),
        ),
      ]),
      ChartPanel(
        title: 'Aciertos en ${Fmt.integer(model.coinSims.length)} series simuladas bajo H0',
        subtitle: 'En rojo: series con ${model.observed} o más aciertos, tan extremas o más que lo observado.',
        height: 170,
        child: CustomPaint(
          painter: DiscreteBarsPainter(
            counts: model.coinCounts,
            maxValue: NullWorldModel.coinN,
            color: pal.population,
            palette: pal,
            highlightFrom: model.observed,
            observed: model.observed,
          ),
        ),
      ),
      const SizedBox(height: 8),
      RunButtons(
        counts: const [1, 100, 1000],
        verb: 'Simular serie',
        color: widget.color,
        onRun: (k) => setState(() => model.simulateCoin(k)),
        onReset: () => setState(() => model.coinSims = []),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: StatTile(
            label: 'p-valor simulado',
            value: model.coinSims.isEmpty ? '—' : Fmt.number(model.simulatedP, 3),
            caption: 'proporción en rojo',
            color: pal.reject,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatTile(
            label: 'p-valor exacto (binomial)',
            value: model.coinSims.length < 100 ? 'Simula 100+' : Fmt.number(model.exactP, 4),
            color: pal.parameter,
          ),
        ),
      ]),
    ]);
  }

  Widget _studies(BuildContext context) {
    final pal = ChartPalette.of(context);
    final t = Theme.of(context).textTheme;
    final curve = [
      for (var n = 5; n <= 160; n += 5) Offset(n.toDouble(), model.theoreticalPower(n)),
    ];
    final points = [for (final e in model.rateByN.entries) Offset(e.key.toDouble(), e.value)];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Cada «estudio» toma una muestra de n personas y hace una prueba t bilateral de H0: μ = 0 con α = 0,05.',
          style: t.bodyMedium),
      const SizedBox(height: 6),
      DiscreteSlider(
        label: 'Efecto',
        values: effects,
        value: model.effect,
        format: (v) => '${Fmt.number(v.toDouble(), 1)}σ',
        onChanged: (v) => setState(() => model.setEffect(v.toDouble())),
      ),
      DiscreteSlider(
        label: 'n',
        values: NullWorldModel.sizes,
        value: model.n,
        onChanged: (v) => setState(() => model.setN(v.toInt())),
      ),
      Text(model.effect == 0 ? 'Efecto real 0: H0 es cierta. Todo rechazo es un error tipo I.'
          : 'Efecto real ${Fmt.number(model.effect, 1)}σ: H0 es falsa. Todo no rechazo es un error tipo II.',
          style: t.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      ChartPanel(
        title: 'p-valores de ${Fmt.integer(model.pValues.length)} estudios',
        subtitle: 'En rojo, los p ≤ 0,05 (rechazan H0).',
        height: 140,
        child: CustomPaint(
          painter: HistogramPainter(
            values: model.pValues, min: 0, max: 1, bins: 20, color: pal.population, palette: pal,
            highlight: (c) => c <= model.alpha, highlightColor: pal.reject,
            format: (v) => Fmt.number(v, 1),
            markers: [ChartMarker(model.alpha, pal.reject, label: 'α')],
            emptyText: 'Ejecuta estudios',
          ),
        ),
      ),
      const SizedBox(height: 8),
      RunButtons(
        counts: const [10, 100, 500],
        verb: 'Estudios',
        color: widget.color,
        onRun: (k) => setState(() => model.runStudies(k)),
        onReset: () => setState(() => model.setEffect(model.effect)),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
          child: StatTile(
            label: model.effect == 0 ? 'Tasa de error tipo I' : 'Potencia simulada',
            value: model.pValues.isEmpty ? '—' : Fmt.percent(model.rejectionRate),
            color: model.effect == 0 ? pal.reject : pal.accept,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: StatTile(
            label: model.effect == 0 ? 'α fijado' : 'Potencia teórica',
            value: model.effect == 0 ? '5 %' : Fmt.percent(model.theoreticalPower(model.n)),
          ),
        ),
      ]),
      if (model.effect > 0) ...[
        const SizedBox(height: 10),
        ChartPanel(
          title: 'Potencia según n (efecto ${Fmt.number(model.effect, 1)}σ)',
          subtitle: 'Curva teórica; puntos ámbar = tus simulaciones (100+ estudios por n).',
          height: 150,
          child: CustomPaint(
            painter: PowerCurvePainter(curve: curve, points: points, palette: pal, xMax: 160, current: model.n.toDouble()),
          ),
        ),
      ],
    ]);
  }
}
