import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/progress_models.dart';
import '../domain/repositories/repositories.dart';

/// Guarda el progreso como un único JSON en el almacenamiento local.
/// Sin cuentas ni servidor: el MVP funciona completamente sin conexión.
class PrefsProgressRepository implements ProgressRepository {
  PrefsProgressRepository(this._prefs);

  static const String key = 'inferencia_progress_v1';
  final SharedPreferences _prefs;

  @override
  ProgressState read() {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const ProgressState();
    try {
      return ProgressState.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
    } catch (_) {
      // Un JSON dañado no debe impedir abrir la app.
      return const ProgressState();
    }
  }

  @override
  Future<void> write(ProgressState state) =>
      _prefs.setString(key, jsonEncode(state.toJson()));

  @override
  Future<void> clear() => _prefs.remove(key);
}

/// Implementación en memoria para pruebas.
class InMemoryProgressRepository implements ProgressRepository {
  InMemoryProgressRepository([this._state = const ProgressState()]);
  ProgressState _state;

  @override
  ProgressState read() => _state;

  @override
  Future<void> write(ProgressState state) async => _state = state;

  @override
  Future<void> clear() async => _state = const ProgressState();
}
