import 'dart:math' as math;

import 'distributions.dart';
import 'inference.dart';

/// Registro de funciones con nombre, para que el contenido (JSON) pueda
/// declarar cifras verificables: `{"fn": "ci_mean_t", "args": {...}}`.
///
/// El mismo registro existe en `tool/inference_core.py`. Los tests de
/// contenido recorren todos los `verify` del JSON y los comprueban contra
/// este motor, de modo que editar un dato nunca deja falso un enunciado.
class InferenceRegistry {
  InferenceRegistry._();

  static double _d(Map<String, dynamic> a, String k) {
    final v = a[k];
    if (v is num) return v.toDouble();
    throw ArgumentError('Falta el argumento numérico "$k"');
  }

  static int _i(Map<String, dynamic> a, String k) {
    final v = a[k];
    if (v is num) return v.round();
    throw ArgumentError('Falta el argumento entero "$k"');
  }

  static Tail _tail(Map<String, dynamic> a) => Tail.fromCode((a['tail'] ?? 'two') as String);

  static const Set<String> functions = {
    'z_crit', 't_crit', 'ci_mean_z', 'ci_mean_t', 'ci_prop', 'ci_diff_means',
    'ci_diff_props', 'test_mean_z', 'test_mean_t', 'test_prop', 'test_diff_means',
    'test_diff_props', 'n_mean', 'n_prop', 'se_mean', 'se_prop', 'binom_upper',
    'cohen_d', 'prob_mean_above', 'prob_mean_between', 'fwer', 'power_mean_z',
  };

  static bool isCi(String fn) => fn.startsWith('ci_');
  static bool isTest(String fn) => fn.startsWith('test_');

  static ConfidenceInterval? interval(String fn, Map<String, dynamic> a) {
    switch (fn) {
      case 'ci_mean_z':
        return Inference.ciMeanZ(_d(a, 'mean'), _d(a, 'sigma'), _i(a, 'n'), _d(a, 'conf'));
      case 'ci_mean_t':
        return Inference.ciMeanT(_d(a, 'mean'), _d(a, 'sd'), _i(a, 'n'), _d(a, 'conf'));
      case 'ci_prop':
        return Inference.ciProportion(_i(a, 'x'), _i(a, 'n'), _d(a, 'conf'));
      case 'ci_diff_means':
        return Inference.ciDiffMeans(_d(a, 'mean1'), _d(a, 'sd1'), _i(a, 'n1'),
            _d(a, 'mean2'), _d(a, 'sd2'), _i(a, 'n2'), _d(a, 'conf'));
      case 'ci_diff_props':
        return Inference.ciDiffProportions(
            _i(a, 'x1'), _i(a, 'n1'), _i(a, 'x2'), _i(a, 'n2'), _d(a, 'conf'));
    }
    return null;
  }

  static TestResult? test(String fn, Map<String, dynamic> a) {
    switch (fn) {
      case 'test_mean_z':
        return Inference.testMeanZ(_d(a, 'mean'), _d(a, 'sigma'), _i(a, 'n'), _d(a, 'mu0'), _tail(a));
      case 'test_mean_t':
        return Inference.testMeanT(_d(a, 'mean'), _d(a, 'sd'), _i(a, 'n'), _d(a, 'mu0'), _tail(a));
      case 'test_prop':
        return Inference.testProportion(_i(a, 'x'), _i(a, 'n'), _d(a, 'p0'), _tail(a));
      case 'test_diff_means':
        return Inference.testDiffMeans(_d(a, 'mean1'), _d(a, 'sd1'), _i(a, 'n1'),
            _d(a, 'mean2'), _d(a, 'sd2'), _i(a, 'n2'), _tail(a));
      case 'test_diff_props':
        return Inference.testDiffProportions(
            _i(a, 'x1'), _i(a, 'n1'), _i(a, 'x2'), _i(a, 'n2'), _tail(a));
    }
    return null;
  }

  /// Evalúa una función con nombre y devuelve todos sus campos numéricos.
  static Map<String, double> evaluate(String fn, Map<String, dynamic> a) {
    final ci = interval(fn, a);
    if (ci != null) return ci.toMap();
    final t = test(fn, a);
    if (t != null) return t.toMap();
    switch (fn) {
      case 'z_crit':
        return {'critical': Inference.zCritical(_d(a, 'conf'))};
      case 't_crit':
        return {'critical': Inference.tCritical(_d(a, 'conf'), _d(a, 'df'))};
      case 'n_mean':
        return {'n': Inference.sampleSizeMean(_d(a, 'sigma'), _d(a, 'E'), _d(a, 'conf')).toDouble()};
      case 'n_prop':
        return {'n': Inference.sampleSizeProportion(_d(a, 'p'), _d(a, 'E'), _d(a, 'conf')).toDouble()};
      case 'se_mean':
        return {'se': _d(a, 'sd') / math.sqrt(_d(a, 'n'))};
      case 'se_prop':
        final p = _d(a, 'p');
        return {'se': math.sqrt(p * (1 - p) / _d(a, 'n'))};
      case 'binom_upper':
        return {'p': Distributions.binomialUpper(_i(a, 'k'), _i(a, 'n'), _d(a, 'p'))};
      case 'cohen_d':
        return {
          'd': Inference.cohenD(_d(a, 'mean1'), _d(a, 'sd1'), _i(a, 'n1'),
              _d(a, 'mean2'), _d(a, 'sd2'), _i(a, 'n2'))
        };
      case 'prob_mean_above':
        final se = _d(a, 'sigma') / math.sqrt(_d(a, 'n'));
        return {'p': 1 - Distributions.normalCdf((_d(a, 'a') - _d(a, 'mu')) / se)};
      case 'prob_mean_between':
        final se = _d(a, 'sigma') / math.sqrt(_d(a, 'n'));
        final mu = _d(a, 'mu');
        return {
          'p': Distributions.normalCdf((_d(a, 'b') - mu) / se) -
              Distributions.normalCdf((_d(a, 'a') - mu) / se)
        };
      case 'fwer':
        return {'p': Inference.familyWiseError(_i(a, 'k'), _d(a, 'alpha'))};
      case 'power_mean_z':
        return {
          'power': Inference.powerMeanZ(_d(a, 'mu0'), _d(a, 'mu1'), _d(a, 'sigma'),
              _i(a, 'n'), _d(a, 'alpha'), _tail(a))
        };
    }
    throw ArgumentError('Función desconocida: $fn');
  }
}
