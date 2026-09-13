import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/simulation/interval_simulator.dart';
import '../../domain/simulation/population.dart';
import '../../domain/simulation/sampling_simulator.dart';
import '../../domain/stats/distributions.dart';
import '../../domain/stats/random_source.dart';
import 'chart_kit.dart';
import 'density_painter.dart';
import 'histogram_painter.dart';
import 'interval_rain_painter.dart';

/// Ilustraciones de las lecciones. Todas se generan con el mismo motor que
/// los laboratorios (con semilla fija), no son imágenes estáticas.
class LessonVisual extends StatelessWidget {
  const LessonVisual(this.id, {super.key, this.color});

  final String id;
  final Color? color;

  static const Set<String> known = {
    'population_sample', 'bias_variance', 'three_distributions', 'se_sqrt_n', 'clt_shapes',
    'normal_95', 'ci_rain_mini', 't_vs_z', 'p_value_tail', 'errors_matrix', 'power_curves',
    'decision_tree', 'two_groups', 'effect_vs_n',
  };

  @override
  Widget build(BuildContext context) {
    final pal = ChartPalette.of(context);
    final c = color ?? AppColors.indigo;
    Widget paint(CustomPainter p, {double h = 170}) =>
        SizedBox(height: h, width: double.infinity, child: CustomPaint(painter: p));

    switch (id) {
      case 'population_sample':
        return paint(_PopulationSamplePainter(pal, c), h: 180);
      case 'bias_variance':
        return paint(_TargetsPainter(pal), h: 190);
      case 'three_distributions':
        return _ThreeDistributions(pal: pal);
      case 'se_sqrt_n':
        return paint(_TwoNormalsPainter(pal), h: 160);
      case 'clt_shapes':
        return _CltShapes(pal: pal);
      case 'normal_95':
        return paint(DensityPainter(
          palette: pal,
          regions: [
            ShadeRegion(-1.96, 1.96, pal.confidence.withValues(alpha: 0.55), label: '95 %'),
            ShadeRegion(-4, -1.96, pal.reject.withValues(alpha: 0.5)),
            ShadeRegion(1.96, 4, pal.reject.withValues(alpha: 0.5)),
          ],
          criticals: const [-1.96, 1.96],
        ));
      case 'ci_rain_mini':
        return paint(_miniRain(pal), h: 170);
      case 't_vs_z':
        return Column(children: [
          paint(DensityPainter(palette: pal, df: 4, compareNormal: true, lineColor: c)),
          _Legend(items: [(c, 't con 4 gl'), (pal.muted, 'Normal estándar')]),
        ]);
      case 'p_value_tail':
        return paint(DensityPainter(
          palette: pal,
          regions: [ShadeRegion(2.1, 4, pal.reject.withValues(alpha: 0.7), label: 'p')],
          observed: 2.1,
          observedLabel: 'observado',
        ));
      case 'errors_matrix':
        return const _ErrorsMatrix();
      case 'power_curves':
        return Column(children: [
          paint(_PowerPainter(pal), h: 170),
          _Legend(items: [(pal.reject, 'α (error tipo I)'), (pal.muted, 'β (error tipo II)'), (pal.accept, 'Potencia')]),
        ]);
      case 'decision_tree':
        return const _DecisionTree();
      case 'two_groups':
        return paint(_DiffIntervalsPainter(pal), h: 150);
      case 'effect_vs_n':
        return paint(_EffectVsNPainter(pal), h: 170);
    }
    return const SizedBox.shrink();
  }

  IntervalRainPainter _miniRain(ChartPalette pal) {
    final rng = RandomSource(11);
    final list = IntervalSimulator.many(
      count: 20, mu: 50, sigma: 10, n: 25, conf: 0.95, method: IntervalMethod.tWithS, rng: rng);
    return IntervalRainPainter(intervals: list, mu: 50, xMin: 40, xMax: 60, palette: pal, maxRows: 20);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items});
  final List<(Color, String)> items;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      alignment: WrapAlignment.center,
      children: [
        for (final (c, t) in items)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 5),
            Text(t, style: Theme.of(context).textTheme.labelSmall),
          ]),
      ],
    );
  }
}

