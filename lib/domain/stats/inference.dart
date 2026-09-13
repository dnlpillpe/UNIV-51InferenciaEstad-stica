import 'dart:math' as math;

import 'distributions.dart';

/// Dirección de la hipótesis alternativa.
enum Tail {
  twoSided('two', '≠', 'Bilateral'),
  less('less', '<', 'Cola izquierda'),
  greater('greater', '>', 'Cola derecha');

  const Tail(this.code, this.symbol, this.label);
  final String code;
  final String symbol;
  final String label;

  static Tail fromCode(String code) =>
      Tail.values.firstWhere((t) => t.code == code, orElse: () => Tail.twoSided);
}

/// Distribución de referencia del estadístico.
enum RefDistribution { z, t }

/// Resultado de un intervalo de confianza.
class ConfidenceInterval {
  const ConfidenceInterval({
    required this.estimate,
    required this.se,
    required this.critical,
    required this.level,
    required this.distribution,
    this.df,
  });

  final double estimate;
  final double se;
  final double critical;
  final double level;
  final RefDistribution distribution;
  final double? df;

  double get margin => critical * se;
  double get lower => estimate - margin;
  double get upper => estimate + margin;
  double get width => 2 * margin;

  bool contains(double value) => value >= lower && value <= upper;

  Map<String, double> toMap() => {
        'estimate': estimate,
        'se': se,
        'critical': critical,
        'margin': margin,
        'lower': lower,
        'upper': upper,
        if (df != null) 'df': df!,
      };
}

/// Resultado de una prueba de hipótesis.
class TestResult {
  const TestResult({
    required this.estimate,
    required this.se,
    required this.statistic,
    required this.pValue,
    required this.tail,
    required this.distribution,
    this.df,
    this.pooled,
  });

  final double estimate;
  final double se;
  final double statistic;
  final double pValue;
  final Tail tail;
  final RefDistribution distribution;
  final double? df;
  final double? pooled;

  bool rejectAt(double alpha) => pValue <= alpha;

  /// Valor crítico (en la escala del estadístico) para un α dado.
  double criticalValue(double alpha) {
    final q = tail == Tail.twoSided ? 1 - alpha / 2 : 1 - alpha;
    final c = distribution == RefDistribution.t
        ? Distributions.tQuantile(q, df!)
        : Distributions.normalQuantile(q);
    return tail == Tail.less ? -c : c;
  }

  Map<String, double> toMap() => {
        'estimate': estimate,
        'se': se,
        'statistic': statistic,
        'p': pValue,
        if (df != null) 'df': df!,
        if (pooled != null) 'pooled': pooled!,
      };
}

/// Procedimientos de inferencia de una y dos muestras.
///
/// Convención: `conf` y `alpha` en proporción (0,95; 0,05), nunca en %.
class Inference {
  Inference._();

  static double zCritical(double conf) => Distributions.normalQuantile(1 - (1 - conf) / 2);

  static double tCritical(double conf, double df) =>
      Distributions.tQuantile(1 - (1 - conf) / 2, df);

  static double pValue(double stat, Tail tail, double Function(double) cdf) {
    switch (tail) {
      case Tail.twoSided:
        final c = cdf(stat);
        return math.min(1.0, 2 * math.min(c, 1 - c));
      case Tail.less:
        return cdf(stat);
      case Tail.greater:
        return 1 - cdf(stat);
    }
  }

  static double welchDf(double s1, int n1, double s2, int n2) {
    final v1 = s1 * s1 / n1, v2 = s2 * s2 / n2;
    return (v1 + v2) * (v1 + v2) / (v1 * v1 / (n1 - 1) + v2 * v2 / (n2 - 1));
  }

  // --------------------------------------------------------- intervalos
  static ConfidenceInterval ciMeanZ(double mean, double sigma, int n, double conf) =>
      ConfidenceInterval(
        estimate: mean,
        se: sigma / math.sqrt(n),
        critical: zCritical(conf),
        level: conf,
        distribution: RefDistribution.z,
      );

  static ConfidenceInterval ciMeanT(double mean, double sd, int n, double conf) =>
      ConfidenceInterval(
        estimate: mean,
        se: sd / math.sqrt(n),
        critical: tCritical(conf, (n - 1).toDouble()),
        level: conf,
        distribution: RefDistribution.t,
        df: (n - 1).toDouble(),
      );

  static ConfidenceInterval ciProportion(int x, int n, double conf) {
    final p = x / n;
    return ConfidenceInterval(
      estimate: p,
      se: math.sqrt(p * (1 - p) / n),
      critical: zCritical(conf),
      level: conf,
      distribution: RefDistribution.z,
    );
  }

  static ConfidenceInterval ciDiffMeans(
      double m1, double s1, int n1, double m2, double s2, int n2, double conf) {
    final df = welchDf(s1, n1, s2, n2);
    return ConfidenceInterval(
      estimate: m1 - m2,
      se: math.sqrt(s1 * s1 / n1 + s2 * s2 / n2),
      critical: tCritical(conf, df),
      level: conf,
      distribution: RefDistribution.t,
      df: df,
    );
  }

