import 'package:flutter_test/flutter_test.dart';
import 'package:inferencia_estadistica/domain/models/exercise_models.dart';
import 'package:inferencia_estadistica/domain/stats/inference_registry.dart';

import '../support/test_content.dart';

/// Test de cifras: cada número que el contenido afirma (en `verify`) se
/// recalcula con el motor. Si alguien edita un dato del JSON y deja falso un
/// enunciado, esta prueba falla.
void main() {
  final c = loadTestContent();

  test('todas las cifras declaradas coinciden con el motor', () {
    var n = 0;
    final sources = [
      for (final e in c.exercises) (e.id, e.verify),
      for (final cs in c.cases) (cs.id, cs.verify),
    ];
    for (final (id, claims) in sources) {
      for (final v in claims) {
        n++;
        final r = InferenceRegistry.evaluate(v.fn, v.args);
        expect(r.containsKey(v.field), isTrue, reason: '$id: ${v.fn} no tiene ${v.field}');
        expect(r[v.field]!, closeTo(v.value, v.tolerance), reason: '$id: ${v.fn}.${v.field}');
      }
    }
    expect(n, greaterThanOrEqualTo(45));
  });

  test('la respuesta de cada ejercicio numérico verificado es la del motor', () {
    for (final e in c.exercises.whereType<NumericExercise>()) {
      if (e.verify.isEmpty) continue;
      final v = e.verify.first; // convención: el primero es la respuesta
      final got = InferenceRegistry.evaluate(v.fn, v.args)[v.field]!;
      expect(got, closeTo(e.answer, e.tolerance), reason: e.id);
    }
  });

  test('la decisión esperada de cada caso coincide con el cálculo', () {
    for (final cs in c.cases) {
      final a = cs.analysis;
      if (a == null || cs.expectedReject == null) continue;
      final t = InferenceRegistry.test(a.fn, a.args);
      expect(t, isNotNull, reason: cs.id);
      expect(t!.rejectAt(a.alpha), cs.expectedReject, reason: '${cs.id}: p = ${t.pValue}');
    }
  });

  test('todos los análisis de casos se pueden ejecutar', () {
    for (final cs in c.cases) {
      final a = cs.analysis;
      if (a == null) continue;
      final ok = InferenceRegistry.test(a.fn, a.args) != null || InferenceRegistry.interval(a.fn, a.args) != null;
      expect(ok, isTrue, reason: cs.id);
      final comp = a.companion;
      if (comp != null) expect(InferenceRegistry.interval(comp.fn, comp.args), isNotNull, reason: cs.id);
    }
  });
}
