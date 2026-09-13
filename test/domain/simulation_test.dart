import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:inferencia_estadistica/domain/simulation/city_survey.dart';
import 'package:inferencia_estadistica/domain/simulation/hypothesis_simulator.dart';
import 'package:inferencia_estadistica/domain/simulation/interval_simulator.dart';
import 'package:inferencia_estadistica/domain/simulation/permutation_test.dart';
import 'package:inferencia_estadistica/domain/simulation/population.dart';
import 'package:inferencia_estadistica/domain/simulation/sampling_simulator.dart';
import 'package:inferencia_estadistica/domain/stats/descriptive.dart';
import 'package:inferencia_estadistica/domain/stats/inference.dart';
import 'package:inferencia_estadistica/domain/stats/random_source.dart';

/// Las simulaciones deben mostrar lo que las lecciones afirman.
/// Los márgenes de cada prueba son de al menos 4 errores estándar.
void main() {
  test('el generador normal tiene media 0 y desviación 1', () {
    final rng = RandomSource(1);
    final xs = List.generate(20000, (_) => rng.nextGaussian());
    expect(Descriptive.mean(xs), closeTo(0, 0.03));
    expect(Descriptive.sd(xs), closeTo(1, 0.03));
  });

  test('las poblaciones tienen la forma anunciada', () {
    final skew = Population.generate(PopulationShape.skewed);
    final normal = Population.generate(PopulationShape.normal);
    expect(Descriptive.skewness(skew.values), greaterThan(1.3));
    expect(Descriptive.skewness(normal.values).abs(), lessThan(0.2));
    expect(normal.mean, closeTo(165, 0.6));
  });

  test('el error estándar observado se acerca a σ/√n (lab 2, e2_2)', () {
    final pop = Population.generate(PopulationShape.normal);
    final rng = RandomSource(2);
    for (final n in [25, 100]) {
      final means = SamplingSimulator.drawMeans(pop, n, 2000, rng);
      final se = Descriptive.populationSd(means);
      expect(se, closeTo(pop.sd / math.sqrt(n), 0.08 * pop.sd / math.sqrt(n)), reason: 'n = $n');
    }
  });

  test('TLC: medias casi simétricas con n = 30 aunque la población no lo sea (e2_1)', () {
    final pop = Population.generate(PopulationShape.skewed);
    final rng = RandomSource(3);
    final m2 = SamplingSimulator.drawMeans(pop, 2, 3000, rng);
    final m30 = SamplingSimulator.drawMeans(pop, 30, 3000, rng);
    expect(Descriptive.skewness(m2), greaterThan(0.9));
    expect(Descriptive.skewness(m30), lessThan(0.6));
  });

  test('una muestra grande conserva la asimetría de la población (e2_3)', () {
    final pop = Population.generate(PopulationShape.skewed);
    final sample = pop.sample(2000, RandomSource(4));
    expect(Descriptive.skewness(sample), greaterThan(1.2));
  });

  group('Lluvia de intervalos', () {
    double capture(IntervalMethod m, int n, double conf, int seed) {
      final list = IntervalSimulator.many(
          count: 3000, mu: 50, sigma: 10, n: n, conf: conf, method: m, rng: RandomSource(seed));
      return list.where((i) => i.captured).length / list.length;
    }

    test('t con s captura cerca del 95 % (e3_1)', () {
      expect(capture(IntervalMethod.tWithS, 20, 0.95, 5), inInclusiveRange(0.93, 0.97));
    });

    test('el atajo z con s en n = 5 captura cerca del 88 % (e3_3)', () {
      expect(capture(IntervalMethod.zWithS, 5, 0.95, 6), inInclusiveRange(0.85, 0.905));
    });

    test('99 % captura más que 80 % (e3_2)', () {
      expect(capture(IntervalMethod.tWithS, 20, 0.99, 7), greaterThan(capture(IntervalMethod.tWithS, 20, 0.80, 8) + 0.12));
    });
  });

  group('Villa Muestra', () {
    final city = CitySurvey.generate();

    List<double> estimates(SamplingMethod m, int n, int reps, int seed) {
      final rng = RandomSource(seed);
      return List.generate(reps, (_) => city.draw(m, n, rng).estimate);
    }

    test('la conveniencia está sesgada aunque n sea grande (e1_1)', () {
      final conv = estimates(SamplingMethod.convenience, 200, 200, 9);
      final srs = estimates(SamplingMethod.simpleRandom, 25, 400, 10);
      expect(Descriptive.mean(conv) - city.trueProportion, greaterThan(0.15));
      expect((Descriptive.mean(srs) - city.trueProportion).abs(), lessThan(0.03));
      expect(Descriptive.populationSd(conv), lessThan(Descriptive.populationSd(srs)));
    });

    test('el estratificado varía menos que el aleatorio simple (e1_2)', () {
      final strat = estimates(SamplingMethod.stratified, 40, 600, 11);
      final srs = estimates(SamplingMethod.simpleRandom, 40, 600, 12);
      expect(Descriptive.populationSd(strat), lessThan(0.92 * Descriptive.populationSd(srs)));
    });

    test('la respuesta voluntaria sobreestima', () {
      final vol = estimates(SamplingMethod.voluntary, 100, 100, 13);
      expect(Descriptive.mean(vol), greaterThan(city.trueProportion + 0.15));
    });

    test('los métodos entregan el tamaño pedido', () {
      final rng = RandomSource(14);
      for (final m in SamplingMethod.values) {
        final s = city.draw(m, 40, rng);
        expect(s.indices.length, inInclusiveRange(38, 40), reason: m.label);
        expect(s.indices.toSet().length, s.indices.length, reason: 'sin repetidos: ${m.label}');
      }
    });
  });

  group('Mundo de H0', () {
    test('la moneda: 16 o más de 25 ocurre ≈ 11 % (e4_1)', () {
      final sims = HypothesisSimulator.nullSuccesses(0.5, 25, 5000, RandomSource(15));
      expect(HypothesisSimulator.upperTailShare(sims, 16), inInclusiveRange(0.095, 0.135));
    });

    test('con H0 cierta se rechaza ≈ α (e4_2)', () {
      final p = HypothesisSimulator.studyPValues(
          mu0: 0, trueMu: 0, sigma: 1, n: 20, tail: Tail.twoSided, k: 3000, rng: RandomSource(16));
      expect(HypothesisSimulator.rejectionRate(p, 0.05), inInclusiveRange(0.035, 0.065));
    });

    test('potencia ≈ 25 % con efecto 0,3σ y n = 20 (e4_3)', () {
      final p = HypothesisSimulator.studyPValues(
          mu0: 0, trueMu: 0.3, sigma: 1, n: 20, tail: Tail.twoSided, k: 2000, rng: RandomSource(17));
      expect(HypothesisSimulator.rejectionRate(p, 0.05), inInclusiveRange(0.19, 0.32));
    });

    test('20 pruebas sobre ruido: ≈ 64 % encuentra algo (e5_2)', () {
      final fam = HypothesisSimulator.multipleTestingFamilies(
          families: 400, tests: 20, nPerGroup: 15, alpha: 0.05, rng: RandomSource(18));
      final rate = fam.where((h) => h > 0).length / fam.length;
      expect(rate, inInclusiveRange(0.56, 0.72));
    });
  });

  test('prueba por permutación del lab 5 da p ≈ 0,013 (e5_1)', () {
    const a = <double>[15, 13, 17, 14, 16, 12, 15, 18, 14, 13, 16, 15];
    const b = <double>[12, 14, 11, 13, 15, 10, 12, 14, 13, 11, 12, 16];
    final perm = PermutationTest(a, b);
    expect(perm.observed, closeTo(2.0833, 0.001));
    final p = perm.pValue(perm.run(4000, RandomSource(19)));
    expect(p, inInclusiveRange(0.004, 0.026));
  });
}
