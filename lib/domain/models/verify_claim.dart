import 'json_utils.dart';

/// Cifra afirmada por el contenido que debe coincidir con el motor.
///
/// Ejemplo: `{"fn":"test_mean_t","args":{...},"field":"p","value":0.024,"tol":0.001}`.
class VerifyClaim {
  const VerifyClaim({
    required this.fn,
    required this.args,
    required this.field,
    required this.value,
    required this.tolerance,
  });

  final String fn;
  final Map<String, dynamic> args;
  final String field;
  final double value;
  final double tolerance;

  factory VerifyClaim.fromJson(Json j) => VerifyClaim(
        fn: jStr(j, 'fn'),
        args: Map<String, dynamic>.from((j['args'] as Map?) ?? const {}),
        field: jStr(j, 'field'),
        value: jDouble(j, 'value'),
        tolerance: jDouble(j, 'tol', 0.001),
      );
}