  static ConfidenceInterval ciDiffProportions(int x1, int n1, int x2, int n2, double conf) {
    final p1 = x1 / n1, p2 = x2 / n2;
    return ConfidenceInterval(
      estimate: p1 - p2,
      se: math.sqrt(p1 * (1 - p1) / n1 + p2 * (1 - p2) / n2),
      critical: zCritical(conf),
      level: conf,
      distribution: RefDistribution.z,
    );
  }

  // ------------------------------------------------------------- pruebas
  static TestResult testMeanZ(double mean, double sigma, int n, double mu0, Tail tail) {
    final se = sigma / math.sqrt(n);
    final z = (mean - mu0) / se;
    return TestResult(
      estimate: mean,
      se: se,
      statistic: z,
      pValue: pValue(z, tail, Distributions.normalCdf),
      tail: tail,
      distribution: RefDistribution.z,
    );
  }

  static TestResult testMeanT(double mean, double sd, int n, double mu0, Tail tail) {
    final se = sd / math.sqrt(n);
    final t = (mean - mu0) / se;
    final df = (n - 1).toDouble();
    return TestResult(
      estimate: mean,
      se: se,
      statistic: t,
      pValue: pValue(t, tail, (v) => Distributions.tCdf(v, df)),
      tail: tail,
      distribution: RefDistribution.t,
      df: df,
    );
  }

  static TestResult testProportion(int x, int n, double p0, Tail tail) {
    final ph = x / n;
    final se = math.sqrt(p0 * (1 - p0) / n);
    final z = (ph - p0) / se;
    return TestResult(
      estimate: ph,
      se: se,
      statistic: z,
      pValue: pValue(z, tail, Distributions.normalCdf),
      tail: tail,
      distribution: RefDistribution.z,
    );
  }

  static TestResult testDiffMeans(
      double m1, double s1, int n1, double m2, double s2, int n2, Tail tail) {
    final se = math.sqrt(s1 * s1 / n1 + s2 * s2 / n2);
    final df = welchDf(s1, n1, s2, n2);
    final t = (m1 - m2) / se;
    return TestResult(
      estimate: m1 - m2,
      se: se,
      statistic: t,
      pValue: pValue(t, tail, (v) => Distributions.tCdf(v, df)),
      tail: tail,
      distribution: RefDistribution.t,
      df: df,
    );
  }

  static TestResult testDiffProportions(int x1, int n1, int x2, int n2, Tail tail) {
    final p1 = x1 / n1, p2 = x2 / n2;
    final pp = (x1 + x2) / (n1 + n2);
    final se = math.sqrt(pp * (1 - pp) * (1 / n1 + 1 / n2));
    final z = (p1 - p2) / se;
    return TestResult(
      estimate: p1 - p2,
      se: se,
      statistic: z,
      pValue: pValue(z, tail, Distributions.normalCdf),
      tail: tail,
      distribution: RefDistribution.z,
      pooled: pp,
    );
  }

  // ------------------------------------------------------ tamaño de muestra
  static int sampleSizeMean(double sigma, double e, double conf) {
    final v = math.pow(zCritical(conf) * sigma / e, 2).toDouble();
    return (v - 1e-9).ceil();
  }

  static int sampleSizeProportion(double p, double e, double conf) {
    final z = zCritical(conf);
    return (z * z * p * (1 - p) / (e * e) - 1e-9).ceil();
  }

  // ---------------------------------------------------------- complementos
  static double cohenD(double m1, double s1, int n1, double m2, double s2, int n2) {
    final sp = math.sqrt(((n1 - 1) * s1 * s1 + (n2 - 1) * s2 * s2) / (n1 + n2 - 2));
    return (m1 - m2) / sp;
  }

  /// Potencia teórica de la prueba z para la media.
  static double powerMeanZ(
      double mu0, double mu1, double sigma, int n, double alpha, Tail tail) {
    final se = sigma / math.sqrt(n);
    final shift = (mu1 - mu0) / se;
    switch (tail) {
      case Tail.greater:
        final z = Distributions.normalQuantile(1 - alpha);
        return 1 - Distributions.normalCdf(z - shift);
      case Tail.less:
        final z = Distributions.normalQuantile(1 - alpha);
        return Distributions.normalCdf(-z - shift);
      case Tail.twoSided:
        final z = Distributions.normalQuantile(1 - alpha / 2);
        return 1 - Distributions.normalCdf(z - shift) + Distributions.normalCdf(-z - shift);
    }
  }

  /// Probabilidad de al menos un falso positivo en k pruebas independientes.
  static double familyWiseError(int k, double alpha) =>
      1 - math.pow(1 - alpha, k).toDouble();
}