class _PopulationSamplePainter extends CustomPainter {
  _PopulationSamplePainter(this.pal, this.color);
  final ChartPalette pal;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(4);
    final popC = Offset(size.width * 0.3, size.height * 0.5);
    final popR = size.height * 0.40;
    final sampleC = Offset(size.width * 0.8, size.height * 0.5);
    final sampleR = size.height * 0.22;
    canvas.drawCircle(popC, popR, Paint()..color = pal.population.withValues(alpha: 0.12));
    canvas.drawCircle(sampleC, sampleR, Paint()..color = color.withValues(alpha: 0.14));
    final picked = <Offset>[];
    for (var i = 0; i < 170; i++) {
      final a = rng.nextDouble() * 2 * math.pi;
      final r = popR * 0.92 * math.sqrt(rng.nextDouble());
      final p = popC + Offset(math.cos(a) * r, math.sin(a) * r);
      final chosen = i % 14 == 0;
      if (chosen) picked.add(p);
      canvas.drawCircle(p, chosen ? 3.4 : 2.2, Paint()..color = chosen ? color : pal.population.withValues(alpha: 0.7));
    }
    for (var i = 0; i < picked.length; i++) {
      final a = i / picked.length * 2 * math.pi;
      canvas.drawCircle(sampleC + Offset(math.cos(a), math.sin(a)) * sampleR * 0.55, 3.4, Paint()..color = color);
    }
    drawLabel(canvas, 'Población · μ, σ, p', Offset(popC.dx, size.height - 14), color: pal.ink, weight: FontWeight.w700);
    drawLabel(canvas, 'Muestra · x̄, s, p̂', Offset(sampleC.dx, size.height - 14), color: color, weight: FontWeight.w700);
    // Flechas: selección (arriba) e inferencia (abajo).
    final top = Paint()..color = pal.muted..strokeWidth = 1.6;
    final a1 = Offset(popC.dx + popR + 6, size.height * 0.36);
    final b1 = Offset(sampleC.dx - sampleR - 6, size.height * 0.36);
    canvas.drawLine(a1, b1, top);
    canvas.drawPath(Path()..moveTo(b1.dx, b1.dy)..lineTo(b1.dx - 7, b1.dy - 4)..lineTo(b1.dx - 7, b1.dy + 4)..close(), Paint()..color = pal.muted);
    drawLabel(canvas, 'se elige al azar', Offset((a1.dx + b1.dx) / 2, a1.dy - 16), color: pal.muted, fontSize: 10);
    final inf = Paint()..color = pal.confidence..strokeWidth = 2.4;
    final a2 = Offset(sampleC.dx - sampleR - 6, size.height * 0.64);
    final b2 = Offset(popC.dx + popR + 6, size.height * 0.64);
    drawDashedLine(canvas, a2, b2, inf);
    canvas.drawPath(Path()..moveTo(b2.dx, b2.dy)..lineTo(b2.dx + 8, b2.dy - 5)..lineTo(b2.dx + 8, b2.dy + 5)..close(), Paint()..color = pal.confidence);
    drawLabel(canvas, 'inferencia', Offset((a2.dx + b2.dx) / 2, a2.dy + 4), color: pal.estimate, fontSize: 11, weight: FontWeight.w800);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TargetsPainter extends CustomPainter {
  _TargetsPainter(this.pal);
  final ChartPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final specs = [
      ('Sin sesgo · poca variabilidad', 0.0, 0.0, 0.12),
      ('Sin sesgo · mucha variabilidad', 0.0, 0.0, 0.42),
      ('Con sesgo · poca variabilidad', 0.45, -0.35, 0.12),
      ('Con sesgo · mucha variabilidad', 0.4, -0.3, 0.42),
    ];
    final cellW = size.width / 4;
    final r = math.min(cellW * 0.40, (size.height - 34) / 2);
    for (var i = 0; i < 4; i++) {
      final (label, bx, by, spread) = specs[i];
      final c = Offset(cellW * (i + 0.5), r + 6);
      for (var k = 3; k >= 1; k--) {
        canvas.drawCircle(c, r * k / 3, Paint()..color = (k.isOdd ? pal.reject : pal.surface).withValues(alpha: k.isOdd ? 0.16 : 1));
        canvas.drawCircle(c, r * k / 3, Paint()..color = pal.muted.withValues(alpha: 0.4)..style = PaintingStyle.stroke);
      }
      canvas.drawCircle(c, 3, Paint()..color = pal.parameter);
      final rng = math.Random(20 + i);
      for (var j = 0; j < 12; j++) {
        final dx = (bx + spread * (rng.nextDouble() * 2 - 1)) * r;
        final dy = (by + spread * (rng.nextDouble() * 2 - 1)) * r;
        canvas.drawCircle(c + Offset(dx, dy), 3, Paint()..color = pal.sampling);
      }
      final words = label.split(' · ');
      drawLabel(canvas, words[0], Offset(c.dx, 2 * r + 12), color: pal.ink, fontSize: 9.5, weight: FontWeight.w700);
      drawLabel(canvas, words[1], Offset(c.dx, 2 * r + 24), color: pal.muted, fontSize: 9.5);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ThreeDistributions extends StatelessWidget {
  const _ThreeDistributions({required this.pal});
  final ChartPalette pal;

  @override
  Widget build(BuildContext context) {
    final pop = Population.generate(PopulationShape.skewed, size: 3000, seed: 5);
    final rng = RandomSource(9);
    final sample = pop.sample(40, rng);
    final means = SamplingSimulator.drawMeans(pop, 40, 800, rng);
    const max = 26.0;
    Widget panel(String title, List<double> v, Color c, {int bins = 26}) => Expanded(
          child: Column(children: [
            Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            SizedBox(
              height: 110,
              child: CustomPaint(
                painter: HistogramPainter(values: v, min: 0, max: max, bins: bins, color: c, palette: pal, showAxis: true),
              ),
            ),
          ]),
        );
    return Row(children: [
      panel('Población', pop.values, pal.population),
      panel('Una muestra (n = 40)', sample, pal.sample, bins: 13),
      panel('Medias de 800 muestras', means, pal.sampling, bins: 52),
    ]);
  }
}

class _CltShapes extends StatelessWidget {
  const _CltShapes({required this.pal});
  final ChartPalette pal;

  @override
  Widget build(BuildContext context) {
    final pop = Population.generate(PopulationShape.skewed, size: 3000, seed: 5);
    final rng = RandomSource(3);
    final m2 = SamplingSimulator.drawMeans(pop, 2, 1500, rng);
    final m30 = SamplingSimulator.drawMeans(pop, 30, 1500, rng);
    Widget panel(String title, List<double> v, Color c, int bins) => Expanded(
          child: Column(children: [
            Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
            SizedBox(
              height: 110,
              child: CustomPaint(
                painter: HistogramPainter(values: v, min: 0, max: 20, bins: bins, color: c, palette: pal),
              ),
            ),
          ]),
        );
    return Row(children: [
      panel('Población', pop.values, pal.population, 24),
      panel('Medias, n = 2', m2, pal.sampling, 30),
      panel('Medias, n = 30', m30, pal.sampling, 48),
    ]);
  }
}

class _TwoNormalsPainter extends CustomPainter {
  _TwoNormalsPainter(this.pal);
  final ChartPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final f = ChartFrame(size, xMin: 92, xMax: 108, yMax: 0.42, top: 16);
    void curve(double se, Color c, String label) {
      final path = Path();
      for (var i = 0; i <= 120; i++) {
        final x = 92 + 16 * i / 120;
        final y = Distributions.normalPdf((x - 100) / se) / se;
        final p = Offset(f.x(x), f.y(y));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, Paint()..color = c..strokeWidth = 2.4..style = PaintingStyle.stroke);
      final peak = Distributions.normalPdf(0) / se;
      drawLabel(canvas, label, Offset(f.x(100) + 8, f.y(peak) - 2), color: c, weight: FontWeight.w800, align: TextAlign.left);
    }
    curve(2, pal.sample, 'n = 36 · EE = 2');
    curve(1, pal.sampling, 'n = 144 · EE = 1');
    drawXAxis(canvas, f, pal);
    drawMarker(canvas, f, ChartMarker(100, pal.parameter, dashed: true));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PowerPainter extends CustomPainter {
  _PowerPainter(this.pal);
  final ChartPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    const shift = 2.5;
    final f = ChartFrame(size, xMin: -3.5, xMax: 6, yMax: 0.44, top: 18);
    const crit = 1.645;
    void area(double a, double b, double mu, Color c) {
      final path = Path()..moveTo(f.x(a), f.y(0));
      for (var i = 0; i <= 60; i++) {
        final x = a + (b - a) * i / 60;
        path.lineTo(f.x(x), f.y(Distributions.normalPdf(x - mu)));
      }
      path
        ..lineTo(f.x(b), f.y(0))
        ..close();
      canvas.drawPath(path, Paint()..color = c);
    }
    area(crit, 6, shift, pal.accept.withValues(alpha: 0.35));
    area(-3.5, crit, shift, pal.muted.withValues(alpha: 0.25));
    area(crit, 6, 0, pal.reject.withValues(alpha: 0.7));
    void curve(double mu, Color c) {
      final path = Path();
      for (var i = 0; i <= 150; i++) {
        final x = -3.5 + 9.5 * i / 150;
        final p = Offset(f.x(x), f.y(Distributions.normalPdf(x - mu)));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(path, Paint()..color = c..strokeWidth = 2..style = PaintingStyle.stroke);
    }
    curve(0, pal.ink);
    curve(shift, pal.sampling);
    drawLabel(canvas, 'Si H0 es cierta', Offset(f.x(-1.2), f.y(0.41)), color: pal.ink, fontSize: 10, weight: FontWeight.w700);
    drawLabel(canvas, 'Si hay efecto', Offset(f.x(3.8), f.y(0.41)), color: pal.sampling, fontSize: 10, weight: FontWeight.w700);
    final px = f.x(crit);
    drawDashedLine(canvas, Offset(px, f.plot.top), Offset(px, f.plot.bottom), Paint()..color = pal.ink..strokeWidth = 1.2);
    drawLabel(canvas, 'valor crítico', Offset(px, f.plot.bottom + 6), color: pal.muted, fontSize: 9.5);
    canvas.drawLine(Offset(f.plot.left, f.plot.bottom), Offset(f.plot.right, f.plot.bottom), Paint()..color = pal.muted);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DiffIntervalsPainter extends CustomPainter {
  _DiffIntervalsPainter(this.pal);
  final ChartPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final f = ChartFrame(size, xMin: -3, xMax: 6, yMax: 1, top: 16);
    final rows = [
      ('Contiene el 0: sin evidencia de diferencia', -1.2, 3.6, pal.muted),
      ('Excluye el 0: hay evidencia de diferencia', 0.6, 4.8, pal.confidence),
    ];
    for (var i = 0; i < rows.length; i++) {
      final (label, a, b, c) = rows[i];
      final y = f.plot.top + (i + 0.55) * f.plot.height / 2;
      canvas.drawLine(Offset(f.x(a), y), Offset(f.x(b), y), Paint()..color = c..strokeWidth = 5..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(f.x((a + b) / 2), y), 5, Paint()..color = pal.ink);
      drawLabel(canvas, label, Offset(f.x(a), y - 22), color: pal.ink, fontSize: 10.5, weight: FontWeight.w600, align: TextAlign.left);
    }
    drawXAxis(canvas, f, pal);
    drawMarker(canvas, f, ChartMarker(0, pal.reject, label: '0', dashed: true));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EffectVsNPainter extends CustomPainter {
  _EffectVsNPainter(this.pal);
  final ChartPalette pal;

  @override
  void paint(Canvas canvas, Size size) {
    final f = ChartFrame(size, xMin: -0.4, xMax: 0.4, yMax: 1, top: 16, left: 70);
    // Mismo efecto (0,02 s), desviación 0,9 s: el IC se estrecha con √n.
    final rows = [(500, '500'), (5000, '5 000'), (50000, '50 000')];
    for (var i = 0; i < rows.length; i++) {
      final (n, label) = rows[i];
      final se = 0.9 * math.sqrt(2 / n);
      final a = 0.02 - 1.96 * se, b = 0.02 + 1.96 * se;
      final y = f.plot.top + (i + 0.5) * f.plot.height / 3;
      final excludes = a > 0;
      canvas.drawLine(Offset(f.x(a), y), Offset(f.x(b), y),
          Paint()
            ..color = (excludes ? pal.reject : pal.muted)
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round);
      canvas.drawCircle(Offset(f.x(0.02), y), 4.5, Paint()..color = pal.ink);
      drawLabel(canvas, 'n = $label', Offset(f.plot.left - 8, y - 7), color: pal.ink, fontSize: 10.5, weight: FontWeight.w700, align: TextAlign.right);
    }
    drawXAxis(canvas, f, pal);
    drawMarker(canvas, f, ChartMarker(0, pal.parameter, label: 'efecto 0', dashed: true));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ErrorsMatrix extends StatelessWidget {
  const _ErrorsMatrix();

  @override
  Widget build(BuildContext context) {
    final pal = ChartPalette.of(context);
    final t = Theme.of(context).textTheme;
    Widget cell(String title, String sub, Color c) => Expanded(
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(10),
            height: 74,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(title, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800, color: c), textAlign: TextAlign.center),
              Text(sub, style: t.labelSmall, textAlign: TextAlign.center),
            ]),
          ),
        );
    Widget head(String s) => Expanded(
        child: Text(s, textAlign: TextAlign.center, style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700)));
    return Column(children: [
      Row(children: [const SizedBox(width: 84), head('H0 es cierta'), head('H0 es falsa')]),
      Row(children: [
        SizedBox(width: 84, child: Text('Rechazo H0', style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700))),
        cell('Error tipo I', 'probabilidad α', pal.reject),
        cell('Acierto', 'potencia 1 − β', pal.accept),
      ]),
      Row(children: [
        SizedBox(width: 84, child: Text('No rechazo H0', style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700))),
        cell('Acierto', 'probabilidad 1 − α', pal.accept),
        cell('Error tipo II', 'probabilidad β', pal.muted),
      ]),
    ]);
  }
}

class _DecisionTree extends StatelessWidget {
  const _DecisionTree();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget box(String s, Color c) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.5))),
          child: Text(s, style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        );
    Widget arrow() => const Padding(padding: EdgeInsets.symmetric(vertical: 2), child: Icon(Icons.south_rounded, size: 16));
    return Column(children: [
      box('¿Variable numérica o sí/no?', AppColors.indigo),
      arrow(),
      Row(children: [
        Expanded(child: Column(children: [
          box('Numérica → medias', AppColors.m1),
          arrow(),
          box('1 grupo: t de una media\n2 grupos: Welch\nMismos sujetos: pareada', AppColors.m1),
        ])),
        const SizedBox(width: 8),
        Expanded(child: Column(children: [
          box('Sí/no → proporciones', AppColors.m3),
          arrow(),
          box('1 grupo: z de una proporción\n2 grupos: dos proporciones', AppColors.m3),
        ])),
      ]),
      arrow(),
      box('¿Rango de valores? → intervalo   ·   ¿Decisión frente a un umbral? → prueba', AppColors.m5),
    ]);
  }
}
