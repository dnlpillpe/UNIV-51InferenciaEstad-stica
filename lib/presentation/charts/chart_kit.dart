import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Marco de coordenadas de un gráfico: traduce datos a píxeles.
class ChartFrame {
  ChartFrame(
    this.size, {
    required this.xMin,
    required this.xMax,
    this.yMin = 0,
    required this.yMax,
    this.left = 12,
    this.right = 12,
    this.top = 12,
    this.bottom = 26,
  });

  final Size size;
  final double xMin, xMax, yMin, yMax;
  final double left, right, top, bottom;

  Rect get plot => Rect.fromLTRB(left, top, size.width - right, size.height - bottom);

  double x(double v) {
    final span = xMax - xMin;
    if (span == 0) return plot.center.dx;
    return plot.left + (v - xMin) / span * plot.width;
  }

  double y(double v) {
    final span = yMax - yMin;
    if (span == 0) return plot.bottom;
    return plot.bottom - (v - yMin) / span * plot.height;
  }

  double xInv(double px) => xMin + (px - plot.left) / plot.width * (xMax - xMin);
}

/// Marca vertical con etiqueta (μ, x̄, valor observado...).
class ChartMarker {
  const ChartMarker(this.value, this.color, {this.label, this.dashed = false, this.width = 2});
  final double value;
  final Color color;
  final String? label;
  final bool dashed;
  final double width;
}

void drawLabel(
  Canvas canvas,
  String text,
  Offset at, {
  required Color color,
  double fontSize = 10,
  FontWeight weight = FontWeight.w500,
  TextAlign align = TextAlign.center,
  bool above = false,
  Color? background,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  var dx = at.dx;
  if (align == TextAlign.center) dx -= tp.width / 2;
  if (align == TextAlign.right) dx -= tp.width;
  final dy = above ? at.dy - tp.height : at.dy;
  if (background != null) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(dx - 3, dy - 1, tp.width + 6, tp.height + 2),
        const Radius.circular(4),
      ),
      Paint()..color = background,
    );
  }
  tp.paint(canvas, Offset(dx, dy));
}

void drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint, {double dash = 5, double gap = 4}) {
  final d = (b - a).distance;
  if (d == 0) return;
  final dir = (b - a) / d;
  var t = 0.0;
  while (t < d) {
    final e = math.min(t + dash, d);
    canvas.drawLine(a + dir * t, a + dir * e, paint);
    t = e + gap;
  }
}

/// Eje horizontal con marcas «bonitas».
void drawXAxis(
  Canvas canvas,
  ChartFrame f,
  ChartPalette pal, {
  String Function(double)? format,
  int ticks = 5,
  bool gridLines = false,
}) {
  final axis = Paint()
    ..color = pal.muted.withValues(alpha: 0.6)
    ..strokeWidth = 1;
  canvas.drawLine(Offset(f.plot.left, f.plot.bottom), Offset(f.plot.right, f.plot.bottom), axis);
  final values = Fmt.niceTicks(f.xMin, f.xMax, ticks);
  for (final v in values) {
    final px = f.x(v);
    if (px < f.plot.left - 1 || px > f.plot.right + 1) continue;
    canvas.drawLine(Offset(px, f.plot.bottom), Offset(px, f.plot.bottom + 4), axis);
    if (gridLines) {
      canvas.drawLine(Offset(px, f.plot.top), Offset(px, f.plot.bottom), Paint()..color = pal.grid);
    }
    drawLabel(canvas, (format ?? Fmt.auto)(v), Offset(px, f.plot.bottom + 6), color: pal.muted);
  }
}

void drawMarker(Canvas canvas, ChartFrame f, ChartMarker m, {bool labelTop = true}) {
  final px = f.x(m.value);
  if (px < f.plot.left - 2 || px > f.plot.right + 2) return;
  final p = Paint()
    ..color = m.color
    ..strokeWidth = m.width;
  final a = Offset(px, f.plot.top + (m.label != null ? 12 : 0));
  final b = Offset(px, f.plot.bottom);
  if (m.dashed) {
    drawDashedLine(canvas, a, b, p);
  } else {
    canvas.drawLine(a, b, p);
  }
  if (m.label != null) {
    drawLabel(canvas, m.label!, Offset(px, f.plot.top), color: m.color, weight: FontWeight.w800, fontSize: 11);
  }
}
