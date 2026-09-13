import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Fondo de cabecera con el motivo de la app: curvas normales tenues y
/// puntos muestrales sobre un degradado del color indicado.
class CurveBackdrop extends StatelessWidget {
  const CurveBackdrop({super.key, required this.child, this.color, this.padding});

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.indigo;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(c, Colors.white, 0.08)!, c, Color.lerp(c, Colors.black, 0.35)!],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CustomPaint(
          painter: _CurvesPainter(),
          child: Padding(padding: padding ?? const EdgeInsets.all(20), child: child),
        ),
      ),
    );
  }
}

class _CurvesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final specs = [
      (0.72, 0.95, 0.55, 0.16),
      (0.88, 0.85, 0.35, 0.10),
      (0.55, 1.05, 0.65, 0.22),
    ];
    for (final (cx, base, h, w) in specs) {
      final p = Path();
      for (var i = 0; i <= 80; i++) {
        final z = -3 + 6 * i / 80;
        final x = size.width * (cx + z * w / 3);
        final y = size.height * (base - h * math.exp(-0.5 * z * z));
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      canvas.drawPath(p, stroke);
    }
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.14);
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final x = size.width * (0.45 + 0.55 * rnd.nextDouble());
      final y = size.height * (0.1 + 0.5 * rnd.nextDouble());
      canvas.drawCircle(Offset(x, y), 1.5 + rnd.nextDouble() * 1.8, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
