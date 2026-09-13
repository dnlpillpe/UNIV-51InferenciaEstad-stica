import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inferencia_estadistica/app.dart';
import 'package:inferencia_estadistica/data/prefs_progress_repository.dart';
import 'package:inferencia_estadistica/domain/models/progress_models.dart';
import 'package:inferencia_estadistica/presentation/providers/app_providers.dart';
import 'package:inferencia_estadistica/presentation/screens/lab_screen.dart';
import 'package:inferencia_estadistica/presentation/screens/lesson_screen.dart';

import '../support/test_content.dart';

Widget _app(ProgressState initial) => ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(FileContentRepository()),
        progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository(initial)),
      ],
      child: const InferenciaApp(),
    );

Widget _screen(Widget child) => ProviderScope(
      overrides: [
        contentRepositoryProvider.overrideWithValue(FileContentRepository()),
        progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository(const ProgressState(onboardingDone: true))),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  testWidgets('onboarding → inicio → calculadora', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const ProgressState()));
    await tester.pumpAndSettle();
    expect(find.text('La inferencia es un experimento imaginario'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('¿Qué estudias?'), findsOneWidget);
    await tester.ensureVisible(find.text('Economía'));
    await tester.tap(find.text('Economía'));
    await tester.pump();
    await tester.tap(find.text('Empezar'));
    await tester.pumpAndSettle();

    expect(find.text('Inferencia Estadística'), findsOneWidget);
    expect(find.text('SIGUIENTE LECCIÓN'), findsOneWidget);

    await tester.tap(find.text('Calculadora').last);
    await tester.pumpAndSettle();
    expect(find.text('Calculadora inferencial'), findsOneWidget);
    await tester.ensureVisible(find.text('Calcular'));
    await tester.tap(find.text('Calcular'));
    await tester.pumpAndSettle();
    expect(find.text('Cómo decirlo'), findsWidgets);
  });

  testWidgets('las cinco pestañas se abren sin errores', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(const ProgressState(onboardingDone: true)));
    await tester.pumpAndSettle();
    const titles = {
      'Ruta': 'Ruta del curso',
      'Laboratorios': 'Encuesta en Villa Muestra',
      'Calculadora': 'Calculadora inferencial',
      'Progreso': 'Tu progreso',
      'Inicio': 'Tu ruta',
    };
    for (final e in titles.entries) {
      await tester.tap(find.text(e.key).last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: e.key);
      expect(find.text(e.value), findsWidgets, reason: e.key);
    }
  });

  testWidgets('una lección exige responder la tarjeta de comprobación', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final lesson = loadTestContent().lesson('m1_l1')!;
    await tester.pumpWidget(_screen(LessonScreen(lesson: lesson)));
    await tester.pumpAndSettle();
    for (var i = 0; i < lesson.cards.length - 1; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
    }
    // La última tarjeta es de comprobación: el botón dice «Terminar» pero está desactivado.
    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Terminar'));
    expect(button.onPressed, isNull);
    await tester.ensureVisible(find.text('Un estadístico x̄ de la muestra'));
    await tester.tap(find.text('Un estadístico x̄ de la muestra'));
    await tester.pumpAndSettle();
    expect(find.text('Bien'), findsOneWidget);
  });

  testWidgets('experimento: predecir, simular y ver la conclusión', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final lab = loadTestContent().lab('lab3')!;
    await tester.pumpWidget(_screen(LabScreen(lab: lab)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alrededor de 95'));
    await tester.pump();
    await tester.tap(find.text('Registrar predicción y simular'));
    await tester.pumpAndSettle();

    final run100 = find.text('×100');
    await tester.ensureVisible(run100);
    await tester.tap(run100);
    await tester.pumpAndSettle();

    final reveal = find.text('Ver la conclusión');
    await tester.ensureVisible(reveal);
    await tester.tap(reveal);
    await tester.pumpAndSettle();
    expect(find.text('Tu predicción se confirmó'), findsOneWidget);
  });
}
