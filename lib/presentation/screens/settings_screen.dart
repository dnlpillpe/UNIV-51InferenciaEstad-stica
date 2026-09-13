import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/app_logo.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/models/progress_models.dart';
import '../providers/app_providers.dart';
import '../widgets/content_builder.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final notifier = ref.read(progressProvider.notifier);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ContentBuilder(builder: (context, content) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            Text('Tema', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            SegmentedButton<AppThemePreference>(
              segments: const [
                ButtonSegment(value: AppThemePreference.system, label: Text('Sistema')),
                ButtonSegment(value: AppThemePreference.light, label: Text('Claro')),
                ButtonSegment(value: AppThemePreference.dark, label: Text('Oscuro')),
              ],
              selected: {p.theme},
              onSelectionChanged: (s) => notifier.setTheme(s.first),
            ),
            const SizedBox(height: 20),
            Text('Tu carrera', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Ordena los casos profesionales para mostrar primero los de tu carrera.', style: t.bodySmall),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: const InputDecoration(),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: p.career,
                  isExpanded: true,
                  isDense: true,
                  hint: const Text('Sin especificar'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Sin especificar')),
                    for (final c in content.careers) DropdownMenuItem<String?>(value: c, child: Text(c)),
                  ],
                  onChanged: notifier.setCareer,
                ),
              ),
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.coral),
              icon: const Icon(Icons.delete_sweep_rounded),
              label: const Text('Borrar mi progreso'),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (d) => AlertDialog(
                    title: const Text('¿Borrar el progreso?'),
                    content: const Text('Se eliminarán lecciones, ejercicios, experimentos, casos y confusiones registradas. '
                        'Tus ajustes se conservan.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
                      FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Borrar')),
                    ],
                  ),
                );
                if (ok == true) notifier.resetLearning();
              },
            ),
            const SizedBox(height: 32),
            const Center(child: AppLogo(size: 72)),
            const SizedBox(height: 10),
            Center(child: Text('Inferencia Estadística 1.0.0', style: t.titleSmall)),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Educational Mobile Apps Factory · funciona sin conexión; tus datos quedan en este dispositivo.',
                style: t.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${content.modules.length} módulos · ${content.lessonCount} lecciones · ${content.exercises.length} ejercicios · '
                '${content.experimentCount} experimentos · ${content.cases.length} casos',
                style: t.labelSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      }),
    );
  }
}
