import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/models/lab_models.dart';
import '../../domain/stats/descriptive.dart';
import '../charts/bars_painters.dart';
import '../charts/chart_kit.dart';
import '../charts/histogram_painter.dart';
import 'experiment_frame.dart';
import 'lab_controls.dart';
import 'lab_view_models.dart';

/// Laboratorio 5 — Sala de decisiones.
class DecisionRoomLab extends StatefulWidget {
  const DecisionRoomLab({super.key, required this.experiment, required this.color});
  final LabExperiment? experiment;
  final Color color;

  @override
  State<DecisionRoomLab> createState() => _DecisionRoomLabState();
}

class _DecisionRoomLabState extends State<DecisionRoomLab> {
  final model = DecisionRoomModel();

  @override
  void initState() {
    super.initState();
    model.preset(widget.experiment?.id);
  }

  String? get _measured {
    switch (model.mode) {
      case RoomMode.permutation:
        if (model.diffs.isEmpty) return null;
        return 'p por permutación ≈ ${Fmt.number(model.permP, 3)} con ${Fmt.integer(model.diffs.length)} barajadas '
            '(prueba t de Welch: p = ${Fmt.pValue(model.welch.pValue)})';
      case RoomMode.multiple:
        if (model.families.isEmpty) return null;
        return '${Fmt.percent(model.familyRate)} de ${model.families.length} analistas encontró al menos un «hallazgo»'
            '${model.bonferroni ? ' (con Bonferroni)' : ''}';
      case RoomMode.bigSample:
        if (model.studies.isEmpty) return null;
        return [
          for (final n in DecisionRoomModel.sizes)
            if (model.studiesFor(n).isNotEmpty)
              'n = ${Fmt.integer(n)}: ${Fmt.percent(model.studiesFor(n).where((s) => s.p <= 0.05).length / model.studiesFor(n).length, 0)} significativos',
        ].join(' · ');
    }
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<RoomMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: RoomMode.permutation, label: Text('Permutación')),
                ButtonSegment(value: RoomMode.multiple, label: Text('Muchas pruebas')),
                ButtonSegment(value: RoomMode.bigSample, label: Text('n enorme')),
              ],
              selected: {model.mode},
              onSelectionChanged: (s) => setState(() => model.mode = s.first),
            ),
          ),
          const SizedBox(height: 10),
        ],
        switch (model.mode) {
          RoomMode.permutation => _permutation(context),
          RoomMode.multiple => _multiple(context),
          RoomMode.bigSample => _big(context),
        },
      ]),
    );
  }

  Widget _scores(String label, List<double> values, Color c) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label · media ${Fmt.number(Descriptive.mean(values), 2)}', style: TextStyle(fontWeight: FontWeight.w800, color: c)),
      const SizedBox(height: 4),
      Wrap(spacing: 4, runSpacing: 4, children: [
        for (final v in values)
          Container(
            width: 30,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(6)),
            child: Text(Fmt.number(v, 0), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
      ]),
    ]);
  }

  Widget _permutation(BuildContext context) {
    final pal = ChartPalette.of(context);
    final t = Theme.of(context).textTheme;
    final obs = model.perm.observed;
    final shuffled = model.diffs.isNotEmpty;
    final range = math.max(3.0, obs.abs() * 1.4);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Notas del examen final (0–20). Los 24 estudiantes se asignaron al azar a cada método.', style: t.bodyMedium),
      const SizedBox(height: 8),
      _scores(shuffled ? 'Grupo «A» tras barajar' : 'Aprendizaje activo (A)', model.lastA, AppColors.m5),
      const SizedBox(height: 8),
      _scores(shuffled ? 'Grupo «B» tras barajar' : 'Clase expositiva (B)', model.lastB, AppColors.m1),
      const SizedBox(height: 8),
      Text('Diferencia observada A − B: ${Fmt.number(obs, 2)} puntos', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      ChartPanel(
        title: 'Diferencias en ${Fmt.integer(model.diffs.length)} reasignaciones al azar',
        subtitle: 'En rojo, las diferencias tan extremas o más que la observada (en cualquier dirección).',
        height: 150,
        child: CustomPaint(
          painter: HistogramPainter(
            values: model.diffs, min: -range, max: range, bins: 36, color: pal.population, palette: pal,
            highlight: (c) => c.abs() >= obs.abs(), highlightColor: pal.reject,
            markers: [
              ChartMarker(obs, pal.estimate, label: 'observada'),
              ChartMarker(-obs, pal.estimate, dashed: true),
            ],
            emptyText: 'Pulsa «Barajar»',
          ),
        ),
      ),
      const SizedBox(height: 8),
      RunButtons(
        counts: const [1, 100, 1000],
        verb: 'Barajar',
        color: widget.color,
        onRun: (k) => setState(() => model.shuffle(k)),
        onReset: () => setState(() => model.preset('e5_1')),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: StatTile(label: 'p por permutación', value: model.diffs.isEmpty ? '—' : Fmt.number(model.permP, 3), color: pal.reject)),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Prueba t de Welch', value: model.diffs.length < 1000 ? 'Baraja 1000+' : 'p = ${Fmt.pValue(model.welch.pValue)}')),
      ]),
    ]);
  }

  Widget _multiple(BuildContext context) {
    final pal = ChartPalette.of(context);
    final t = Theme.of(context).textTheme;
    final counts = List<int>.filled(7, 0);
    for (final h in model.families) {
      counts[math.min(h, 6)]++;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Cada analista compara ${DecisionRoomModel.tests} indicadores entre dos grupos de ${DecisionRoomModel.nPerGroup} '
          'sin ninguna diferencia real, con α = ${Fmt.number(model.alphaPerTest, 4)} por prueba.', style: t.bodyMedium),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: model.bonferroni,
        onChanged: (v) => setState(() => model.setBonferroni(v)),
        title: const Text('Corrección de Bonferroni (α/20)'),
      ),
      ChartPanel(
        title: '«Hallazgos» por analista (${model.families.length} analistas)',
        subtitle: 'Todo lo que no es 0 es un falso positivo.',
        height: 150,
        child: CustomPaint(
          painter: DiscreteBarsPainter(counts: counts, maxValue: 6, color: pal.population, palette: pal, highlightFrom: 1),
        ),
      ),
      const SizedBox(height: 8),
      RunButtons(
        counts: const [10, 50],
        verb: 'Analistas',
        color: widget.color,
        onRun: (k) => setState(() => model.runFamilies(k)),
        onReset: () => setState(() => model.setBonferroni(model.bonferroni)),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: StatTile(label: 'Con al menos un hallazgo', value: model.families.isEmpty ? '—' : Fmt.percent(model.familyRate), color: pal.reject)),
        const SizedBox(width: 8),
        Expanded(
          child: StatTile(
            label: 'Teórico 1 − (1 − α)²⁰',
            value: Fmt.percent(1 - math.pow(1 - model.alphaPerTest, DecisionRoomModel.tests).toDouble()),
          ),
        ),
      ]),
    ]);
  }

  Widget _big(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pal = ChartPalette.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('El efecto real es siempre 0,02 s (desviación 0,9 s): d de Cohen ≈ 0,02. Solo cambia el tamaño de cada grupo.',
          style: t.bodyMedium),
      const SizedBox(height: 8),
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: [for (final n in DecisionRoomModel.sizes) ButtonSegment(value: n, label: Text('n = ${Fmt.integer(n)}'))],
        selected: {model.bigN},
        onSelectionChanged: (s) => setState(() => model.bigN = s.first),
      ),
      const SizedBox(height: 8),
      RunButtons(
        counts: const [1, 10],
        verb: 'Estudio',
        color: widget.color,
        onRun: (k) => setState(() => model.runBig(k)),
        onReset: () => setState(() => model.studies = []),
      ),
      const SizedBox(height: 10),
      for (final n in DecisionRoomModel.sizes)
        Builder(builder: (context) {
          final list = model.studiesFor(n);
          final sig = list.where((s) => s.p <= 0.05).length;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('n = ${Fmt.integer(n)} por grupo', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('${list.length} estudios', style: t.labelSmall),
                ]),
                const SizedBox(height: 6),
                ThinProgress(value: list.isEmpty ? 0 : sig / list.length, color: pal.reject, height: 8),
                const SizedBox(height: 6),
                Text(
                  list.isEmpty
                      ? 'Sin estudios todavía.'
                      : 'Significativos: $sig de ${list.length} · último p = ${Fmt.pValue(list.last.p)} · d = ${Fmt.number(list.last.d, 3)}',
                  style: t.bodySmall,
                ),
              ]),
            ),
          );
        }),
    ]);
  }
}
