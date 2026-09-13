import '../stats/descriptive.dart';
import '../stats/random_source.dart';

/// Prueba por permutación («barajar etiquetas») para dos grupos.
///
/// Si el tratamiento no tuviera efecto, las etiquetas A/B serían arbitrarias:
/// barajarlas genera diferencias que solo se deben al azar de la asignación.
class PermutationTest {
  PermutationTest(this.groupA, this.groupB)
      : observed = Descriptive.mean(groupA) - Descriptive.mean(groupB);

  final List<double> groupA;
  final List<double> groupB;
  final double observed;

  /// Una permutación: diferencia de medias tras barajar las etiquetas.
  double shuffleOnce(RandomSource rng) {
    final pooled = [...groupA, ...groupB];
    rng.shuffle(pooled);
    final a = pooled.sublist(0, groupA.length);
    final b = pooled.sublist(groupA.length);
    return Descriptive.mean(a) - Descriptive.mean(b);
  }

  List<double> run(int k, RandomSource rng) =>
      List<double>.generate(k, (_) => shuffleOnce(rng));

  /// p-valor bilateral: proporción de permutaciones al menos tan extremas.
  double pValue(List<double> diffs) {
    if (diffs.isEmpty) return double.nan;
    final obs = observed.abs() - 1e-12;
    return diffs.where((d) => d.abs() >= obs).length / diffs.length;
  }
}
