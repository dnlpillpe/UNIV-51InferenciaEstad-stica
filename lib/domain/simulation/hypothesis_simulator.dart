import 'dart:math' as math;

import '../stats/descriptive.dart';
import '../stats/inference.dart';
import '../stats/random_source.dart';

/// Simulaciones del «mundo donde H0 es cierta» y de estudios repetidos.
class HypothesisSimulator {
  HypothesisSimulator._();

  /// Número de éxitos en `n` ensayos con probabilidad `p0`, repetido `k` veces.
  static List<int> nullSuccesses(double p0, int n, int k, RandomSource rng) {
    return List<int>.generate(k, (_) {
      var s = 0;
      for (var i = 0; i < n; i++) {
        if (rng.nextBool(p0)) s++;
      }
      return s;
    });
  }

  /// p-valor simulado de cola derecha: proporción de simulaciones ≥ observado.
  static double upperTailShare(List<int> sims, int observed) {
    if (sims.isEmpty) return double.nan;
    return sims.where((s) => s >= observed).length / sims.length;
  }

  /// Repite `k` estudios (prueba t de una muestra) con media real `trueMu`.
  /// Devuelve los p-valores; la fracción ≤ α es la tasa de rechazo:
  /// si trueMu == mu0 estima α (error tipo I); si no, estima la potencia.
  static List<double> studyPValues({
    required double mu0,
    required double trueMu,
    required double sigma,
    required int n,
    required Tail tail,
    required int k,
    required RandomSource rng,
  }) {
    return List<double>.generate(k, (_) {
      final xs = List<double>.generate(n, (_) => rng.nextNormal(trueMu, sigma));
      return Inference.testMeanT(Descriptive.mean(xs), Descriptive.sd(xs), n, mu0, tail).pValue;
    });
  }

  static double rejectionRate(List<double> pValues, double alpha) {
    if (pValues.isEmpty) return double.nan;
    return pValues.where((p) => p <= alpha).length / pValues.length;
  }

  /// «El jardín de las comparaciones»: cada familia hace `tests` pruebas
  /// sobre ruido puro (dos grupos de la misma población). Devuelve, por
  /// familia, cuántas pruebas salieron «significativas».
  static List<int> multipleTestingFamilies({
    required int families,
    required int tests,
    required int nPerGroup,
    required double alpha,
    required RandomSource rng,
  }) {
    return List<int>.generate(families, (_) {
      var hits = 0;
      for (var t = 0; t < tests; t++) {
        final a = List<double>.generate(nPerGroup, (_) => rng.nextGaussian());
        final b = List<double>.generate(nPerGroup, (_) => rng.nextGaussian());
        final r = Inference.testDiffMeans(Descriptive.mean(a), Descriptive.sd(a), nPerGroup,
            Descriptive.mean(b), Descriptive.sd(b), nPerGroup, Tail.twoSided);
        if (r.pValue <= alpha) hits++;
      }
      return hits;
    });
  }

  /// Un estudio con muestra enorme y efecto minúsculo.
  static TestResult hugeSampleStudy({
    required double mu0,
    required double trueMu,
    required double sigma,
    required int n,
    required RandomSource rng,
  }) {
    // Con n muy grande se simula la media directamente desde su distribución
    // muestral exacta N(μ, σ/√n); s ≈ σ.
    final m = rng.nextNormal(trueMu, sigma / math.sqrt(n));
    return Inference.testMeanT(m, sigma, n, mu0, Tail.twoSided);
  }
}
