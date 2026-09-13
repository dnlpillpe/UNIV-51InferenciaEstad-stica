/// Utilidades mínimas de lectura de JSON, sin dependencias externas.
typedef Json = Map<String, dynamic>;

String jStr(Json j, String k, [String fallback = '']) {
  final v = j[k];
  return v is String ? v : fallback;
}

String? jStrOrNull(Json j, String k) {
  final v = j[k];
  return v is String && v.isNotEmpty ? v : null;
}

int jInt(Json j, String k, [int fallback = 0]) {
  final v = j[k];
  return v is num ? v.round() : fallback;
}

double jDouble(Json j, String k, [double fallback = 0]) {
  final v = j[k];
  return v is num ? v.toDouble() : fallback;
}

double? jDoubleOrNull(Json j, String k) {
  final v = j[k];
  return v is num ? v.toDouble() : null;
}

bool jBool(Json j, String k, [bool fallback = false]) {
  final v = j[k];
  return v is bool ? v : fallback;
}

List<Json> jList(Json j, String k) {
  final v = j[k];
  if (v is! List) return const [];
  return v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
}

List<String> jStrings(Json j, String k) {
  final v = j[k];
  if (v is! List) return const [];
  return v.whereType<String>().toList();
}

/// Convierte "#RRGGBB" en un entero ARGB opaco.
int parseHexColor(String hex, [int fallback = 0xFF243B6B]) {
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  return int.tryParse(h, radix: 16) ?? fallback;
}
