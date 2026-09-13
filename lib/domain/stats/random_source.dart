import 'dart:math' as math;

/// Generador aleatorio con semilla. Toda simulación de la app pasa por aquí,
/// de modo que los tests pueden reproducir exactamente un experimento.
class RandomSource {
  RandomSource([int? seed]) : _r = math.Random(seed);

  final math.Random _r;
  double? _spare;

  double nextDouble() => _r.nextDouble();

  int nextInt(int max) => _r.nextInt(max);

  bool nextBool(double probability) => _r.nextDouble() < probability;

  /// Normal estándar por el método polar de Marsaglia.
  double nextGaussian() {
    final s = _spare;
    if (s != null) {
      _spare = null;
      return s;
    }
    double u, v, q;
    do {
      u = 2 * _r.nextDouble() - 1;
      v = 2 * _r.nextDouble() - 1;
      q = u * u + v * v;
    } while (q >= 1 || q == 0);
    final f = math.sqrt(-2 * math.log(q) / q);
    _spare = v * f;
    return u * f;
  }

  double nextNormal(double mean, double sd) => mean + sd * nextGaussian();

  double nextExponential(double mean) => -mean * math.log(1 - _r.nextDouble());

  /// Baraja una lista en el sitio (Fisher–Yates).
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = _r.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}
