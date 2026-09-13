import 'dart:convert';

import '../domain/models/case_models.dart';
import '../domain/models/course_content.dart';
import '../domain/models/course_models.dart';
import '../domain/models/exercise_models.dart';
import '../domain/models/json_utils.dart';
import '../domain/models/lab_models.dart';
import '../domain/models/reference_models.dart';

/// Convierte los archivos JSON del curso en el modelo de dominio.
///
/// Separado del repositorio para poder probarlo con archivos leídos del
/// disco, sin necesidad del `AssetBundle` de Flutter.
class ContentParser {
  const ContentParser();

  static const List<String> files = [
    'modules.json',
    'exercises.json',
    'cases.json',
    'labs.json',
    'misconceptions.json',
    'glossary.json',
  ];

  CourseContent parse(Map<String, String> sources) {
    Json doc(String name) {
      final raw = sources[name];
      if (raw == null) throw StateError('Falta el archivo de contenido $name');
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    }

    final modulesDoc = doc('modules.json');
    return CourseContent(
      modules: jList(modulesDoc, 'modules').map(CourseModule.fromJson).toList(),
      careers: jStrings(modulesDoc, 'careers'),
      exercises: jList(doc('exercises.json'), 'exercises').map(Exercise.fromJson).toList(),
      cases: jList(doc('cases.json'), 'cases').map(CaseStudy.fromJson).toList(),
      labs: jList(doc('labs.json'), 'labs').map(Lab.fromJson).toList(),
      misconceptions:
          jList(doc('misconceptions.json'), 'misconceptions').map(Misconception.fromJson).toList(),
      glossary: jList(doc('glossary.json'), 'glossary').map(GlossaryTerm.fromJson).toList(),
    );
  }
}
