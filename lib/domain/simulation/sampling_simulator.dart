import 'dart:math' as math;

import '../stats/descriptive.dart';
import '../stats/random_source.dart';
import 'population.dart';

/// Resultado acumulado de extraer muchas muestras de una población.
class SamplingRun {
  const SamplingRun({
    required this.n,
    required this.means,
    required this.lastSample,
  });

  final int n;
  final List<double> means;
  final List<double> lastSample;

  int get count => means.length;
  double get meanOfMeans => Descriptive.mean(means);

  /// Error estándar observado: desviación de las medias muestrales.
  double get observedSe => means.length < 2 ? double.nan : Descriptive.populationSd(means);
}

/// Construye la distribución muestral de la media, muestra a muestra.
class SamplingSimulator {
  SamplingSimulator._();

  static List<double> drawMeans(Population p, int n, int count, RandomSource rng) {
    return List<double>.generate(count, (_) => Descriptive.mean(p.sample(n, rng)));
  }

  /// Error estándar teórico σ/√n.
  static double theoreticalSe(Population p, int n) => p.sd / math.sqrt(n);
}
