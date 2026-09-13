import 'dart:math' as math;

/// Distribuciones de probabilidad usadas por la app.
///
/// Todo es Dart puro (sin Flutter) para poder probarlo con `flutter test`
/// sin arrancar la interfaz. Los algoritmos son idénticos a los de
/// `tool/inference_core.py`, que se validó contra SciPy:
///
/// * CDF normal: algoritmo de Hart 5666 (West, 2005), error < 1e-14.
/// * Cuantil normal: Acklam + un paso de Halley, error < 1e-10.
/// * CDF t de Student: beta incompleta regularizada (fracción continua).
/// * Cuantil t: bisección sobre la CDF, error < 1e-11.
class Distributions {
  Distributions._();

  static final double _sqrt2Pi = math.sqrt(2 * math.pi);

  // ------------------------------------------------------------- normal
  static double normalPdf(double x) => math.exp(-0.5 * x * x) / _sqrt2Pi;

  static double normalCdf(double x) {
    final ax = x.abs();
    double c;
    if (ax > 37) {
      c = 0;
    } else {
      final e = math.exp(-ax * ax / 2);
      if (ax < 7.07106781186547) {
        var b = 3.52624965998911e-02 * ax + 0.700383064443688;
        b = b * ax + 6.37396220353165;
        b = b * ax + 33.912866078383;
        b = b * ax + 112.079291497871;
        b = b * ax + 221.213596169931;
        b = b * ax + 220.206867912376;
        c = e * b;
        b = 8.83883476483184e-02 * ax + 1.75566716318264;
        b = b * ax + 16.064177579207;
        b = b * ax + 86.7807322029461;
        b = b * ax + 296.564248779674;
        b = b * ax + 637.333633378831;
        b = b * ax + 793.826512519948;
        b = b * ax + 440.413735824752;
        c = c / b;
      } else {
        var b = ax + 0.65;
        b = ax + 4 / b;
        b = ax + 3 / b;
        b = ax + 2 / b;
        b = ax + 1 / b;
        c = e / b / 2.506628274631;
      }
    }
    return x > 0 ? 1 - c : c;
  }

  static const List<double> _a = [
    -3.969683028665376e+01, 2.209460984245205e+02, -2.759285104469687e+02,
    1.383577518672690e+02, -3.066479806614716e+01, 2.506628277459239e+00,
  ];
  static const List<double> _b = [
    -5.447609879822406e+01, 1.615858368580409e+02, -1.556989798598866e+02,
    6.680131188771972e+01, -1.328068155288572e+01,
  ];
  static const List<double> _c = [
    -7.784894002430293e-03, -3.223964580411365e-01, -2.400758277161838e+00,
    -2.549732539343734e+00, 4.374664141464968e+00, 2.938163982698783e+00,
  ];
  static const List<double> _d = [
    7.784695709041462e-03, 3.224671290700398e-01, 2.445134137142996e+00,
    3.754408661907416e+00,
  ];

  /// Cuantil de la normal estándar: devuelve z tal que P(Z ≤ z) = p.
  static double normalQuantile(double p) {
    if (p <= 0 || p >= 1) {
      throw ArgumentError.value(p, 'p', 'debe estar en (0, 1)');
    }
    const plow = 0.02425;
    double x;
    if (p < plow) {
      final q = math.sqrt(-2 * math.log(p));
      x = (((((_c[0] * q + _c[1]) * q + _c[2]) * q + _c[3]) * q + _c[4]) * q + _c[5]) /
          ((((_d[0] * q + _d[1]) * q + _d[2]) * q + _d[3]) * q + 1);
    } else if (p <= 1 - plow) {
      final q = p - 0.5;
      final r = q * q;
      x = (((((_a[0] * r + _a[1]) * r + _a[2]) * r + _a[3]) * r + _a[4]) * r + _a[5]) * q /
          (((((_b[0] * r + _b[1]) * r + _b[2]) * r + _b[3]) * r + _b[4]) * r + 1);
    } else {
      final q = math.sqrt(-2 * math.log(1 - p));
      x = -(((((_c[0] * q + _c[1]) * q + _c[2]) * q + _c[3]) * q + _c[4]) * q + _c[5]) /
          ((((_d[0] * q + _d[1]) * q + _d[2]) * q + _d[3]) * q + 1);
    }
    // Un paso de Halley para llevar el error a precisión de máquina.
    final e = normalCdf(x) - p;
    final u = e * _sqrt2Pi * math.exp(x * x / 2);
    return x - u / (1 + x * u / 2);
  }

