import 'package:flutter_test/flutter_test.dart';
import 'package:inferencia_estadistica/domain/engine/procedures.dart';
import 'package:inferencia_estadistica/domain/stats/inference.dart';
import 'package:inferencia_estadistica/domain/stats/inference_registry.dart';

void main() {
  group('Intervalos', () {
    test('media con σ conocida (lección m3_l1)', () {
      final ci = Inference.ciMeanZ(24.6, 6, 36, 0.95);
      expect(ci.se, closeTo(1, 1e-12));
      expect(ci.lower, closeTo(22.64, 0.005));
      expect(ci.upper, closeTo(26.56, 0.005));
      expect(ci.contains(24.6), isTrue);
    });

    test('media con t: el intervalo es más ancho que con z', () {
      final t = Inference.ciMeanT(52, 8, 10, 0.95);
      final z = Inference.ciMeanZ(52, 8, 10, 0.95);
      expect(t.critical, closeTo(2.262, 0.001));
      expect(t.width, greaterThan(z.width));
      expect(t.df, 9);
    });

    test('proporción (lección m3_l4)', () {
      final ci = Inference.ciProportion(210, 500, 0.95);
      expect(ci.lower, closeTo(0.377, 0.001));
      expect(ci.upper, closeTo(0.463, 0.001));
    });

    test('más confianza, más ancho', () {
      final w90 = Inference.ciMeanT(10, 2, 25, 0.90).width;
      final w95 = Inference.ciMeanT(10, 2, 25, 0.95).width;
      final w99 = Inference.ciMeanT(10, 2, 25, 0.99).width;
      expect(w90 < w95 && w95 < w99, isTrue);
    });

    test('diferencia de medias de Welch (caso de Psicología)', () {
      final ci = Inference.ciDiffMeans(38.4, 9.1, 32, 43.9, 10.2, 30, 0.95);
      expect(ci.df, closeTo(58.14, 0.01));
      expect(ci.lower, closeTo(-10.43, 0.01));
      expect(ci.upper, closeTo(-0.57, 0.01));
    });
  });

  group('Pruebas', () {
    test('t unilateral (caso de Minas)', () {
      final r = Inference.testMeanT(0.86, 0.11, 18, 0.80, Tail.greater);
      expect(r.statistic, closeTo(2.314, 0.001));
      expect(r.pValue, closeTo(0.0167, 0.0002));
      expect(r.rejectAt(0.05), isTrue);
      expect(r.rejectAt(0.01), isFalse);
    });

    test('bilateral duplica la cola', () {
      final one = Inference.testMeanZ(2.1, 1, 1, 0, Tail.greater).pValue;
      final two = Inference.testMeanZ(2.1, 1, 1, 0, Tail.twoSided).pValue;
      expect(two, closeTo(2 * one, 1e-12));
      expect(two, closeTo(0.0357, 0.0001));
    });

    test('la cola izquierda con estadístico positivo da p grande', () {
      final r = Inference.testMeanT(51, 4, 16, 50, Tail.less);
      expect(r.pValue, greaterThan(0.5));
    });

    test('proporción con error estándar bajo H0 (caso de Contabilidad)', () {
      final r = Inference.testProportion(16, 200, 0.05, Tail.greater);
      expect(r.se, closeTo(0.01541, 0.00001));
      expect(r.pValue, closeTo(0.0258, 0.0002));
    });

    test('dos proporciones con proporción combinada (caso de Sistemas)', () {
      final r = Inference.testDiffProportions(296, 4000, 248, 4000, Tail.twoSided);
      expect(r.pooled, closeTo(0.068, 1e-9));
      expect(r.statistic, closeTo(2.132, 0.001));
    });

    test('dualidad IC 95 % – prueba bilateral al 5 %', () {
      for (final mu0 in [99.5, 100.0, 100.05, 100.1, 101.5, 101.8]) {
        final ci = Inference.ciMeanT(100.9, 2.0, 25, 0.95);
        final t = Inference.testMeanT(100.9, 2.0, 25, mu0, Tail.twoSided);
        expect(t.rejectAt(0.05), !ci.contains(mu0), reason: 'μ0 = $mu0');
      }
    });

    test('valor crítico con la dirección correcta', () {
      final r = Inference.testMeanZ(-2, 1, 1, 0, Tail.less);
      expect(r.criticalValue(0.05), closeTo(-1.645, 0.001));
    });
  });

  group('Tamaño de muestra y potencia', () {
    test('proporción conservadora al ±3 %', () {
      expect(Inference.sampleSizeProportion(0.5, 0.03, 0.95), 1068);
    });

    test('media redondea hacia arriba', () {
      expect(Inference.sampleSizeMean(12, 2, 0.95), 139);
    });

    test('potencia crece con n (lección m4_l4)', () {
      final p25 = Inference.powerMeanZ(100, 103, 10, 25, 0.05, Tail.greater);
      final p100 = Inference.powerMeanZ(100, 103, 10, 100, 0.05, Tail.greater);
      expect(p25, closeTo(0.44, 0.005));
      expect(p100, closeTo(0.91, 0.005));
    });

    test('sin efecto, la potencia es α', () {
      expect(Inference.powerMeanZ(0, 0, 1, 50, 0.05, Tail.twoSided), closeTo(0.05, 1e-9));
    });

    test('error por comparaciones múltiples', () {
      expect(Inference.familyWiseError(20, 0.05), closeTo(0.6415, 0.0001));
    });
  });

  group('Registro con nombre', () {
    test('todas las funciones declaradas se pueden evaluar', () {
      final samples = <String, Map<String, dynamic>>{
        'z_crit': {'conf': 0.95},
        't_crit': {'conf': 0.95, 'df': 10},
        'ci_mean_z': {'mean': 1, 'sigma': 1, 'n': 10, 'conf': 0.95},
        'ci_mean_t': {'mean': 1, 'sd': 1, 'n': 10, 'conf': 0.95},
        'ci_prop': {'x': 20, 'n': 50, 'conf': 0.95},
        'ci_diff_means': {'mean1': 1, 'sd1': 1, 'n1': 10, 'mean2': 0, 'sd2': 1, 'n2': 12, 'conf': 0.95},
        'ci_diff_props': {'x1': 20, 'n1': 50, 'x2': 25, 'n2': 60, 'conf': 0.95},
        'test_mean_z': {'mean': 1, 'sigma': 1, 'n': 10, 'mu0': 0, 'tail': 'two'},
        'test_mean_t': {'mean': 1, 'sd': 1, 'n': 10, 'mu0': 0, 'tail': 'greater'},
        'test_prop': {'x': 20, 'n': 50, 'p0': 0.5, 'tail': 'less'},
        'test_diff_means': {'mean1': 1, 'sd1': 1, 'n1': 10, 'mean2': 0, 'sd2': 1, 'n2': 12, 'tail': 'two'},
        'test_diff_props': {'x1': 20, 'n1': 50, 'x2': 25, 'n2': 60, 'tail': 'two'},
        'n_mean': {'sigma': 5, 'E': 1, 'conf': 0.95},
        'n_prop': {'p': 0.5, 'E': 0.05, 'conf': 0.95},
        'se_mean': {'sd': 10, 'n': 25},
        'se_prop': {'p': 0.5, 'n': 100},
        'binom_upper': {'k': 16, 'n': 25, 'p': 0.5},
        'cohen_d': {'mean1': 1, 'sd1': 1, 'n1': 10, 'mean2': 0, 'sd2': 1, 'n2': 10},
        'prob_mean_above': {'mu': 0, 'sigma': 1, 'n': 4, 'a': 1},
        'prob_mean_between': {'mu': 0, 'sigma': 1, 'n': 4, 'a': -1, 'b': 1},
        'fwer': {'k': 3, 'alpha': 0.05},
        'power_mean_z': {'mu0': 0, 'mu1': 1, 'sigma': 1, 'n': 10, 'alpha': 0.05, 'tail': 'two'},
      };
      expect(samples.keys.toSet(), InferenceRegistry.functions);
      samples.forEach((fn, args) {
        final r = InferenceRegistry.evaluate(fn, args);
        expect(r.values.every((v) => v.isFinite), isTrue, reason: fn);
      });
    });

    test('función desconocida lanza error', () {
      expect(() => InferenceRegistry.evaluate('nope', {}), throwsArgumentError);
    });
  });

  group('Calculadora', () {
    const runner = ProcedureRunner();

    test('IC de una media produce texto sin lecturas incorrectas', () {
      final out = runner.run(Procedure.ciMean, {'mean': 24.6, 'sd': 6, 'n': 36});
      expect(out.ok, isTrue);
      expect(out.intervalText, contains('confianza'));
      expect(out.intervalText, isNot(contains('probabilidad de que')));
    });

    test('no rechazar se redacta sin «aceptar H0»', () {
      final out = runner.run(Procedure.testMean, {'mean': 0.056, 'sd': 0.012, 'n': 12, 'mu0': 0.05}, tail: Tail.greater);
      expect(out.test!.rejectAt(0.05), isFalse);
      expect(out.testText, contains('no demuestra'));
    });

    test('advierte condiciones de proporción', () {
      final out = runner.run(Procedure.testProportion, {'x': 3, 'n': 40, 'p0': 0.05});
      expect(out.warnings.any((w) => w.contains('n·p0')), isTrue);
    });

    test('valida entradas', () {
      final out = runner.run(Procedure.ciProportion, {'x': 60, 'n': 50});
      expect(out.ok, isFalse);
      final out2 = runner.run(Procedure.ciMean, {'mean': 1, 'sd': -2, 'n': 10});
      expect(out2.ok, isFalse);
      final out3 = runner.run(Procedure.ciMean, {'mean': 1, 'sd': 2, 'n': 10.5});
      expect(out3.ok, isFalse);
    });

    test('todos los procedimientos funcionan con sus valores iniciales', () {
      for (final p in Procedure.values) {
        final v = {for (final f in p.fields) f.key: f.initial!};
        final out = runner.run(p, v);
        expect(out.ok, isTrue, reason: '${p.label}: ${out.errors}');
        expect(out.interval != null || out.test != null || out.sampleSize != null, isTrue);
      }
    });
  });
}
