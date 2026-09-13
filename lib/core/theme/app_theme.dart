import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.indigo,
      brightness: b,
      primary: dark ? const Color(0xFFB8C2FF) : AppColors.indigo,
      secondary: AppColors.amber,
      tertiary: AppColors.teal,
      error: AppColors.coral,
      // La superficie coincide con el fondo: las barras superiores se funden con
      // él y las tarjetas se distinguen por su propio color (cardTheme).
      surface: dark ? AppColors.paperDark : AppColors.paper,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: b,
      scaffoldBackgroundColor: dark ? AppColors.paperDark : AppColors.paper,
      visualDensity: VisualDensity.standard,
    );
    final text = base.textTheme.apply(
      bodyColor: dark ? const Color(0xFFE8EAF6) : const Color(0xFF1B2250),
      displayColor: dark ? const Color(0xFFF1F3FF) : const Color(0xFF141C45),
    );
    return base.copyWith(
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        bodyLarge: text.bodyLarge?.copyWith(height: 1.45),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.45),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: dark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: dark ? const Color(0x22FFFFFF) : const Color(0x1422306B)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? AppColors.surfaceDark : Colors.white,
        indicatorColor: AppColors.amber.withValues(alpha: dark ? 0.35 : 0.30),
        labelTextStyle: WidgetStatePropertyAll(
          text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        activeTrackColor: dark ? AppColors.amber : AppColors.indigo,
        thumbColor: AppColors.amber,
        overlayColor: AppColors.amber.withValues(alpha: 0.2),
        valueIndicatorColor: AppColors.indigoDeep,
      ),
      dividerTheme: DividerThemeData(
        color: dark ? const Color(0x22FFFFFF) : const Color(0x1422306B),
        space: 1,
      ),
    );
  }
}
