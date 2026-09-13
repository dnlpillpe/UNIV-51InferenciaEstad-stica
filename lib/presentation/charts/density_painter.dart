import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/stats/distributions.dart';
import 'chart_kit.dart';

/// Región sombreada bajo la curva, entre dos valores del estadístico.
class ShadeRegion {
  const ShadeRegion(this.from, this.to, this.color, {this.label});
  final double from;
  final double to;
  final Color color;
  final String? label;
}

/// Curva normal o t con regiones sombreadas, valor observado y valores
/// críticos. Se usa en la calculadora, en los casos y en las lecciones.
class DensityPainter extends CustomPainter {
  DensityPainter({
    required this.palette,
    this.df,
    this.regions = const [],
    this.observed,
    this.observedLabel,
    this.criticals = const [],
    this.range = 4,
    this.compareNormal = false,
    this.lineColor,
  });

  /// Si es nulo, la curva es la normal estándar; si no, t con `df` gl.
  final double? df;
  final ChartPalette palette;
  final List<ShadeRegion> regions;
  final double? observed;
  final String? observedLabel;
  final List<double> criticals;
  final double range;

  /// Superpone la normal estándar (para comparar con t).
  final bool compareNormal;
  final Color? lineColor;

  double _pdf(double x) => df == null ? Distributions.normalPdf(x) : Distributions.tPdf(x, df!);

  @override
  void paint(Canvas canvas, Size size) {
    final f = ChartFrame(size, xMin: -range, xMax: range, yMax: 0.43, top: 18, bottom: 24);
    for (final r in regions) {
      final a = math.max(r.from, -range), b = math.min(r.to, range);
      if (b <= a) continue;
      final path = Path()..moveTo(f.x(a), f.y(0));
      const steps = 60;
      for (var i = 0; i <= steps; i++) {
        final x = a + (b - a) * i / steps;
        path.lineTo(f.x(x), f.y(_pdf(x)));
      }
      path
        ..lineTo(f.x(b), f.y(0))
        ..close();
      canvas.drawPath(path, Paint()..color = r.color);
      if (r.label != null) {
        final mid = (a + b) / 2;
        drawLabel(canvas, r.label!, Offset(f.x(mid), f.y(_pdf(mid) * 0.45)),
            color: palette.ink, fontSize: 10, weight: FontWeight.w700);
      }
    }
    void curve(double Function(double) pdf, Color c, double w, {bool dashed = false}) {
      final path = Path();
      for (var i = 0; i <= 160; i++) {
        final x = -range + 2 * range * i / 160;
        final p = Offset(f.x(x), f.y(pdf(x)));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      if (dashed) {
        final metrics = path.computeMetrics();
        final paint = Paint()
          ..color = c
          ..strokeWidth = w
          ..style = PaintingStyle.stroke;
        for (final m in metrics) {
          var d = 0.0;
          while (d < m.length) {
            canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), paint);
            d += 10;
          }
        }
      } else {
        canvas.drawPath(
          path,
          Paint()
            ..color = c
            ..strokeWidth = w
            ..style = PaintingStyle.stroke,
        );
      }
    }

    if (compareNormal && df != null) {
      curve(Distributions.normalPdf, palette.muted, 1.6, dashed: true);
    }
    curve(_pdf, lineColor ?? palette.ink, 2.2);
    drawXAxis(canvas, f, palette, format: (v) => Fmt.number(v, 0));

    for (final c in criticals) {
      if (c.abs() > range) continue;
      final px = f.x(c);
      drawDashedLine(canvas, Offset(px, f.y(_pdf(c)) - 4), Offset(px, f.plot.bottom),
          Paint()..color = palette.muted..strokeWidth = 1.2);
      drawLabel(canvas, Fmt.number(c, 2), Offset(px, f.y(_pdf(c)) - 16),
          color: palette.muted, fontSize: 10);
    }
    final o = observed;
    if (o != null) {
      final clamped = o.clamp(-range, range);
      final px = f.x(clamped);
      canvas.drawLine(Offset(px, f.plot.top + 12), Offset(px, f.plot.bottom),
          Paint()..color = palette.estimate..strokeWidth = 2.6);
      final txt = observedLabel ?? Fmt.number(o, 2);
      final align = clamped > range * 0.6
          ? TextAlign.right
          : clamped < -range * 0.6
              ? TextAlign.left
              : TextAlign.center;
      drawLabel(canvas, o.abs() > range ? '$txt →' : txt, Offset(px, f.plot.top - 2),
          color: palette.estimate, weight: FontWeight.w800, fontSize: 11, align: align);
    }
  }

  @override
  bool shouldRepaint(covariant DensityPainter old) => true;
}
