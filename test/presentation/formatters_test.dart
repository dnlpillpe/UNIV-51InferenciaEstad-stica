import 'package:flutter_test/flutter_test.dart';
import 'package:inferencia_estadistica/core/utils/formatters.dart';

void main() {
  test('coma decimal y signo menos tipográfico', () {
    expect(Fmt.number(0.0357, 4), '0,0357');
    expect(Fmt.number(-2.5, 1), '−2,5');
    expect(Fmt.number(-0.0001, 2), '0,00');
  });

  test('miles con espacio fino desde cinco cifras', () {
    expect(Fmt.integer(1068), '1068');
    expect(Fmt.integer(50000), '50 000');
  });

  test('porcentajes y p-valores', () {
    expect(Fmt.percent(0.33), '33,0 %');
    expect(Fmt.pValue(0.00001), '< 0,0001');
    expect(Fmt.pValue(0.0167), '0,0167');
    expect(Fmt.pValue(0.31), '0,310');
  });

  test('lee lo que escribe el estudiante', () {
    expect(Fmt.parse('0,5'), 0.5);
    expect(Fmt.parse('0.5'), 0.5);
    expect(Fmt.parse('1 068'), 1068);
    expect(Fmt.parse('1.068,5'), 1068.5);
    expect(Fmt.parse('−1,5'), -1.5);
    expect(Fmt.parse('4,8 %'), closeTo(0.048, 1e-12));
    expect(Fmt.parse('abc'), isNull);
  });

  test('marcas de eje', () {
    expect(Fmt.niceTicks(0, 1), [0, 0.2, 0.4, 0.6, 0.8, 1]);
    expect(Fmt.niceTicks(-4, 4).contains(0), isTrue);
  });
}
