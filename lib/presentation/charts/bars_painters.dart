import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import 'chart_kit.dart';

/// Barras para un conteo entero (número de aciertos en 25 lanzamientos).
/// Es una variable discreta: aquí las barras sí van separadas.
class DiscreteBarsPainter extends CustomPainter {
  DiscreteBarsPainter({
    required this.counts,
    required this.maxValue,
    required this.color,
    required this.palette,
    this.highlightFrom,
    this.observed,
  });

  final List<int> counts; // índice = valor
  final int maxValue;
  final Color color;
  final ChartPalette palette;
  final int? highlightFrom;
  final int? observed;

  @override
  void paint(Canvas canvas, Size size) {
    final maxC = counts.isEmpty ? 1 : math.max(1, counts.reduce(math.max));
    final f = ChartFrame(size, xMin: -0.5, xMax: maxValue + 0.5, yMax: maxC * 1.1, top: 18);
    final bw = f.plot.width / (maxValue + 1) * 0.78;
    for (var v = 0; v < counts.length && v <= maxValue; v++) {
      if (counts[v] == 0) continue;
      final cx = f.x(v.toDouble());
      final hot = highlightFrom != null && v >= highlightFrom!;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTRB(cx - bw / 2, f.y(counts[v].toDouble()), cx + bw / 2, f.plot.bottom),
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        Paint()..color = hot ? palette.reject : color.withValues(alpha: 0.75),
      );
    }
    drawXAxis(canvas, f, palette, format: (v) => Fmt.number(v, 0));
    if (observed != null) {
      drawMarker(canvas, f, ChartMarker(observed! - 0.5, palette.estimate, label: 'observado ${observed!}', dashed: true));
    }
  }

  @override
  bool shouldRepaint(covariant DiscreteBarsPainter old) => true;
}

/// Curva de potencia teórica con los puntos simulados encima.
class PowerCurvePainter extends CustomPainter {
  PowerCurvePainter({
    required this.curve,
    required this.palette,
    required this.xMax,
    this.points = const [],
    this.current,
    this.alpha = 0.05,
    this.xLabel = 'n',
  });

  final List<Offset> curve; // (x, potencia)
  final List<Offset> points;
  final ChartPalette palette;
  final double xMax;
  final double? current;
  final double alpha;
  final String xLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final f = ChartFrame(size, xMin: 0, xMax: xMax, yMax: 1.05, left: 30, top: 14);
    for (final yv in [0.0, 0.25, 0.5, 0.75, 1.0]) {
      final y = f.y(yv);
      canvas.drawLine(Offset(f.plot.left, y), Offset(f.plot.right, y), Paint()..color = palette.grid);
      drawLabel(canvas, Fmt.percent(yv, 0), Offset(f.plot.left - 4, y - 6),
          color: palette.muted, fontSize: 9, align: TextAlign.right);
    }
    final y80 = f.y(0.8);
    drawDashedLine(canvas, Offset(f.plot.left, y80), Offset(f.plot.right, y80),
        Paint()..color = palette.accept..strokeWidth = 1.2);
    drawLabel(canvas, '80 %', Offset(f.plot.right, y80 - 13), color: palette.accept, fontSize: 9, align: TextAlign.right);
    final ya = f.y(alpha);
    drawDashedLine(canvas, Offset(f.plot.left, ya), Offset(f.plot.right, ya),
        Paint()..color = palette.reject..strokeWidth = 1);

    if (curve.length > 1) {
      final path = Path()..moveTo(f.x(curve.first.dx), f.y(curve.first.dy));
      for (final p in curve.skip(1)) {
        path.lineTo(f.x(p.dx), f.y(p.dy));
      }
      canvas.drawPath(path, Paint()..color = palette.ink..strokeWidth = 2.2..style = PaintingStyle.stroke);
    }
    for (final p in points) {
      canvas.drawCircle(Offset(f.x(p.dx), f.y(p.dy)), 4.5, Paint()..color = palette.confidence);
      canvas.drawCircle(Offset(f.x(p.dx), f.y(p.dy)), 4.5,
          Paint()..color = palette.ink..style = PaintingStyle.stroke..strokeWidth = 1);
    }
    if (current != null) {
      drawMarker(canvas, f, ChartMarker(current!, palette.estimate, label: '$xLabel = ${Fmt.number(current!, 0)}', dashed: true));
    }
    drawXAxis(canvas, f, palette, format: (v) => Fmt.number(v, 0));
  }

  @override
  bool shouldRepaint(covariant PowerCurvePainter old) => true;
}
