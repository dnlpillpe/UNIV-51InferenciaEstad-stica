import 'json_utils.dart';

/// Confusión conceptual catalogada. Cada distractor la declara con `tag`.
class Misconception {
  const Misconception({
    required this.id,
    required this.name,
    required this.moduleId,
    required this.description,
    required this.correction,
    this.remedyLesson,
    this.remedyExperiment,
  });

  final String id;
  final String name;
  final String moduleId;
  final String description;
  final String correction;
  final String? remedyLesson;
  final String? remedyExperiment;

  factory Misconception.fromJson(Json j) => Misconception(
        id: jStr(j, 'id'),
        name: jStr(j, 'name'),
        moduleId: jStr(j, 'module'),
        description: jStr(j, 'description'),
        correction: jStr(j, 'correction'),
        remedyLesson: jStrOrNull(j, 'remedyLesson'),
        remedyExperiment: jStrOrNull(j, 'remedyExperiment'),
      );
}

class GlossaryTerm {
  const GlossaryTerm({
    required this.term,
    required this.definition,
    required this.moduleId,
    this.symbol,
    this.example,
  });

  final String term;
  final String definition;
  final String moduleId;
  final String? symbol;
  final String? example;

  factory GlossaryTerm.fromJson(Json j) => GlossaryTerm(
        term: jStr(j, 'term'),
        definition: jStr(j, 'definition'),
        moduleId: jStr(j, 'module'),
        symbol: jStrOrNull(j, 'symbol'),
        example: jStrOrNull(j, 'example'),
      );
}
