import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/simulation/interval_simulator.dart';
import 'chart_kit.dart';

/// Lluvia de intervalos: cada fila es el intervalo de un investigador.
/// Ámbar = captura a μ; coral con marca = falla. μ es la línea vertical.
class IntervalRainPainter extends CustomPainter {
  IntervalRainPainter({
    required this.intervals,
    required this.mu,
    required this.xMin,
    required this.xMax,
    required this.palette,
    this.maxRows = 100,
  });

  final List<SimulatedInterval> intervals;
  final double mu;
  final double xMin, xMax;
  final ChartPalette palette;
  final int maxRows;

  @override
  void paint(Canvas canvas, Size size) {
    final f = ChartFrame(size, xMin: xMin, xMax: xMax, yMax: 1, top: 18, bottom: 24);
    final shown = intervals.length > maxRows
        ? intervals.sublist(intervals.length - maxRows)
        : intervals;
    final rowH = f.plot.height / maxRows;
    final stroke = (rowH * 0.62).clamp(1.0, 4.0);
    for (var i = 0; i < shown.length; i++) {
      final it = shown[i];
      final y = f.plot.top + (i + 0.5) * rowH;
      final color = it.captured ? palette.confidence : palette.reject;
      final a = f.x(it.lower).clamp(f.plot.left, f.plot.right);
      final b = f.x(it.upper).clamp(f.plot.left, f.plot.right);
      final isNewest = i == shown.length - 1;
      canvas.drawLine(
        Offset(a, y),
        Offset(b, y),
        Paint()
          ..color = color.withValues(alpha: isNewest ? 1 : 0.85)
          ..strokeWidth = it.captured ? stroke : stroke + 0.8
          ..strokeCap = StrokeCap.round,
      );
      final e = f.x(it.estimate);
      if (e >= f.plot.left && e <= f.plot.right) {
        canvas.drawCircle(Offset(e, y), stroke * 0.7 + 0.4, Paint()..color = palette.ink.withValues(alpha: 0.55));
      }
      if (!it.captured) {
        // Marca lateral: los fallos se reconocen también sin color.
        canvas.drawCircle(Offset(f.plot.right - 3, y), stroke * 0.6 + 1, Paint()..color = palette.reject);
      }
    }
    drawXAxis(canvas, f, palette);
    drawMarker(canvas, f, ChartMarker(mu, palette.parameter, label: 'μ', width: 2.2));
  }

  @override
  bool shouldRepaint(covariant IntervalRainPainter old) => true;
}
