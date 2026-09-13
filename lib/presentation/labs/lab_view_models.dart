import 'dart:math' as math;

import '../../domain/simulation/city_survey.dart';
import '../../domain/simulation/hypothesis_simulator.dart';
import '../../domain/simulation/interval_simulator.dart';
import '../../domain/simulation/permutation_test.dart';
import '../../domain/simulation/population.dart';
import '../../domain/simulation/sampling_simulator.dart';
import '../../domain/stats/descriptive.dart';
import '../../domain/stats/distributions.dart';
import '../../domain/stats/inference.dart';
import '../../domain/stats/random_source.dart';

// ViewModels de los laboratorios.
//
// Son Dart puro (sin Flutter) y de vida corta: cada pantalla de laboratorio
// crea el suyo y lo descarta al salir. Así se prueban con `flutter test`
// sin interfaz, y el estado de una simulación nunca contamina otra.

// ===================================================================== Lab 1
class SurveyRow {
  SurveyRow(this.method, this.n);
  SamplingMethod method;
  int n;
  final List<double> estimates = [];
  SurveySample? last;

  double get mean => estimates.isEmpty ? double.nan : Descriptive.mean(estimates);
  double get spread => estimates.length < 2 ? double.nan : Descriptive.populationSd(estimates);
}

class SurveyLabModel {
  SurveyLabModel({int seed = 101}) : rng = RandomSource(seed);

  final CitySurvey city = CitySurvey.generate();
  final RandomSource rng;
  final List<SurveyRow> rows = [
    SurveyRow(SamplingMethod.simpleRandom, 25),
    SurveyRow(SamplingMethod.convenience, 200),
  ];
  int runs = 0;

  double get truth => city.trueProportion;

  void preset(String? experimentId) {
    switch (experimentId) {
      case 'e1_2':
        rows[0]
          ..method = SamplingMethod.simpleRandom
          ..n = 40;
        rows[1]
          ..method = SamplingMethod.stratified
          ..n = 40;
      case 'e1_1':
      default:
        rows[0]
          ..method = SamplingMethod.simpleRandom
          ..n = 25;
        rows[1]
          ..method = SamplingMethod.convenience
          ..n = 200;
    }
    reset();
  }

  void draw([int times = 1]) {
    for (var k = 0; k < times; k++) {
      for (final r in rows) {
        final s = city.draw(r.method, r.n, rng);
        r.last = s;
        r.estimates.add(s.estimate);
      }
      runs++;
    }
  }

  void setMethod(int row, SamplingMethod m) {
    rows[row].method = m;
    reset();
  }

  void setN(int row, int n) {
    rows[row].n = n;
    reset();
  }

  void reset() {
    for (final r in rows) {
      r.estimates.clear();
      r.last = null;
    }
    runs = 0;
  }
}

// ===================================================================== Lab 2
class SamplingLabModel {
  SamplingLabModel({int seed = 202}) : rng = RandomSource(seed);

  final RandomSource rng;
  final Map<PopulationShape, Population> _pops = {};
  PopulationShape shape = PopulationShape.normal;
  int n = 25;
  List<double> means = [];
  List<double> lastSample = [];
  int totalDrawn = 0;

  /// Error estándar observado por tamaño de muestra (para comparar).
  final Map<int, double> observedSeByN = {};

  static const List<int> sizes = [1, 2, 5, 10, 25, 30, 50, 100, 200];

  Population get population => _pops.putIfAbsent(shape, () => Population.generate(shape));
  double get theoreticalSe => SamplingSimulator.theoreticalSe(population, n);
  double get observedSe => means.length < 2 ? double.nan : Descriptive.populationSd(means);

  void preset(String? experimentId) {
    switch (experimentId) {
      case 'e2_1':
        shape = PopulationShape.skewed;
        n = 2;
      case 'e2_2':
        shape = PopulationShape.normal;
        n = 25;
      case 'e2_3':
        shape = PopulationShape.skewed;
        n = 200;
      default:
        shape = PopulationShape.normal;
        n = 25;
    }
    means = [];
    lastSample = [];
    totalDrawn = 0;
    observedSeByN.clear();
  }

  void draw(int k) {
    final newMeans = <double>[];
    for (var i = 0; i < k; i++) {
      final s = population.sample(n, rng);
      lastSample = s;
      newMeans.add(Descriptive.mean(s));
    }
    means = [...means, ...newMeans];
    totalDrawn += k;
    if (means.length >= 30) observedSeByN[n] = observedSe;
  }

