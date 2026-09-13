import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/app_logo.dart';
import '../../core/theme/app_colors.dart';
import '../charts/density_painter.dart';
import '../charts/lesson_visuals.dart';
import '../providers/app_providers.dart';
import '../widgets/content_builder.dart';

/// Tres pantallas: la promesa, el método y la carrera del estudiante.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;
  String? _career;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (_index < 2) {
      _page.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
    } else {
      ref.read(progressProvider.notifier).finishOnboarding(career: _career);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: AppColors.indigoDeep,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(() => _index = i),
                children: [
                  _Page(
                    top: const AppLogo(size: 116),
                    title: 'La inferencia es un experimento imaginario',
                    body: '«Si repitiera el muestreo mil veces…» Casi ningún curso te deja hacerlo. '
                        'Aquí sí: extraes miles de muestras, construyes cien intervalos y simulas el '
                        'mundo donde H0 es cierta. Ves de dónde salen el margen de error y el p-valor.',
                  ),
                  _Page(
                    top: const _MethodSteps(),
                    title: 'Predice, simula, decide',
                    body: 'Cada laboratorio empieza con una predicción tuya. Luego simulas y comparas. '
                        'Los ejercicios detectan qué confusión tienes —no solo si fallaste— y los casos '
                        'profesionales te piden decidir y asumir el riesgo, como en tu futuro trabajo.',
                  ),
                  _CareerPage(
                    selected: _career,
                    onSelect: (c) => setState(() => _career = c),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _index ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.amber : Colors.white24,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: AppColors.amber, foregroundColor: AppColors.indigoDeep),
                    onPressed: _next,
                    child: Text(_index < 2 ? 'Siguiente' : 'Empezar', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.indigoDeep)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.top, required this.title, required this.body});
  final Widget top;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: top),
          const SizedBox(height: 36),
          Text(title, style: t.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Text(body, style: t.bodyLarge?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _MethodSteps extends StatelessWidget {
  const _MethodSteps();

  @override
  Widget build(BuildContext context) {
    const pal = ChartPalette(
      ink: Colors.white,
      muted: Colors.white60,
      grid: Colors.white24,
      population: Colors.white54,
      sample: AppColors.m1,
      sampling: AppColors.violet,
      parameter: Colors.white,
      estimate: AppColors.amber,
      confidence: AppColors.amber,
      reject: AppColors.coral,
      accept: AppColors.teal,
      surface: AppColors.indigoDeep,
    );
    return Column(
      children: [
        SizedBox(
          height: 130,
          child: CustomPaint(
            size: const Size(double.infinity, 130),
            painter: DensityPainter(
              palette: pal,
              regions: [
                ShadeRegion(-1.96, 1.96, AppColors.amber.withValues(alpha: 0.55)),
                ShadeRegion(1.96, 4, AppColors.coral.withValues(alpha: 0.7)),
                ShadeRegion(-4, -1.96, AppColors.coral.withValues(alpha: 0.7)),
              ],
              observed: 2.3,
              observedLabel: 'tu dato',
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final (i, s) in [(Icons.lightbulb_rounded, 'Predice'), (Icons.casino_rounded, 'Simula'), (Icons.gavel_rounded, 'Decide')])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(children: [
                  CircleAvatar(backgroundColor: Colors.white12, child: Icon(i, color: AppColors.amber)),
                  const SizedBox(height: 6),
                  Text(s, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ]),
              ),
          ],
        ),
      ],
    );
  }
}

class _CareerPage extends StatelessWidget {
  const _CareerPage({required this.selected, required this.onSelect});
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ContentBuilder(
      builder: (context, content) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 40, 28, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Qué estudias?', style: t.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(
              'Priorizaremos los casos profesionales de tu carrera. Es opcional y puedes cambiarlo en Ajustes.',
              style: t.bodyLarge?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in content.careers)
                  ChoiceChip(
                    label: Text(c),
                    selected: selected == c,
                    onSelected: (v) => onSelect(v ? c : null),
                    selectedColor: AppColors.amber,
                    backgroundColor: Colors.white10,
                    labelStyle: TextStyle(
                      color: selected == c ? AppColors.indigoDeep : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
              ],
            ),
            const SizedBox(height: 26),
            const _Tiny(),
          ],
        ),
      ),
    );
  }
}

class _Tiny extends StatelessWidget {
  const _Tiny();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.9,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(12),
        child: Theme(
          data: ThemeData(brightness: Brightness.light, useMaterial3: true),
          child: const LessonVisual('ci_rain_mini'),
        ),
      ),
    );
  }
}
