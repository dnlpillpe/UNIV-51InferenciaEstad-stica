import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/common_widgets.dart';
import '../providers/app_providers.dart';
import '../widgets/content_builder.dart';
import '../widgets/nav.dart';
import 'cases_screen.dart';
import 'lab_screen.dart';

class LabsScreen extends ConsumerWidget {
  const LabsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Laboratorios')),
      body: ContentBuilder(builder: (context, content) {
        final t = Theme.of(context).textTheme;
        final doneTotal = content.labs.fold<int>(
            0, (s, l) => s + l.experiments.where((e) => progress.completedExperiments.contains(e.id)).length);
        final predicted = progress.predictions.values.where((v) => v).length;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text('Cada experimento sigue el ciclo Predice → Simula → Explica. '
                'Tu predicción no resta puntos: sirve para descubrir qué intuiciones hay que corregir.', style: t.bodyMedium),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: StatTile(label: 'Experimentos completados', value: '$doneTotal / ${content.experimentCount}')),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'Predicciones acertadas', value: progress.predictions.isEmpty ? '—' : '$predicted / ${progress.predictions.length}')),
            ]),
            const SizedBox(height: 14),
            for (final lab in content.labs) ...[
              Builder(builder: (context) {
                final m = content.module(lab.moduleId);
                final color = m == null ? Colors.indigo : Color(m.colorValue);
                final done = lab.experiments.where((e) => progress.completedExperiments.contains(e.id)).length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    onTap: () => pushScreen(context, LabScreen(lab: lab)),
                    child: Row(children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [color, Color.lerp(color, Colors.black, 0.3)!]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(iconFor(lab.icon), color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('MÓDULO ${m?.number ?? ''}', style: t.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800, letterSpacing: 1)),
                          Text(lab.title, style: t.titleMedium),
                          Text(lab.subtitle, style: t.bodySmall),
                          const SizedBox(height: 8),
                          ThinProgress(value: done / lab.experiments.length, color: color),
                        ]),
                      ),
                    ]),
                  ),
                );
              }),
            ],
            const SectionTitle('Casos profesionales'),
            AppCard(
              onTap: () => pushScreen(context, const CasesScreen()),
              child: Row(children: [
                const Icon(Icons.work_rounded, size: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${content.cases.length} casos de ${content.cases.map((c) => c.career).toSet().length} carreras', style: t.titleMedium),
                    Text('Decide como lo harías en tu trabajo', style: t.bodySmall),
                  ]),
                ),
                const Icon(Icons.chevron_right_rounded),
              ]),
            ),
          ],
        );
      }),
    );
  }
}