  void setN(int value) {
    if (value == n) return;
    n = value;
    means = [];
    lastSample = [];
  }

  void setShape(PopulationShape s) {
    if (s == shape) return;
    shape = s;
    means = [];
    lastSample = [];
    observedSeByN.clear();
  }

  void clear() {
    means = [];
    lastSample = [];
  }
}

// ===================================================================== Lab 3
class IntervalRunSummary {
  const IntervalRunSummary(this.label, this.count, this.captureRate, this.meanWidth);
  final String label;
  final int count;
  final double captureRate;
  final double meanWidth;
}

class IntervalLabModel {
  IntervalLabModel({int seed = 303}) : rng = RandomSource(seed);

  final RandomSource rng;
  static const double mu = 50;
  static const double sigma = 10;
  static const List<int> sizes = [5, 10, 20, 30, 50, 100];
  static const List<double> levels = [0.80, 0.90, 0.95, 0.99];

  int n = 20;
  double conf = 0.95;
  IntervalMethod method = IntervalMethod.tWithS;
  List<SimulatedInterval> intervals = [];
  int totalRuns = 0;
  final List<IntervalRunSummary> history = [];

  int get captured => intervals.where((i) => i.captured).length;
  double get captureRate => intervals.isEmpty ? double.nan : captured / intervals.length;
  double get meanWidth => intervals.isEmpty
      ? double.nan
      : intervals.fold<double>(0, (s, i) => s + (i.upper - i.lower)) / intervals.length;

  String get label => '${(conf * 100).round()} % · n = $n · ${method.label}';

  void preset(String? experimentId) {
    switch (experimentId) {
      case 'e3_2':
        n = 20;
        conf = 0.80;
        method = IntervalMethod.tWithS;
      case 'e3_3':
        n = 5;
        conf = 0.95;
        method = IntervalMethod.zWithS;
      default:
        n = 20;
        conf = 0.95;
        method = IntervalMethod.tWithS;
    }
    intervals = [];
    history.clear();
    totalRuns = 0;
  }

  void add(int k) {
    intervals = [
      ...intervals,
      ...IntervalSimulator.many(count: k, mu: mu, sigma: sigma, n: n, conf: conf, method: method, rng: rng),
    ];
    totalRuns += k;
  }

  void _archive() {
    if (intervals.length >= 20) {
      history.insert(0, IntervalRunSummary(label, intervals.length, captureRate, meanWidth));
      if (history.length > 4) history.removeLast();
    }
    intervals = [];
  }

  void setN(int v) {
    if (v == n) return;
    _archive();
    n = v;
  }

  void setConf(double v) {
    if (v == conf) return;
    _archive();
    conf = v;
  }

  void setMethod(IntervalMethod m) {
    if (m == method) return;
    _archive();
    method = m;
  }

  void clear() => intervals = [];
}

// ===================================================================== Lab 4
enum NullMode { coin, studies }

class NullWorldModel {
  NullWorldModel({int seed = 404}) : rng = RandomSource(seed);
  final RandomSource rng;

  NullMode mode = NullMode.coin;

  // Moneda
  static const int coinN = 25;
  int observed = 16;
  List<int> coinSims = [];

  List<int> get coinCounts {
    final c = List<int>.filled(coinN + 1, 0);
    for (final s in coinSims) {
      c[s]++;
    }
    return c;
  }

  double get simulatedP => HypothesisSimulator.upperTailShare(coinSims, observed);
  double get exactP => Distributions.binomialUpper(observed, coinN, 0.5);

  void simulateCoin(int k) {
    coinSims = [...coinSims, ...HypothesisSimulator.nullSuccesses(0.5, coinN, k, rng)];
  }

  // Estudios repetidos
  double effect = 0; // en desviaciones estándar
  int n = 20;
  double alpha = 0.05;
  List<double> pValues = [];
  final Map<int, double> rateByN = {};
  static const List<int> sizes = [10, 20, 30, 50, 90, 150];

  double get rejectionRate => HypothesisSimulator.rejectionRate(pValues, alpha);

  double theoreticalPower(int size) =>
      Inference.powerMeanZ(0, effect, 1, size, alpha, Tail.twoSided);

  void runStudies(int k) {
    pValues = [
      ...pValues,
      ...HypothesisSimulator.studyPValues(
          mu0: 0, trueMu: effect, sigma: 1, n: n, tail: Tail.twoSided, k: k, rng: rng),
    ];
    if (pValues.length >= 100) rateByN[n] = rejectionRate;
  }

