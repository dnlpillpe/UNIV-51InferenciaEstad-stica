import 'dart:math' as math;

/// Formato numérico en español: coma decimal y espacio fino para miles
/// («1 068», «0,0357», «33,0 %»).
class Fmt {
  Fmt._();

  static String number(double v, [int decimals = 2]) {
    if (v.isNaN) return '—';
    if (v.isInfinite) return v > 0 ? '∞' : '−∞';
    final neg = v < 0;
    final fixed = v.abs().toStringAsFixed(decimals);
    final parts = fixed.split('.');
    final intPart = _groupThousands(parts[0]);
    final out = parts.length > 1 ? '$intPart,${parts[1]}' : intPart;
    final isZero = double.tryParse(fixed) == 0;
    return (neg && !isZero) ? '−$out' : out;
  }

  static String integer(num v) =>
      (v < 0 ? '−' : '') + _groupThousands(v.round().abs().toString());

  static String _groupThousands(String digits) {
    if (digits.length <= 4) return digits;
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) b.write(' ');
      b.write(digits[i]);
    }
    return b.toString();
  }

  /// Proporción → porcentaje: 0,33 → «33,0 %».
  static String percent(double p, [int decimals = 1]) => '${number(p * 100, decimals)} %';

  /// p-valores con precisión útil y sin falsos ceros.
  static String pValue(double p) {
    if (p.isNaN) return '—';
    if (p < 0.0001) return '< 0,0001';
    if (p < 0.001) return number(p, 4);
    return number(p, p < 0.1 ? 4 : 3);
  }

  /// Decimales automáticos según la magnitud (para ejes y resultados).
  static String auto(double v) {
    final a = v.abs();
    if (a == 0) return '0';
    if (a >= 1000) return number(v, 0);
    if (a >= 100) return number(v, 1);
    if (a >= 10) return number(v, 2);
    if (a >= 1) return number(v, 2);
    if (a >= 0.01) return number(v, 3);
    return number(v, 4);
  }

  /// Interpreta texto escrito por el estudiante: acepta «0,5», «0.5», «1 068».
  static double? parse(String raw) {
    var s = raw.trim().replaceAll(' ', '').replaceAll(' ', '').replaceAll('−', '-');
    if (s.isEmpty) return null;
    if (s.contains(',') && s.contains('.')) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '.');
    }
    if (s.endsWith('%')) {
      final v = double.tryParse(s.substring(0, s.length - 1));
      return v == null ? null : v / 100;
    }
    return double.tryParse(s);
  }

  /// Marcas «bonitas» para un eje entre min y max.
  static List<double> niceTicks(double min, double max, [int target = 5]) {
    if (!(max > min)) return [min];
    final span = max - min;
    final raw = span / target;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final norm = raw / mag;
    final step = (norm < 1.5 ? 1 : norm < 3 ? 2 : norm < 7 ? 5 : 10) * mag;
    final start = (min / step).ceil() * step;
    final ticks = <double>[];
    for (var v = start; v <= max + step * 1e-6; v += step) {
      ticks.add(double.parse(v.toStringAsFixed(10)));
    }
    return ticks;
  }
}
