import 'dart:io';

import 'package:inferencia_estadistica/data/content_parser.dart';
import 'package:inferencia_estadistica/domain/models/course_content.dart';
import 'package:inferencia_estadistica/domain/repositories/repositories.dart';

/// Lee el contenido directamente del disco (las pruebas corren en la raíz).
CourseContent loadTestContent() {
  final sources = {
    for (final f in ContentParser.files) f: File('assets/content/$f').readAsStringSync(),
  };
  return const ContentParser().parse(sources);
}

/// Repositorio síncrono para pruebas de widgets (evita E/S asíncrona real).
class FileContentRepository implements ContentRepository {
  final CourseContent _content = loadTestContent();

  @override
  Future<CourseContent> load() => Future.value(_content);
}