  int get runs => mode == NullMode.coin ? coinSims.length : pValues.length;

  void preset(String? experimentId) {
    switch (experimentId) {
      case 'e4_1':
        mode = NullMode.coin;
        observed = 16;
      case 'e4_2':
        mode = NullMode.studies;
        effect = 0;
        n = 20;
      case 'e4_3':
        mode = NullMode.studies;
        effect = 0.3;
        n = 20;
      default:
        mode = NullMode.coin;
    }
    coinSims = [];
    pValues = [];
    rateByN.clear();
  }

  void setEffect(double e) {
    effect = e;
    pValues = [];
    rateByN.clear();
  }

  void setN(int v) {
    n = v;
    pValues = [];
  }
}

// ===================================================================== Lab 5
enum RoomMode { permutation, multiple, bigSample }

class BigStudy {
  const BigStudy(this.n, this.p, this.d);
  final int n;
  final double p;
  final double d;
}

class DecisionRoomModel {
  DecisionRoomModel({int seed = 505}) : rng = RandomSource(seed);
  final RandomSource rng;
  RoomMode mode = RoomMode.permutation;

  // Permutación: notas (0–20) de 24 estudiantes asignados al azar.
  static const List<double> active = [15, 13, 17, 14, 16, 12, 15, 18, 14, 13, 16, 15];
  static const List<double> lecture = [12, 14, 11, 13, 15, 10, 12, 14, 13, 11, 12, 16];
  final PermutationTest perm = PermutationTest(active, lecture);
  List<double> diffs = [];
  List<double> lastA = active;
  List<double> lastB = lecture;

  double get permP => perm.pValue(diffs);
  TestResult get welch => Inference.testDiffMeans(
        Descriptive.mean(active), Descriptive.sd(active), active.length,
        Descriptive.mean(lecture), Descriptive.sd(lecture), lecture.length, Tail.twoSided);

  void shuffle(int k) {
    final out = <double>[];
    for (var i = 0; i < k; i++) {
      final pooled = [...active, ...lecture];
      rng.shuffle(pooled);
      final a = pooled.sublist(0, active.length);
      final b = pooled.sublist(active.length);
      out.add(Descriptive.mean(a) - Descriptive.mean(b));
      if (i == k - 1) {
        lastA = a;
        lastB = b;
      }
    }
    diffs = [...diffs, ...out];
  }

  // Comparaciones múltiples
  static const int tests = 20;
  static const int nPerGroup = 15;
  bool bonferroni = false;
  List<int> families = [];

  double get alphaPerTest => bonferroni ? 0.05 / tests : 0.05;
  double get familyRate =>
      families.isEmpty ? double.nan : families.where((h) => h > 0).length / families.length;

  void runFamilies(int k) {
    families = [
      ...families,
      ...HypothesisSimulator.multipleTestingFamilies(
          families: k, tests: tests, nPerGroup: nPerGroup, alpha: alphaPerTest, rng: rng),
    ];
  }

  void setBonferroni(bool v) {
    bonferroni = v;
    families = [];
  }

  // Muestras enormes
  static const double diff = 0.02;
  static const double sd = 0.9;
  static const List<int> sizes = [500, 5000, 50000];
  int bigN = 500;
  List<BigStudy> studies = [];

  void runBig(int k) {
    final out = <BigStudy>[];
    for (var i = 0; i < k; i++) {
      final se = sd * math.sqrt(2 / bigN);
      final observed = rng.nextNormal(diff, se);
      final t = observed / se;
      final df = (2 * bigN - 2).toDouble();
      final p = Inference.pValue(t, Tail.twoSided, (v) => Distributions.tCdf(v, df));
      out.add(BigStudy(bigN, p, observed / sd));
    }
    studies = [...studies, ...out];
  }

  List<BigStudy> studiesFor(int n) => studies.where((s) => s.n == n).toList();

  int get runs => switch (mode) {
        RoomMode.permutation => diffs.length,
        RoomMode.multiple => families.length,
        RoomMode.bigSample => studies.length,
      };

  void preset(String? experimentId) {
    switch (experimentId) {
      case 'e5_2':
        mode = RoomMode.multiple;
      case 'e5_3':
        mode = RoomMode.bigSample;
      default:
        mode = RoomMode.permutation;
    }
    diffs = [];
    lastA = active;
    lastB = lecture;
    families = [];
    bonferroni = false;
    studies = [];
    bigN = 500;
  }
}
