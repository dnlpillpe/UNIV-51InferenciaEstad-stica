import '../models/course_content.dart';
import '../models/progress_models.dart';
import '../models/reference_models.dart';

class DiagnosedMisconception {
  const DiagnosedMisconception(this.misconception, this.strength, this.occurrences);
  final Misconception misconception;

  /// Intensidad actual (con decaimiento y resoluciones descontadas).
  final double strength;
  final int occurrences;
}

/// Lee el historial de etiquetas y nombra las confusiones activas.
///
/// Cada error con etiqueta suma 1; cada acierto posterior en un ítem capaz
/// de detectar esa confusión resta 0,5. Los eventos pierden un 3 % de peso
/// por cada evento más reciente, así la foto refleja el presente.
class DiagnosisEngine {
  const DiagnosisEngine();

  static const double decay = 0.97;
  static const double activeThreshold = 0.6;

  Map<String, double> strengths(ProgressState p) {
    final out = <String, double>{};
    final events = p.tagEvents;
    for (var i = 0; i < events.length; i++) {
      final age = events.length - 1 - i;
      final w = events[i].weight * _pow(decay, age);
      out[events[i].tag] = (out[events[i].tag] ?? 0) + w;
    }
    return out;
  }

  List<DiagnosedMisconception> active(CourseContent c, ProgressState p, {int limit = 5}) {
    final s = strengths(p);
    final counts = <String, int>{};
    for (final e in p.tagEvents) {
      if (e.weight > 0) counts[e.tag] = (counts[e.tag] ?? 0) + 1;
    }
    final list = <DiagnosedMisconception>[];
    s.forEach((tag, v) {
      final m = c.misconception(tag);
      if (m != null && v >= activeThreshold) {
        list.add(DiagnosedMisconception(m, v, counts[tag] ?? 0));
      }
    });
    list.sort((a, b) => b.strength.compareTo(a.strength));
    return list.take(limit).toList();
  }

  static double _pow(double b, int e) {
    var r = 1.0;
    for (var i = 0; i < e; i++) {
      r *= b;
      if (r < 1e-6) return 0;
    }
    return r;
  }
}
