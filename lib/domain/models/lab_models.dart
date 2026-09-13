import 'exercise_models.dart';
import 'json_utils.dart';

/// Experimento con el ciclo Predice → Simula → Explica.
///
/// La predicción se registra antes de simular y no resta puntos: sirve para
/// que el estudiante se comprometa con una intuición que la simulación
/// confirmará o contradirá. La conclusión permanece oculta hasta que el
/// estudiante ha simulado lo suficiente (`minRuns`).
class LabExperiment {
  const LabExperiment({
    required this.id,
    required this.labId,
    required this.title,
    required this.question,
    required this.predictions,
    required this.instructions,
    required this.reveal,
    required this.minRuns,
    this.tag,
  });

  final String id;
  final String labId;
  final String title;
  final String question;
  final List<ChoiceOption> predictions;
  final String instructions;
  final String reveal;
  final int minRuns;
  final String? tag;

  factory LabExperiment.fromJson(Json j, String labId) => LabExperiment(
        id: jStr(j, 'id'),
        labId: labId,
        title: jStr(j, 'title'),
        question: jStr(j, 'question'),
        predictions: jList(j, 'predictions').map(ChoiceOption.fromJson).toList(),
        instructions: jStr(j, 'instructions'),
        reveal: jStr(j, 'reveal'),
        minRuns: jInt(j, 'minRuns', 3),
        tag: jStrOrNull(j, 'tag'),
      );
}

class Lab {
  const Lab({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.experiments,
  });

  final String id;
  final String moduleId;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final List<LabExperiment> experiments;

  factory Lab.fromJson(Json j) {
    final id = jStr(j, 'id');
    return Lab(
      id: id,
      moduleId: jStr(j, 'module'),
      title: jStr(j, 'title'),
      subtitle: jStr(j, 'subtitle'),
      description: jStr(j, 'description'),
      icon: jStr(j, 'icon'),
      experiments: jList(j, 'experiments').map((e) => LabExperiment.fromJson(e, id)).toList(),
    );
  }
}
