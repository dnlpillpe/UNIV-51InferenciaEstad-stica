import '../stats/inference.dart';

/// Campo de entrada de un procedimiento de la calculadora.
class ProcedureField {
  const ProcedureField(this.key, this.label, {this.hint, this.integer = false, this.initial});
  final String key;
  final String label;
  final String? hint;
  final bool integer;
  final double? initial;
}

enum Procedure {
  ciMean('IC para una media', 'Estimar μ con σ desconocida (t) o conocida (z)', true, false),
  ciProportion('IC para una proporción', 'Estimar p a partir de x éxitos en n', true, false),
  testMean('Prueba para una media', 'H0: μ = μ0 con t (o z si σ es conocida)', false, true),
  testProportion('Prueba para una proporción', 'H0: p = p0', false, true),
  diffMeans('Dos medias independientes', 'Welch: IC y prueba para μ1 − μ2', true, true),
  diffProportions('Dos proporciones', 'IC y prueba para p1 − p2', true, true),
  sampleSizeMean('Tamaño de muestra: media', 'n para un margen de error E', false, false),
  sampleSizeProportion('Tamaño de muestra: proporción', 'n para un margen de error E', false, false);

  const Procedure(this.label, this.description, this.hasInterval, this.hasTest);
  final String label;
  final String description;
  final bool hasInterval;
  final bool hasTest;

  bool get usesTail => hasTest;
  bool get usesConfidence => hasInterval || this == sampleSizeMean || this == sampleSizeProportion;
  bool get canUseKnownSigma => this == ciMean || this == testMean;

  List<ProcedureField> get fields {
    switch (this) {
      case Procedure.ciMean:
        return const [
          ProcedureField('mean', 'Media muestral x̄', initial: 24.6),
          ProcedureField('sd', 'Desviación s (o σ)', initial: 6),
          ProcedureField('n', 'Tamaño n', integer: true, initial: 36),
        ];
      case Procedure.ciProportion:
        return const [
          ProcedureField('x', 'Éxitos x', integer: true, initial: 210),
          ProcedureField('n', 'Tamaño n', integer: true, initial: 500),
        ];
      case Procedure.testMean:
        return const [
          ProcedureField('mean', 'Media muestral x̄', initial: 0.86),
          ProcedureField('sd', 'Desviación s (o σ)', initial: 0.11),
          ProcedureField('n', 'Tamaño n', integer: true, initial: 18),
          ProcedureField('mu0', 'Valor de H0: μ0', initial: 0.80),
        ];
      case Procedure.testProportion:
        return const [
          ProcedureField('x', 'Éxitos x', integer: true, initial: 16),
          ProcedureField('n', 'Tamaño n', integer: true, initial: 200),
          ProcedureField('p0', 'Valor de H0: p0', initial: 0.05),
        ];
      case Procedure.diffMeans:
        return const [
          ProcedureField('mean1', 'x̄1', initial: 38.4),
          ProcedureField('sd1', 's1', initial: 9.1),
          ProcedureField('n1', 'n1', integer: true, initial: 32),
          ProcedureField('mean2', 'x̄2', initial: 43.9),
          ProcedureField('sd2', 's2', initial: 10.2),
          ProcedureField('n2', 'n2', integer: true, initial: 30),
        ];
      case Procedure.diffProportions:
        return const [
          ProcedureField('x1', 'Éxitos x1', integer: true, initial: 296),
          ProcedureField('n1', 'n1', integer: true, initial: 4000),
          ProcedureField('x2', 'Éxitos x2', integer: true, initial: 248),
          ProcedureField('n2', 'n2', integer: true, initial: 4000),
        ];
      case Procedure.sampleSizeMean:
        return const [
          ProcedureField('sigma', 'σ estimada', initial: 12),
          ProcedureField('E', 'Margen de error E', initial: 2),
        ];
      case Procedure.sampleSizeProportion:
        return const [
          ProcedureField('p', 'p esperada (0,5 si no sabes)', initial: 0.5),
          ProcedureField('E', 'Margen de error E (proporción)', initial: 0.03),
        ];
    }
  }
}

class ProcedureOutcome {
  const ProcedureOutcome({
    this.interval,
    this.test,
    this.sampleSize,
    this.warnings = const [],
    this.errors = const [],
    this.intervalText,
    this.testText,
  });

  final ConfidenceInterval? interval;
  final TestResult? test;
  final int? sampleSize;
  final List<String> warnings;
  final List<String> errors;
  final String? intervalText;
  final String? testText;

  bool get ok => errors.isEmpty;
}

/// Ejecuta un procedimiento, valida entradas y redacta la interpretación.
class ProcedureRunner {
  const ProcedureRunner();

