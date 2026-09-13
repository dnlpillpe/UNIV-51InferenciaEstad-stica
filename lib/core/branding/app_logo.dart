import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Marca de la app: una campana de Gauss con la franja central de confianza en
/// ámbar y las colas de rechazo en coral, puntos muestrales que caen sobre ella y, debajo, un intervalo de
/// confianza con su estimación. Es el mismo dibujo que genera el icono
/// del lanzador (`tool/generate_icon.py`).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 64, this.rounded = true});

  final double size;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: AppLogoPainter(rounded: rounded)),
    );
  }
}

class AppLogoPainter extends CustomPainter {
  AppLogoPainter({this.rounded = true});

  final bool rounded;

  static double _bell(double x) => math.exp(-0.5 * x * x);

  /// Semiancho de la franja central, en desviaciones (igual que el icono).
  static const double _band = 1.6;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(rounded ? s * 0.22 : 0));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.indigoSoft, AppColors.indigo, AppColors.indigoDeep],
        ).createShader(rect),
    );

    // Geometría de la campana.
    final left = s * 0.12, right = s * 0.88;
    final base = s * 0.66, peak = s * 0.30;
    double px(double z) => left + (z + 3) / 6 * (right - left);
    double py(double z) => base - (base - peak) * _bell(z);

    // Franja central (región de confianza) en ámbar.
    const k = _band;
    final band = Path()..moveTo(px(-k), base);
    for (var z = -k; z <= k; z += 0.05) {
      band.lineTo(px(z), py(z));
    }
    band
      ..lineTo(px(k), py(k))
      ..lineTo(px(k), base)
      ..close();
    canvas.drawPath(band, Paint()..color = AppColors.amber);

    // Colas (región de rechazo) en coral.
    for (final side in [-1, 1]) {
      final tail = Path()..moveTo(px(side * k), base);
      for (var t = k; t <= 3.0; t += 0.05) {
        tail.lineTo(px(side * t), py(side * t));
      }
      tail
        ..lineTo(px(side * 3.0), base)
        ..close();
      canvas.drawPath(tail, Paint()..color = AppColors.coral);
    }

    // Contorno blanco de la campana.
    final curve = Path()..moveTo(px(-3), py(-3));
    for (var z = -3.0; z <= 3.0; z += 0.05) {
      curve.lineTo(px(z), py(z));
    }
    canvas.drawPath(
      curve,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.035
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // Línea base.
    canvas.drawLine(
      Offset(left, base),
      Offset(right, base),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..strokeWidth = s * 0.022
        ..strokeCap = StrokeCap.round,
    );

    // Puntos muestrales que caen.
    final dot = Paint()..color = Colors.white;
    final dots = [
      Offset(px(-0.9), s * 0.17),
      Offset(px(0.15), s * 0.12),
      Offset(px(1.05), s * 0.19),
    ];
    for (final d in dots) {
      canvas.drawCircle(d, s * 0.032, dot);
    }

    // Intervalo de confianza bajo la curva.
    final y = s * 0.80;
    final ci = Paint()
      ..color = AppColors.amber
      ..strokeWidth = s * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(px(-1.5), y), Offset(px(1.7), y), ci);
    canvas.drawLine(Offset(px(-1.5), y - s * 0.05), Offset(px(-1.5), y + s * 0.05), ci);
    canvas.drawLine(Offset(px(1.7), y - s * 0.05), Offset(px(1.7), y + s * 0.05), ci);
    canvas.drawCircle(Offset(px(0.1), y), s * 0.045, Paint()..color = Colors.white);

    // μ: línea vertical discontinua.
    final mu = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = s * 0.014;
    for (var yy = peak - s * 0.02; yy < y + s * 0.07; yy += s * 0.05) {
      canvas.drawLine(Offset(px(0), yy), Offset(px(0), math.min(yy + s * 0.028, y + s * 0.07)), mu);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AppLogoPainter oldDelegate) => oldDelegate.rounded != rounded;
}