  // ------------------------------------------------------ gamma y beta
  static const List<double> _lanczos = [
    676.5203681218851, -1259.1392167224028, 771.32342877765313,
    -176.61502916214059, 12.507343278686905, -0.13857109526572012,
    9.9843695780195716e-6, 1.5056327351493116e-7,
  ];

  static double logGamma(double x) {
    if (x < 0.5) {
      return math.log(math.pi / math.sin(math.pi * x).abs()) - logGamma(1 - x);
    }
    final y = x - 1;
    var a = 0.99999999999980993;
    final t = y + 7.5;
    for (var i = 0; i < _lanczos.length; i++) {
      a += _lanczos[i] / (y + i + 1);
    }
    return 0.5 * math.log(2 * math.pi) + (y + 0.5) * math.log(t) - t + math.log(a);
  }

  static double _betacf(double a, double b, double x) {
    const tiny = 1e-300;
    final qab = a + b, qap = a + 1, qam = a - 1;
    var c = 1.0;
    var d = 1 - qab * x / qap;
    if (d.abs() < tiny) d = tiny;
    d = 1 / d;
    var h = d;
    for (var m = 1; m <= 300; m++) {
      final m2 = 2 * m;
      var aa = m * (b - m) * x / ((qam + m2) * (a + m2));
      d = 1 + aa * d;
      if (d.abs() < tiny) d = tiny;
      c = 1 + aa / c;
      if (c.abs() < tiny) c = tiny;
      d = 1 / d;
      h *= d * c;
      aa = -(a + m) * (qab + m) * x / ((a + m2) * (qap + m2));
      d = 1 + aa * d;
      if (d.abs() < tiny) d = tiny;
      c = 1 + aa / c;
      if (c.abs() < tiny) c = tiny;
      d = 1 / d;
      final de = d * c;
      h *= de;
      if ((de - 1).abs() < 1e-15) break;
    }
    return h;
  }

  /// Beta incompleta regularizada I_x(a, b).
  static double regIncBeta(double a, double b, double x) {
    if (x <= 0) return 0;
    if (x >= 1) return 1;
    final lbt = logGamma(a + b) - logGamma(a) - logGamma(b) +
        a * math.log(x) + b * math.log(1 - x);
    final bt = math.exp(lbt);
    if (x < (a + 1) / (a + b + 2)) {
      return bt * _betacf(a, b, x) / a;
    }
    return 1 - bt * _betacf(b, a, 1 - x) / b;
  }

  // --------------------------------------------------------- t de Student
  static double tPdf(double t, double df) {
    final lc = logGamma((df + 1) / 2) - logGamma(df / 2) - 0.5 * math.log(df * math.pi);
    return math.exp(lc - (df + 1) / 2 * math.log(1 + t * t / df));
  }

  static double tCdf(double t, double df) {
    final x = df / (df + t * t);
    final tail = 0.5 * regIncBeta(df / 2, 0.5, x);
    return t > 0 ? 1 - tail : tail;
  }

  static final Map<String, double> _tQuantileCache = {};

  /// Cuantil de la t de Student. Se cachea porque los laboratorios piden
  /// el mismo valor crítico cientos de veces por segundo.
  static double tQuantile(double p, double df) {
    if (p <= 0 || p >= 1) {
      throw ArgumentError.value(p, 'p', 'debe estar en (0, 1)');
    }
    final key = '$p|$df';
    final cached = _tQuantileCache[key];
    if (cached != null) return cached;
    var lo = -1.0, hi = 1.0;
    while (tCdf(lo, df) > p) {
      lo *= 2;
    }
    while (tCdf(hi, df) < p) {
      hi *= 2;
    }
    for (var i = 0; i < 200; i++) {
      final mid = (lo + hi) / 2;
      if (tCdf(mid, df) < p) {
        lo = mid;
      } else {
        hi = mid;
      }
      if (hi - lo < 1e-12) break;
    }
    final result = (lo + hi) / 2;
    if (_tQuantileCache.length > 512) _tQuantileCache.clear();
    _tQuantileCache[key] = result;
    return result;
  }

  // ------------------------------------------------------------ binomial
  static double binomialPmf(int k, int n, double p) {
    if (k < 0 || k > n) return 0;
    if (p == 0) return k == 0 ? 1 : 0;
    if (p == 1) return k == n ? 1 : 0;
    final lc = logGamma(n + 1.0) - logGamma(k + 1.0) - logGamma(n - k + 1.0);
    return math.exp(lc + k * math.log(p) + (n - k) * math.log(1 - p));
  }

  /// P(X ≥ k) para X ~ Binomial(n, p).
  static double binomialUpper(int k, int n, double p) {
    var s = 0.0;
    for (var i = k; i <= n; i++) {
      s += binomialPmf(i, n, p);
    }
    return math.min(1.0, s);
  }
}
