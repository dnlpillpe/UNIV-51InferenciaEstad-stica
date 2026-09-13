import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'domain/models/progress_models.dart';
import 'presentation/providers/app_providers.dart';
import 'presentation/screens/home_shell.dart';
import 'presentation/screens/onboarding_screen.dart';

class InferenciaApp extends ConsumerWidget {
  const InferenciaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(progressProvider.select((p) => p.theme));
    final onboarded = ref.watch(progressProvider.select((p) => p.onboardingDone));
    return MaterialApp(
      title: 'Inferencia Estadística',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (theme) {
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        AppThemePreference.system => ThemeMode.system,
      },
      home: onboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }
}
