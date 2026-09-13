import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/stats/inference.dart';
import '../charts/chart_kit.dart';
import '../charts/density_painter.dart';

/// Resultado de una prueba: curva de referencia con el p-valor sombreado,
/// el estadístico observado y los valores críticos para α.
class TestResultView extends StatelessWidget {
  const TestResultView({super.key, required this.result, required this.alpha});
  final TestResult result;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    final pal = ChartPalette.of(context);
    final r = result;
    final s = r.statistic;
    final range = math.max(4.0, math.min(s.abs() + 1, 8.0));
    final shade = pal.reject.withValues(alpha: 0.6);
    final regions = switch (r.tail) {
      Tail.greater => [ShadeRegion(s, range, shade)],
      Tail.less => [ShadeRegion(-range, s, shade)],
      Tail.twoSided => [ShadeRegion(s.abs(), range, shade), ShadeRegion(-range, -s.abs(), shade)],
    };
    final crit = r.criticalValue(alpha);
    final criticals = r.tail == Tail.twoSided ? [-crit.abs(), crit.abs()] : [crit];
    final reject = r.rejectAt(alpha);
    final sym = r.distribution == RefDistribution.t ? 't' : 'z';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 170,
        child: CustomPaint(
          size: const Size(double.infinity, 170),
          painter: DensityPainter(
            palette: pal,
            df: r.distribution == RefDistribution.t ? r.df : null,
            regions: regions,
            observed: s,
            observedLabel: '$sym = ${Fmt.number(s, 2)}',
            criticals: criticals,
            range: range,
          ),
        ),
      ),
      Text(
        'Curva: distribución de $sym si H0 fuera cierta. Área roja = p-valor. Líneas grises = valores críticos para α = ${Fmt.number(alpha, 2)}.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      TileGrid(
        children: [
          StatTile(label: 'Estimación', value: Fmt.auto(r.estimate)),
          StatTile(label: 'Error estándar', value: Fmt.auto(r.se)),
          StatTile(label: 'Estadístico $sym', value: Fmt.number(s, 3)),
          if (r.df != null) StatTile(label: 'Grados de libertad', value: Fmt.number(r.df!, r.df! == r.df!.roundToDouble() ? 0 : 1)),
          StatTile(label: 'p-valor', value: Fmt.pValue(r.pValue), color: reject ? pal.reject : null),
          StatTile(
            label: 'Decisión (α = ${Fmt.number(alpha, 2)})',
            value: reject ? 'Rechazar H0' : 'No rechazar',
            color: reject ? pal.reject : pal.accept,
          ),
        ],
      ),
    ]);
  }
}

/// Resultado de un intervalo: la estimación, su margen y una referencia.
class IntervalView extends StatelessWidget {
  const IntervalView({super.key, required this.ci, this.percent = false, this.reference, this.referenceLabel});
  final ConfidenceInterval ci;
  final bool percent;
  final double? reference;
  final String? referenceLabel;

  String _f(double v) => percent ? Fmt.percent(v, 1) : Fmt.auto(v);

  @override
  Widget build(BuildContext context) {
    final pal = ChartPalette.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        height: 92,
        child: CustomPaint(
          size: const Size(double.infinity, 92),
          painter: _IntervalBarPainter(ci: ci, palette: pal, reference: reference, referenceLabel: referenceLabel, percent: percent),
        ),
      ),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: StatTile(label: 'Límite inferior', value: _f(ci.lower), color: pal.estimate)),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Estimación', value: _f(ci.estimate))),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Límite superior', value: _f(ci.upper), color: pal.estimate)),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: StatTile(label: 'Margen de error', value: '± ${_f(ci.margin)}')),
        const SizedBox(width: 8),
        Expanded(child: StatTile(label: 'Error estándar', value: _f(ci.se))),
        const SizedBox(width: 8),
        Expanded(
          child: StatTile(
            label: ci.distribution == RefDistribution.t ? 'Crítico t' : 'Crítico z',
            value: Fmt.number(ci.critical, 3),
            caption: ci.df == null ? null : '${Fmt.number(ci.df!, ci.df! == ci.df!.roundToDouble() ? 0 : 1)} gl',
          ),
        ),
      ]),
    ]);
  }
}

class _IntervalBarPainter extends CustomPainter {
  _IntervalBarPainter({required this.ci, required this.palette, this.reference, this.referenceLabel, this.percent = false});
  final ConfidenceInterval ci;
  final ChartPalette palette;
  final double? reference;
  final String? referenceLabel;
  final bool percent;

  @override
  void paint(Canvas canvas, Size size) {
    var lo = ci.lower, hi = ci.upper;
    if (reference != null) {
      lo = math.min(lo, reference!);
      hi = math.max(hi, reference!);
    }
    final pad = (hi - lo) * 0.25 + 1e-9;
    final f = ChartFrame(size, xMin: lo - pad, xMax: hi + pad, yMax: 1, top: 22, bottom: 24);
    final y = f.plot.center.dy + 6;
    final bar = Paint()
      ..color = palette.confidence
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(f.x(ci.lower), y), Offset(f.x(ci.upper), y), bar);
    canvas.drawCircle(Offset(f.x(ci.estimate), y), 7, Paint()..color = palette.ink);
    canvas.drawCircle(Offset(f.x(ci.estimate), y), 4, Paint()..color = palette.surface);
    drawLabel(canvas, '${Fmt.number(ci.level * 100, 0)} %', Offset(f.x(ci.estimate), y - 26),
        color: palette.estimate, weight: FontWeight.w800, fontSize: 11);
    drawXAxis(canvas, f, palette, format: percent ? (v) => Fmt.percent(v, 0) : null);
    if (reference != null) {
      drawMarker(canvas, f, ChartMarker(reference!, palette.reject, label: referenceLabel, dashed: true));
    }
  }

  @override
  bool shouldRepaint(covariant _IntervalBarPainter old) => true;
}
