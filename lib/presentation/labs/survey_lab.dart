import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/models/lab_models.dart';
import '../../domain/simulation/city_survey.dart';
import '../charts/survey_painters.dart';
import 'experiment_frame.dart';
import 'lab_controls.dart';
import 'lab_view_models.dart';

/// Laboratorio 1 — Encuesta en Villa Muestra.
class SurveyLab extends StatefulWidget {
  const SurveyLab({super.key, required this.experiment, required this.color});
  final LabExperiment? experiment;
  final Color color;

  @override
  State<SurveyLab> createState() => _SurveyLabState();
}

class _SurveyLabState extends State<SurveyLab> {
  final model = SurveyLabModel();
  int _mapRow = 1;

  static const List<int> sizes = [10, 25, 40, 50, 100, 200, 300];

  @override
  void initState() {
    super.initState();
    model.preset(widget.experiment?.id);
  }

  Color _rowColor(int i) => i == 0 ? AppColors.m1 : AppColors.m3;

  @override
  Widget build(BuildContext context) {
    final measured = model.rows.map((r) =>
        '${r.method.label} (n = ${r.n}): centro ${Fmt.percent(r.mean)}, dispersión ${Fmt.number(r.spread * 100, 1)} puntos').join(' · ');
    return ExperimentFrame(
      experiment: widget.experiment,
      runs: model.runs,
      color: widget.color,
      measured: model.runs == 0 ? null : '$measured. Valor real: ${Fmt.percent(model.truth)}.',
      builder: (context, enabled) => _body(context, enabled),
    );
  }

  Widget _body(BuildContext context, bool enabled) {
    final pal = ChartPalette.of(context);
    final t = Theme.of(context).textTheme;
    final shown = model.rows[_mapRow].last;
    final free = widget.experiment == null;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ChartPanel(
        title: 'Villa Muestra · 600 residentes',
        subtitle: 'Punto de color = usa transporte público a diario. Anillo = encuestado en la última muestra.',
        height: 200,
        trailing: SegmentedButton<int>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [ButtonSegment(value: 0, label: Text('A')), ButtonSegment(value: 1, label: Text('B'))],
          selected: {_mapRow},
          onSelectionChanged: (s) => setState(() => _mapRow = s.first),
        ),
        child: CustomPaint(
          painter: CityGridPainter(
            city: model.city,
            selected: shown?.indices.toSet() ?? const {},
            palette: pal,
            highlight: _rowColor(_mapRow),
          ),
        ),
      ),
      const SizedBox(height: 8),
      for (var i = 0; i < model.rows.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(children: [
            CircleAvatar(radius: 12, backgroundColor: _rowColor(i), child: Text(i == 0 ? 'A' : 'B', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
            const SizedBox(width: 8),
            Expanded(
              child: free
                  ? DropdownButton<SamplingMethod>(
                      isExpanded: true,
                      value: model.rows[i].method,
                      items: [for (final m in SamplingMethod.values) DropdownMenuItem(value: m, child: Text(m.label))],
                      onChanged: (m) => setState(() => model.setMethod(i, m!)),
                    )
                  : Text('${model.rows[i].method.label} · n = ${model.rows[i].n}', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (free)
              DropdownButton<int>(
                value: sizes.contains(model.rows[i].n) ? model.rows[i].n : 25,
                items: [for (final s in sizes) DropdownMenuItem(value: s, child: Text('n = $s'))],
                onChanged: (v) => setState(() => model.setN(i, v!)),
              ),
          ]),
        ),
      Text(model.rows[_mapRow].method.description, style: t.bodySmall),
      const SizedBox(height: 10),
      RunButtons(
        counts: const [1, 10, 50],
        verb: 'Encuestar',
        color: widget.color,
        onRun: (k) => setState(() => model.draw(k)),
        onReset: () => setState(model.reset),
      ),
      const SizedBox(height: 10),
      ChartPanel(
        title: 'Estimaciones repetidas (${model.runs} encuestas por método)',
        subtitle: 'Cada punto es el % que dio una encuesta. La raya gruesa es el promedio de cada método.',
        height: 150,
        child: CustomPaint(
          painter: StripPlotPainter(
            rows: [
              for (var i = 0; i < model.rows.length; i++)
                StripRow('${i == 0 ? 'A' : 'B'} · ${model.rows[i].method.label} (n = ${model.rows[i].n})', model.rows[i].estimates, _rowColor(i)),
            ],
            truth: model.truth,
            palette: pal,
          ),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        for (var i = 0; i < model.rows.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: StatTile(
              label: '${i == 0 ? 'A' : 'B'}: sesgo · dispersión',
              value: model.rows[i].estimates.isEmpty
                  ? '—'
                  : '${Fmt.number((model.rows[i].mean - model.truth) * 100, 1)} · ${model.rows[i].estimates.length < 2 ? '—' : Fmt.number(model.rows[i].spread * 100, 1)}',
              caption: 'en puntos porcentuales',
              color: _rowColor(i),
            ),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (var d = 0; d < CitySurvey.districts.length; d++)
          Pill('${CitySurvey.districts[d].name}: ${Fmt.percent(model.city.districtProportion(d), 0)}', color: Colors.blueGrey),
      ]),
    ]);
  }
}
