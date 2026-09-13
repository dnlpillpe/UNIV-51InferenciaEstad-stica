import 'package:flutter_test/flutter_test.dart';
import 'package:inferencia_estadistica/domain/simulation/city_survey.dart';
import 'package:inferencia_estadistica/domain/simulation/interval_simulator.dart';
import 'package:inferencia_estadistica/domain/simulation/population.dart';
import 'package:inferencia_estadistica/presentation/labs/lab_view_models.dart';

void main() {
  test('Lab 1: los preajustes fijan los métodos del experimento', () {
    final m = SurveyLabModel();
    m.preset('e1_2');
    expect(m.rows[1].method, SamplingMethod.stratified);
    expect(m.rows[0].n, 40);
    m.draw(5);
    expect(m.runs, 5);
    expect(m.rows[0].estimates.length, 5);
    m.setN(0, 100);
    expect(m.runs, 0);
  });

  test('Lab 2: cambiar n reinicia las medias pero conserva el conteo total', () {
    final m = SamplingLabModel()..preset('e2_2');
    expect(m.shape, PopulationShape.normal);
    m.draw(100);
    expect(m.means.length, 100);
    expect(m.observedSeByN.containsKey(25), isTrue);
    m.setN(100);
    expect(m.means, isEmpty);
    m.draw(100);
    expect(m.totalDrawn, 200);
    expect(m.observedSeByN[100]!, lessThan(m.observedSeByN[25]!));
  });

  test('Lab 3: cambiar la configuración archiva la anterior', () {
    final m = IntervalLabModel()..preset('e3_3');
    expect(m.method, IntervalMethod.zWithS);
    expect(m.n, 5);
    m.add(50);
    m.setMethod(IntervalMethod.tWithS);
    expect(m.history.length, 1);
    expect(m.intervals, isEmpty);
    expect(m.totalRuns, 50);
  });

  test('Lab 4: moneda y estudios', () {
    final m = NullWorldModel()..preset('e4_1');
    expect(m.mode, NullMode.coin);
    m.simulateCoin(200);
    expect(m.runs, 200);
    expect(m.coinCounts.fold<int>(0, (s, x) => s + x), 200);
    expect(m.exactP, closeTo(0.1148, 0.0001));
    m.preset('e4_3');
    expect(m.mode, NullMode.studies);
    expect(m.effect, 0.3);
    m.runStudies(100);
    expect(m.rateByN.containsKey(20), isTrue);
    expect(m.theoreticalPower(90), greaterThan(0.79));
  });

  test('Lab 5: permutación, comparaciones múltiples y n enorme', () {
    final m = DecisionRoomModel()..preset('e5_1');
    m.shuffle(10);
    expect(m.runs, 10);
    expect(m.lastA.length, 12);
    expect([...m.lastA, ...m.lastB]..sort(), [...DecisionRoomModel.active, ...DecisionRoomModel.lecture]..sort());
    expect(m.welch.pValue, closeTo(0.0082, 0.0005));
    m.preset('e5_2');
    m.runFamilies(20);
    expect(m.runs, 20);
    m.setBonferroni(true);
    expect(m.alphaPerTest, closeTo(0.0025, 1e-12));
    expect(m.families, isEmpty);
    m.preset('e5_3');
    m.bigN = 50000;
    m.runBig(20);
    final sig = m.studiesFor(50000).where((s) => s.p <= 0.05).length;
    expect(sig, greaterThanOrEqualTo(14)); // potencia ≈ 0,94
  });
}
