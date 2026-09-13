import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/stats/descriptive.dart';
import 'chart_kit.dart';

/// Histograma de valores continuos, con marcas y curva opcional.
///
/// Las barras van siempre juntas: separarlas sugeriría categorías, y el
/// histograma es de una variable continua.
class HistogramPainter extends CustomPainter {
  HistogramPainter({
    required this.values,
    required this.min,
    required this.max,
    required this.bins,
    required this.color,
    required this.palette,
    this.markers = const [],
    this.curve,
    this.highlight,
    this.highlightColor,
    this.format,
    this.showAxis = true,
    this.emptyText,
  });

  final List<double> values;
  final double min, max;
  final int bins;
  final Color color;
  final ChartPalette palette;
  final List<ChartMarker> markers;

  /// Densidad teórica a superponer (en unidades de la variable).
  final double Function(double)? curve;

  /// Si se indica, las barras cuyo centro cumple la condición se resaltan.
  final bool Function(double center)? highlight;
  final Color? highlightColor;
  final String Function(double)? format;
  final bool showAxis;
  final String? emptyText;

  @override
  void paint(Canvas canvas, Size size) {
    final counts = Descriptive.histogram(values, min, max, bins);
    final maxCount = counts.isEmpty ? 0 : counts.reduce(math.max);
    final w = (max - min) / bins;
    // Escala vertical en densidad para poder superponer la curva.
    final n = values.length;
    double density(int c) => n == 0 ? 0 : c / (n * w);
    var yMax = maxCount == 0 ? 1.0 : density(maxCount);
    if (curve != null) {
      for (var i = 0; i <= 60; i++) {
        yMax = math.max(yMax, curve!(min + (max - min) * i / 60));
      }
    }
    final f = ChartFrame(size, xMin: min, xMax: max, yMax: yMax * 1.12, bottom: showAxis ? 24 : 6, top: 16);

    if (n == 0 && emptyText != null) {
      drawLabel(canvas, emptyText!, f.plot.center, color: palette.muted, fontSize: 12);
    }
    final fill = Paint()..color = color.withValues(alpha: 0.78);
    final hi = Paint()..color = (highlightColor ?? palette.reject).withValues(alpha: 0.88);
    for (var i = 0; i < bins; i++) {
      if (counts[i] == 0) continue;
      final x0 = f.x(min + i * w), x1 = f.x(min + (i + 1) * w);
      final top = f.y(density(counts[i]));
      final center = min + (i + 0.5) * w;
      final r = Rect.fromLTRB(x0, top, x1, f.plot.bottom);
      canvas.drawRect(r, (highlight?.call(center) ?? false) ? hi : fill);
      canvas.drawLine(Offset(x0, top), Offset(x1, top),
          Paint()..color = color.withValues(alpha: 1)..strokeWidth = 1);
    }
    if (curve != null) {
      final path = Path();
      for (var i = 0; i <= 120; i++) {
        final xv = min + (max - min) * i / 120;
        final pt = Offset(f.x(xv), f.y(curve!(xv)));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = palette.ink.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (showAxis) drawXAxis(canvas, f, palette, format: format);
    for (final m in markers) {
      drawMarker(canvas, f, m);
    }
  }

  @override
  bool shouldRepaint(covariant HistogramPainter old) =>
      old.values.length != values.length ||
      !identical(old.values, values) ||
      old.min != min ||
      old.max != max ||
      old.bins != bins ||
      old.color != color ||
      old.markers.length != markers.length;
}
