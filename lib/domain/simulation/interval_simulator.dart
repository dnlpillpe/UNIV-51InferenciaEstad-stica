import 'dart:math' as math;

import '../stats/descriptive.dart';
import '../stats/inference.dart';
import '../stats/random_source.dart';

/// Cómo se construye cada intervalo en la Lluvia de intervalos.
enum IntervalMethod {
  zKnownSigma('z con σ conocida', 'x̄ ± z·σ/√n'),
  tWithS('t con s', 'x̄ ± t·s/√n'),
  zWithS('z con s (atajo)', 'x̄ ± z·s/√n');

  const IntervalMethod(this.label, this.formula);
  final String label;
  final String formula;
}

class SimulatedInterval {
  const SimulatedInterval({
    required this.estimate,
    required this.lower,
    required this.upper,
    required this.captured,
  });

  final double estimate;
  final double lower;
  final double upper;
  final bool captured;
}

/// Genera intervalos a partir de una población normal N(μ, σ) conocida por la
/// app y desconocida para el «investigador» que construye cada intervalo.
class IntervalSimulator {
  IntervalSimulator._();

  static SimulatedInterval one({
    required double mu,
    required double sigma,
    required int n,
    required double conf,
    required IntervalMethod method,
    required RandomSource rng,
  }) {
    final xs = List<double>.generate(n, (_) => rng.nextNormal(mu, sigma));
    final m = Descriptive.mean(xs);
    final s = Descriptive.sd(xs);
    double half;
    switch (method) {
      case IntervalMethod.zKnownSigma:
        half = Inference.zCritical(conf) * sigma / math.sqrt(n);
      case IntervalMethod.tWithS:
        half = Inference.tCritical(conf, (n - 1).toDouble()) * s / math.sqrt(n);
      case IntervalMethod.zWithS:
        half = Inference.zCritical(conf) * s / math.sqrt(n);
    }
    return SimulatedInterval(
      estimate: m,
      lower: m - half,
      upper: m + half,
      captured: (m - half) <= mu && mu <= (m + half),
    );
  }

  static List<SimulatedInterval> many({
    required int count,
    required double mu,
    required double sigma,
    required int n,
    required double conf,
    required IntervalMethod method,
    required RandomSource rng,
  }) =>
      List.generate(
        count,
        (_) => one(mu: mu, sigma: sigma, n: n, conf: conf, method: method, rng: rng),
      );
}
