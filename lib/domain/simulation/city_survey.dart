import 'dart:math' as math;

import '../stats/random_source.dart';

/// Distritos de Villa Muestra, la ciudad del laboratorio 1.
class District {
  const District(this.name, this.rate, this.colStart, this.colEnd, this.rowStart, this.rowEnd);
  final String name;

  /// Probabilidad de que un residente use transporte público a diario.
  final double rate;
  final int colStart, colEnd, rowStart, rowEnd;

  bool containsCell(int col, int row) =>
      col >= colStart && col < colEnd && row >= rowStart && row < rowEnd;
}

class Resident {
  const Resident(this.index, this.col, this.row, this.district, this.usesTransit);
  final int index;
  final int col;
  final int row;
  final int district;
  final bool usesTransit;
}

enum SamplingMethod {
  simpleRandom('Aleatorio simple', 'Todos tienen la misma probabilidad de ser elegidos.'),
  systematic('Sistemático', 'Uno de cada k residentes, desde un inicio al azar.'),
  stratified('Estratificado', 'Aleatorio dentro de cada distrito, en proporción a su tamaño.'),
  convenience('Conveniencia', 'Se encuesta a quien pasa por la puerta del campus.'),
  voluntary('Respuesta voluntaria', 'Encuesta abierta: responde quien quiere.');

  const SamplingMethod(this.label, this.description);
  final String label;
  final String description;

  bool get isProbabilistic =>
      this == simpleRandom || this == systematic || this == stratified;
}

class SurveySample {
  const SurveySample(this.method, this.indices, this.estimate);
  final SamplingMethod method;
  final List<int> indices;
  final double estimate;
}

/// Ciudad de 600 residentes en una cuadrícula de 30 × 20.
///
/// Los distritos difieren mucho en el uso de transporte público, así que:
/// * la conveniencia (campus) y la respuesta voluntaria están sesgadas;
/// * el muestreo estratificado reduce la variabilidad frente al aleatorio.
class CitySurvey {
  CitySurvey._(this.residents);

  static const int cols = 30;
  static const int rows = 20;

  static const List<District> districts = [
    District('Campus', 0.90, 0, 10, 0, 10),
    District('Centro', 0.60, 10, 30, 0, 10),
    District('Barrio Alto', 0.30, 0, 15, 10, 20),
    District('Periferia', 0.10, 15, 30, 10, 20),
  ];

  final List<Resident> residents;

  int get size => residents.length;

  double get trueProportion =>
      residents.where((r) => r.usesTransit).length / residents.length;

  double districtProportion(int d) {
    final inD = residents.where((r) => r.district == d).toList();
    return inD.where((r) => r.usesTransit).length / inD.length;
  }

  factory CitySurvey.generate({int seed = 36}) {
    final rng = RandomSource(seed);
    final list = <Resident>[];
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final d = districts.indexWhere((x) => x.containsCell(col, row));
        list.add(Resident(list.length, col, row, d, rng.nextBool(districts[d].rate)));
      }
    }
    return CitySurvey._(list);
  }

  double _estimate(List<int> idx) =>
      idx.isEmpty ? double.nan : idx.where((i) => residents[i].usesTransit).length / idx.length;

  SurveySample draw(SamplingMethod method, int n, RandomSource rng) {
    final idx = switch (method) {
      SamplingMethod.simpleRandom => _simpleRandom(n, rng),
      SamplingMethod.systematic => _systematic(n, rng),
      SamplingMethod.stratified => _stratified(n, rng),
      SamplingMethod.convenience => _weighted(n, rng, _convenienceWeight),
      SamplingMethod.voluntary => _voluntary(n, rng),
    };
    return SurveySample(method, idx, _estimate(idx));
  }

  List<int> _simpleRandom(int n, RandomSource rng) {
    final all = List<int>.generate(size, (i) => i);
    rng.shuffle(all);
    return all.sublist(0, n.clamp(1, size));
  }

  List<int> _systematic(int n, RandomSource rng) {
    final k = (size / n).floor().clamp(1, size);
    final start = rng.nextInt(k);
    final out = <int>[];
    for (var i = start; i < size && out.length < n; i += k) {
      out.add(i);
    }
    return out;
  }

  List<int> _stratified(int n, RandomSource rng) {
    final out = <int>[];
    for (var d = 0; d < districts.length; d++) {
      final members = residents.where((r) => r.district == d).map((r) => r.index).toList();
      final quota = (n * members.length / size).round();
      rng.shuffle(members);
      out.addAll(members.take(quota.clamp(0, members.length)));
    }
    return out;
  }

  /// Quien pasa por la puerta del campus: los residentes del campus pasan
  /// mucho más, y los usuarios de transporte público (la parada está ahí)
  /// el doble que los demás.
  double _convenienceWeight(Resident r) {
    final base = switch (r.district) { 0 => 6.0, 1 => 1.5, _ => 0.6 };
    return r.usesTransit ? base * 2 : base;
  }

  /// Muestreo ponderado sin reposición (método de Efraimidis–Spirakis).
  List<int> _weighted(int n, RandomSource rng, double Function(Resident) weight) {
    final keys = <MapEntry<int, double>>[];
    for (final r in residents) {
      final u = rng.nextDouble();
      final w = weight(r);
      keys.add(MapEntry(r.index, -_log(u) / w));
    }
    keys.sort((a, b) => a.value.compareTo(b.value));
    return keys.take(n.clamp(1, size)).map((e) => e.key).toList();
  }

  static double _log(double u) => u <= 0 ? -745.0 : math.log(u);

  /// Encuesta abierta: los usuarios de transporte, más interesados en el
  /// tema, responden con probabilidad 0,6; los demás con 0,2.
  List<int> _voluntary(int n, RandomSource rng) {
    final order = List<int>.generate(size, (i) => i);
    rng.shuffle(order);
    final out = <int>[];
    var guard = 0;
    while (out.length < n && guard < 20) {
      for (final i in order) {
        if (out.length >= n) break;
        if (out.contains(i)) continue;
        final p = residents[i].usesTransit ? 0.6 : 0.2;
        if (rng.nextBool(p)) out.add(i);
      }
      guard++;
    }
    return out;
  }
}
