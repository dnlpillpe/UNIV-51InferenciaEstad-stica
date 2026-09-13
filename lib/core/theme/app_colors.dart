import 'package:flutter/material.dart';

/// Paleta de la app.
///
/// La identidad visual sale del propio curso: el índigo profundo es el
/// «mundo desconocido» de la población; el ámbar es el color de la
/// confianza (bandas de los intervalos); el coral marca el rechazo
/// (colas del p-valor, intervalos que fallan); el verde azulado, lo que
/// acierta. Estos significados se mantienen en todos los gráficos.
class AppColors {
  AppColors._();

  // Marca
  static const Color indigo = Color(0xFF22306B);
  static const Color indigoDeep = Color(0xFF141C45);
  static const Color indigoSoft = Color(0xFF3D4C8F);
  static const Color amber = Color(0xFFF2A541);
  static const Color coral = Color(0xFFE5484D);
  static const Color teal = Color(0xFF1F9E89);
  static const Color violet = Color(0xFF6C4AB6);

  // Fondos
  static const Color paper = Color(0xFFF6F4EE);
  static const Color paperDark = Color(0xFF0E1330);
  static const Color surfaceDark = Color(0xFF182045);

  // Neutros de gráfico
  static const Color population = Color(0xFF8A94B8);
  static const Color grid = Color(0x1A22306B);

  // Módulos (coinciden con modules.json)
  static const Color m1 = Color(0xFF2E86AB);
  static const Color m2 = Color(0xFF6C4AB6);
  static const Color m3 = Color(0xFFE09F3E);
  static const Color m4 = Color(0xFFD1495B);
  static const Color m5 = Color(0xFF2A9D8F);

  static Color moduleColor(int colorValue) => Color(colorValue);
}

/// Colores semánticos de gráficos, adaptados al brillo del tema.
@immutable
class ChartPalette {
  const ChartPalette({
    required this.ink,
    required this.muted,
    required this.grid,
    required this.population,
    required this.sample,
    required this.sampling,
    required this.parameter,
    required this.estimate,
    required this.confidence,
    required this.reject,
    required this.accept,
    required this.surface,
  });

  final Color ink;
  final Color muted;
  final Color grid;
  final Color population;
  final Color sample;
  final Color sampling;

  /// μ o p: el valor verdadero (línea del parámetro).
  final Color parameter;

  /// x̄ o p̂: la estimación.
  final Color estimate;

  /// Intervalos que capturan, bandas de confianza.
  final Color confidence;

  /// Regiones de rechazo, p-valor, intervalos que fallan.
  final Color reject;

  /// Aciertos, decisiones correctas.
  final Color accept;
  final Color surface;

  static ChartPalette of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? _dark : _light;
  }

  static const ChartPalette _light = ChartPalette(
    ink: Color(0xFF1B2250),
    muted: Color(0xFF6B7194),
    grid: Color(0x2222306B),
    population: AppColors.population,
    sample: AppColors.m1,
    sampling: AppColors.violet,
    parameter: AppColors.indigo,
    estimate: Color(0xFFD9861C),
    confidence: AppColors.amber,
    reject: AppColors.coral,
    accept: AppColors.teal,
    surface: Colors.white,
  );

  static const ChartPalette _dark = ChartPalette(
    ink: Color(0xFFE8EAF6),
    muted: Color(0xFF9FA6CC),
    grid: Color(0x33E8EAF6),
    population: Color(0xFF7D88B3),
    sample: Color(0xFF5DB3D8),
    sampling: Color(0xFFA78BFA),
    parameter: Color(0xFFF1F3FF),
    estimate: AppColors.amber,
    confidence: AppColors.amber,
    reject: Color(0xFFFF6B6F),
    accept: Color(0xFF3CCBB0),
    surface: AppColors.surfaceDark,
  );
}
