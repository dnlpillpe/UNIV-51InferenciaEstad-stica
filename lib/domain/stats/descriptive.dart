import 'dart:math' as math;

/// Estadística descriptiva mínima que necesitan los simuladores.
class Descriptive {
  Descriptive._();

  static double mean(List<double> xs) {
    if (xs.isEmpty) return double.nan;
    var s = 0.0;
    for (final x in xs) {
      s += x;
    }
    return s / xs.length;
  }

  /// Desviación estándar muestral (divide entre n − 1).
  static double sd(List<double> xs) {
    if (xs.length < 2) return double.nan;
    final m = mean(xs);
    var s = 0.0;
    for (final x in xs) {
      s += (x - m) * (x - m);
    }
    return math.sqrt(s / (xs.length - 1));
  }

  /// Desviación estándar poblacional (divide entre N).
  static double populationSd(List<double> xs) {
    if (xs.isEmpty) return double.nan;
    final m = mean(xs);
    var s = 0.0;
    for (final x in xs) {
      s += (x - m) * (x - m);
    }
    return math.sqrt(s / xs.length);
  }

  static double minOf(List<double> xs) => xs.reduce(math.min);
  static double maxOf(List<double> xs) => xs.reduce(math.max);

  /// Cuantil con interpolación lineal (tipo 7, el de R y Excel).
  static double quantile(List<double> xs, double q) {
    final s = [...xs]..sort();
    if (s.isEmpty) return double.nan;
    final h = (s.length - 1) * q;
    final lo = h.floor();
    final hi = h.ceil();
    return s[lo] + (h - lo) * (s[hi] - s[lo]);
  }

  /// Asimetría muestral (coeficiente de Fisher, sin corrección).
  static double skewness(List<double> xs) {
    final m = mean(xs);
    final sdp = populationSd(xs);
    if (sdp == 0) return 0;
    var s = 0.0;
    for (final x in xs) {
      s += math.pow((x - m) / sdp, 3).toDouble();
    }
    return s / xs.length;
  }

  /// Cuenta de observaciones por intervalo de clase [min, max) en `bins` partes.
  static List<int> histogram(List<double> xs, double min, double max, int bins) {
    final counts = List<int>.filled(bins, 0);
    if (max <= min) return counts;
    final w = (max - min) / bins;
    for (final x in xs) {
      if (x < min || x > max) continue;
      var i = ((x - min) / w).floor();
      if (i >= bins) i = bins - 1;
      counts[i]++;
    }
    return counts;
  }
}
