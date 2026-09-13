import '../stats/descriptive.dart';
import '../stats/random_source.dart';

/// Formas de población disponibles en la Máquina de muestras.
enum PopulationShape {
  normal('Simétrica', 'Estatura de estudiantes', 'cm'),
  uniform('Uniforme', 'Minuto de llegada al aula', 'min'),
  skewed('Asimétrica', 'Espera en ventanilla', 'min'),
  bimodal('Bimodal', 'Horas de estudio semanal', 'h');

  const PopulationShape(this.label, this.context, this.unit);
  final String label;
  final String context;
  final String unit;
}

/// Una población finita y concreta: sus N valores existen y se conocen.
///
/// Didácticamente es importante que la población sea un objeto visible con
/// μ y σ exactos: el estudiante ve el «mundo real» que la muestra intenta
/// adivinar, cosa que en la práctica profesional nunca ocurre.
class Population {
  Population._(this.shape, this.values)
      : mean = Descriptive.mean(values),
        sd = Descriptive.populationSd(values),
        min = Descriptive.minOf(values),
        max = Descriptive.maxOf(values);

  final PopulationShape shape;
  final List<double> values;
  final double mean;
  final double sd;
  final double min;
  final double max;

  int get size => values.length;

  factory Population.generate(PopulationShape shape, {int size = 5000, int seed = 2026}) {
    final rng = RandomSource(seed);
    final values = List<double>.generate(size, (_) => _draw(shape, rng));
    return Population._(shape, values);
  }

  static double _draw(PopulationShape shape, RandomSource rng) {
    switch (shape) {
      case PopulationShape.normal:
        return rng.nextNormal(165, 9);
      case PopulationShape.uniform:
        return rng.nextDouble() * 20;
      case PopulationShape.skewed:
        return 1 + rng.nextExponential(5);
      case PopulationShape.bimodal:
        final v = rng.nextBool(0.5) ? rng.nextNormal(4, 1.5) : rng.nextNormal(14, 2);
        return v < 0 ? 0 : v;
    }
  }

  double draw(RandomSource rng) => values[rng.nextInt(values.length)];

  /// Muestra aleatoria simple (con reposición; N es grande frente a n).
  List<double> sample(int n, RandomSource rng) =>
      List<double>.generate(n, (_) => draw(rng));
}