  ProcedureOutcome run(
    Procedure p,
    Map<String, double> v, {
    double conf = 0.95,
    double alpha = 0.05,
    Tail tail = Tail.twoSided,
    bool knownSigma = false,
  }) {
    final errors = _validate(p, v);
    if (errors.isNotEmpty) return ProcedureOutcome(errors: errors);
    final warnings = <String>[];
    int n(String k) => v[k]!.round();

    switch (p) {
      case Procedure.ciMean:
        final ci = knownSigma
            ? Inference.ciMeanZ(v['mean']!, v['sd']!, n('n'), conf)
            : Inference.ciMeanT(v['mean']!, v['sd']!, n('n'), conf);
        _meanWarnings(n('n'), warnings, knownSigma);
        return ProcedureOutcome(
          interval: ci,
          warnings: warnings,
          intervalText: Interpretation.interval(ci, 'la media poblacional μ'),
        );
      case Procedure.ciProportion:
        final ci = Inference.ciProportion(n('x'), n('n'), conf);
        _successWarnings({'éxitos': n('x'), 'fracasos': n('n') - n('x')}, warnings);
        return ProcedureOutcome(
          interval: ci,
          warnings: warnings,
          intervalText: Interpretation.interval(ci, 'la proporción poblacional p', percent: true),
        );
      case Procedure.testMean:
        final t = knownSigma
            ? Inference.testMeanZ(v['mean']!, v['sd']!, n('n'), v['mu0']!, tail)
            : Inference.testMeanT(v['mean']!, v['sd']!, n('n'), v['mu0']!, tail);
        _meanWarnings(n('n'), warnings, knownSigma);
        return ProcedureOutcome(
          test: t,
          warnings: warnings,
          testText: Interpretation.test(t, alpha, 'μ', v['mu0']!),
        );
      case Procedure.testProportion:
        final t = Inference.testProportion(n('x'), n('n'), v['p0']!, tail);
        final e = n('n') * v['p0']!;
        if (e < 10 || n('n') - e < 10) {
          warnings.add('Bajo H0 se esperan ${e.toStringAsFixed(1).replaceAll('.', ',')} éxitos: '
              'la aproximación normal requiere n·p0 ≥ 10 y n(1 − p0) ≥ 10. Considera una prueba binomial exacta.');
        }
        return ProcedureOutcome(
          test: t,
          warnings: warnings,
          testText: Interpretation.test(t, alpha, 'p', v['p0']!),
        );
      case Procedure.diffMeans:
        final ci = Inference.ciDiffMeans(
            v['mean1']!, v['sd1']!, n('n1'), v['mean2']!, v['sd2']!, n('n2'), conf);
        final t = Inference.testDiffMeans(
            v['mean1']!, v['sd1']!, n('n1'), v['mean2']!, v['sd2']!, n('n2'), tail);
        if (n('n1') < 30 || n('n2') < 30) {
          warnings.add('Algún grupo tiene menos de 30 datos: el procedimiento supone poblaciones '
              'aproximadamente normales. Revisa asimetrías y valores extremos.');
        }
        return ProcedureOutcome(
          interval: ci,
          test: t,
          warnings: warnings,
          intervalText: Interpretation.interval(ci, 'la diferencia de medias μ1 − μ2'),
          testText: Interpretation.test(t, alpha, 'μ1 − μ2', 0),
        );
      case Procedure.diffProportions:
        final ci = Inference.ciDiffProportions(n('x1'), n('n1'), n('x2'), n('n2'), conf);
        final t = Inference.testDiffProportions(n('x1'), n('n1'), n('x2'), n('n2'), tail);
        _successWarnings({
          'éxitos del grupo 1': n('x1'),
          'fracasos del grupo 1': n('n1') - n('x1'),
          'éxitos del grupo 2': n('x2'),
          'fracasos del grupo 2': n('n2') - n('x2'),
        }, warnings);
        return ProcedureOutcome(
          interval: ci,
          test: t,
          warnings: warnings,
          intervalText: Interpretation.interval(ci, 'la diferencia de proporciones p1 − p2', percent: true),
          testText: Interpretation.test(t, alpha, 'p1 − p2', 0),
        );
      case Procedure.sampleSizeMean:
        final size = Inference.sampleSizeMean(v['sigma']!, v['E']!, conf);
        return ProcedureOutcome(sampleSize: size, warnings: const [
          'El resultado depende de la σ supuesta: si la real es mayor, el margen será más amplio. '
              'Usa un estudio piloto o datos previos.'
        ]);
      case Procedure.sampleSizeProportion:
        final size = Inference.sampleSizeProportion(v['p']!, v['E']!, conf);
        return ProcedureOutcome(sampleSize: size, warnings: [
          if (v['p'] != 0.5) 'Con p = 0,5 se obtiene el tamaño más conservador (el mayor posible).',
          'El margen de error no cubre sesgos de selección ni de no respuesta.',
        ]);
    }
  }

  void _meanWarnings(int n, List<String> w, bool knownSigma) {
    if (n < 30) {
      w.add('Con n = $n, el procedimiento supone que la población es aproximadamente normal. '
          'Con asimetría fuerte o valores extremos, el nivel real puede diferir del anunciado.');
    }
    if (knownSigma) {
      w.add('Usar z con σ «conocida» solo es correcto si σ proviene de información externa confiable; '
          'si la calculaste con esta muestra, corresponde t.');
    }
  }

