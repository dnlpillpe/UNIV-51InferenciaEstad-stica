import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'chart_kit.dart';

/// Gráfico de puntos apilados: cada valor es un punto que «cae» en su
/// columna. Con pocas repeticiones muestra que cada media es una muestra
/// concreta; con muchas se convierte en la forma de la distribución.
class DotStackPainter extends CustomPainter {
  DotStackPainter({
    required this.values,
    required this.min,
    required this.max,
    required this.color,
    required this.palette,
    this.columns = 40,
    this.markers = const [],
    this.highlightLast = true,
    this.format,
  });

  final List<double> values;
  final double min, max;
  final Color color;
  final ChartPalette palette;
  final int columns;
  final List<ChartMarker> markers;
  final bool highlightLast;
  final String Function(double)? format;

  @override
  void paint(Canvas canvas, Size size) {
    final f = ChartFrame(size, xMin: min, xMax: max, yMax: 1, top: 16);
    final colW = f.plot.width / columns;
    final counts = List<int>.filled(columns, 0);
    final positions = <Offset>[];
    for (final v in values) {
      if (v < min || v > max) {
        positions.add(Offset.infinite);
        continue;
      }
      var c = ((v - min) / (max - min) * columns).floor();
      if (c >= columns) c = columns - 1;
      positions.add(Offset(c.toDouble(), counts[c].toDouble()));
      counts[c]++;
    }
    final maxStack = counts.isEmpty ? 1 : math.max(1, counts.reduce(math.max));
    final r = math.min(colW / 2 * 0.9, f.plot.height / maxStack / 2 * 0.95);
    final step = f.plot.height / math.max(maxStack, f.plot.height / (2 * r));
    final paint = Paint()..color = color.withValues(alpha: 0.85);
    for (var i = 0; i < positions.length; i++) {
      final p = positions[i];
      if (p == Offset.infinite) continue;
      final cx = f.plot.left + (p.dx + 0.5) * colW;
      final cy = f.plot.bottom - (p.dy + 0.5) * step;
      final isLast = highlightLast && i == positions.length - 1;
      canvas.drawCircle(
        Offset(cx, cy),
        isLast ? math.max(r * 1.4, 3) : math.max(r, 0.8),
        isLast ? (Paint()..color = palette.estimate) : paint,
      );
    }
    drawXAxis(canvas, f, palette, format: format);
    for (final m in markers) {
      drawMarker(canvas, f, m);
    }
  }

  @override
  bool shouldRepaint(covariant DotStackPainter old) => true;
}
