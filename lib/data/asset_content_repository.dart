import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/models/course_content.dart';
import '../domain/repositories/repositories.dart';
import 'content_parser.dart';

/// Lee el contenido empaquetado en `assets/content/`.
///
/// Se usa `load` + `utf8.decode` en lugar de `loadString`: para archivos
/// grandes `loadString` decodifica en otro isolate, lo que no aporta nada
/// con estos tamaños y complica las pruebas de widgets.
class AssetContentRepository implements ContentRepository {
  AssetContentRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  CourseContent? _cache;

  @override
  Future<CourseContent> load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final sources = <String, String>{};
    for (final f in ContentParser.files) {
      final data = await _bundle.load('assets/content/$f');
      sources[f] = utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    }
    final content = const ContentParser().parse(sources);
    _cache = content;
    return content;
  }
}