  void _successWarnings(Map<String, int> counts, List<String> w) {
    final low = counts.entries.where((e) => e.value < 10).map((e) => e.key).toList();
    if (low.isNotEmpty) {
      w.add('Menos de 10 ${low.join(', ')}: la aproximación normal no es fiable.');
    }
  }

  List<String> _validate(Procedure p, Map<String, double> v) {
    final e = <String>[];
    for (final f in p.fields) {
      final x = v[f.key];
      if (x == null || x.isNaN) {
        e.add('Falta «${f.label}».');
        continue;
      }
      if (f.integer && (x - x.round()).abs() > 1e-9) e.add('«${f.label}» debe ser un número entero.');
    }
    if (e.isNotEmpty) return e;
    bool pos(String k) => v[k]! > 0;
    for (final k in ['sd', 'sd1', 'sd2', 'sigma', 'E']) {
      if (v.containsKey(k) && !pos(k)) e.add('La desviación y el margen deben ser mayores que 0.');
    }
    for (final k in ['n', 'n1', 'n2']) {
      if (v.containsKey(k) && v[k]! < 2) e.add('Cada tamaño de muestra debe ser al menos 2.');
    }
    for (final pair in [('x', 'n'), ('x1', 'n1'), ('x2', 'n2')]) {
      if (v.containsKey(pair.$1) && (v[pair.$1]! < 0 || v[pair.$1]! > v[pair.$2]!)) {
        e.add('Los éxitos deben estar entre 0 y n.');
      }
    }
    for (final k in ['p0', 'p']) {
      if (v.containsKey(k) && (v[k]! <= 0 || v[k]! >= 1)) e.add('Las proporciones deben estar entre 0 y 1 (por ejemplo 0,05).');
    }
    if (p == Procedure.sampleSizeProportion && v['E']! >= 1) {
      e.add('El margen de error de una proporción se escribe como proporción (0,03 = 3 puntos).');
    }
    if (p == Procedure.ciProportion && (v['x'] == 0 || v['x'] == v['n'])) {
      e.add('Con 0 éxitos o con todos éxitos el intervalo de Wald no funciona.');
    }
    return e.toSet().toList();
  }
}

/// Redacción de resultados en lenguaje del problema, sin las lecturas
/// incorrectas que el curso combate.
class Interpretation {
  Interpretation._();

  static String _n(double v, int d) {
    final s = v.toStringAsFixed(d).replaceAll('.', ',');
    return s.startsWith('-') ? '−${s.substring(1)}' : s;
  }

  static String _fmt(double v, bool percent) {
    if (percent) return '${_n(v * 100, 1)} %';
    final a = v.abs();
    final d = a >= 100 ? 1 : a >= 1 ? 2 : 4;
    return _n(v, d);
  }

  static String interval(ConfidenceInterval ci, String parameter, {bool percent = false}) {
    final conf = '${_n(ci.level * 100, 0)} %';
    final dist = ci.distribution == RefDistribution.t
        ? 't con ${_n(ci.df!, ci.df! == ci.df!.roundToDouble() ? 0 : 1)} gl'
        : 'z';
    return 'Con $conf de confianza, $parameter está entre ${_fmt(ci.lower, percent)} y '
        '${_fmt(ci.upper, percent)} (estimación ${_fmt(ci.estimate, percent)} ± '
        '${_fmt(ci.margin, percent)}, valor crítico $dist = ${_n(ci.critical, 3)}). '
        'El $conf describe al método: repetido muchas veces, ese porcentaje de intervalos '
        'contendría el valor real.';
  }

  static String test(TestResult t, double alpha, String parameter, double value) {
    final sym = t.distribution == RefDistribution.t ? 't' : 'z';
    final gl = t.df == null ? '' : ' (${_n(t.df!, t.df! == t.df!.roundToDouble() ? 0 : 1)} gl)';
    final p = t.pValue < 0.0001 ? 'menor que 0,0001' : _n(t.pValue, 4);
    final h1 = '$parameter ${t.tail.symbol} ${_n(value, value.abs() < 1 && value != 0 ? 3 : 2)}';
    final decision = t.rejectAt(alpha)
        ? 'Con α = ${_n(alpha, 2)} se rechaza H0: los datos aportan evidencia de que $h1.'
        : 'Con α = ${_n(alpha, 2)} no se rechaza H0: la evidencia no es suficiente para afirmar que $h1. '
            'Esto no demuestra que H0 sea cierta.';
    final freq = t.pValue < 0.0001
        ? 'menos de 1 de cada 10 000'
        : 'alrededor del ${_n(t.pValue * 100, t.pValue < 0.01 ? 2 : 1)} %';
    return 'Estadístico $sym = ${_n(t.statistic, 3)}$gl; p-valor $p. $decision '
        'Si H0 fuera cierta, un resultado tan extremo o más aparecería en $freq de las muestras.';
  }
}
