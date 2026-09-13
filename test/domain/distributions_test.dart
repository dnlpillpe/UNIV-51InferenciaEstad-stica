import 'package:flutter_test/flutter_test.dart';
import 'package:inferencia_estadistica/domain/stats/distributions.dart';

/// Valores de referencia de tablas estándar y de SciPy.
void main() {
  group('Normal', () {
    test('CDF en puntos conocidos', () {
      expect(Distributions.normalCdf(0), closeTo(0.5, 1e-12));
      expect(Distributions.normalCdf(1.96), closeTo(0.9750021048517795, 1e-10));
      expect(Distributions.normalCdf(-1.645), closeTo(0.04998490553912138, 1e-10));
      expect(Distributions.normalCdf(-8), closeTo(6.22096057427178e-16, 1e-18));
    });

    test('cuantiles críticos', () {
      expect(Distributions.normalQuantile(0.975), closeTo(1.959963984540054, 1e-9));
      expect(Distributions.normalQuantile(0.95), closeTo(1.6448536269514722, 1e-9));
      expect(Distributions.normalQuantile(0.995), closeTo(2.5758293035489004, 1e-9));
      expect(Distributions.normalQuantile(0.001), closeTo(-3.090232306167813, 1e-8));
    });

    test('cuantil y CDF son inversas', () {
      for (final p in [0.0001, 0.02, 0.3, 0.5, 0.77, 0.99, 0.9999]) {
        expect(Distributions.normalCdf(Distributions.normalQuantile(p)), closeTo(p, 1e-12));
      }
    });
  });

  group('t de Student', () {
    test('valores críticos de tabla', () {
      expect(Distributions.tQuantile(0.975, 4), closeTo(2.7764451051977987, 1e-8));
      expect(Distributions.tQuantile(0.975, 9), closeTo(2.2621571627409915, 1e-8));
      expect(Distributions.tQuantile(0.975, 15), closeTo(2.131449545559323, 1e-8));
      expect(Distributions.tQuantile(0.975, 29), closeTo(2.045229642132703, 1e-8));
      expect(Distributions.tQuantile(0.95, 17), closeTo(1.7396067260750672, 1e-8));
    });

    test('CDF con gl no enteros (Welch)', () {
      expect(Distributions.tCdf(2.0, 58.14), closeTo(0.97490, 2e-4));
      expect(Distributions.tCdf(-2.23499, 58.14169), closeTo(0.014635, 2e-5));
    });

    test('se acerca a la normal con muchos gl', () {
      expect(Distributions.tQuantile(0.975, 100000), closeTo(1.96, 1e-3));
    });

    test('simetría', () {
      for (final t in [0.3, 1.1, 2.5]) {
        expect(Distributions.tCdf(t, 7) + Distributions.tCdf(-t, 7), closeTo(1, 1e-12));
      }
    });
  });

  group('Binomial', () {
    test('P(X ≥ 16) con n = 25 y p = 0,5', () {
      expect(Distributions.binomialUpper(16, 25, 0.5), closeTo(0.11476147174835, 1e-10));
    });

    test('las probabilidades suman 1', () {
      var s = 0.0;
      for (var k = 0; k <= 30; k++) {
        s += Distributions.binomialPmf(k, 30, 0.37);
      }
      expect(s, closeTo(1, 1e-10));
    });
  });

  test('logGamma coincide con factoriales', () {
    expect(Distributions.logGamma(6), closeTo(4.787491742782046, 1e-10)); // ln 120
    expect(Distributions.logGamma(0.5), closeTo(0.5723649429247001, 1e-10)); // ln √π
  });
}
