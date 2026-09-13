import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/engine/mastery_engine.dart';
import '../providers/app_providers.dart';
import '../widgets/content_builder.dart';
import '../widgets/misconception_chip.dart';
import '../widgets/nav.dart';
import 'module_detail_screen.dart';

/// Progreso: dominio por módulo, confusiones activas y dos indicadores
/// propios del curso — acierto ciego e intuición inicial.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Tu progreso')),
      body: ContentBuilder(builder: (context, content) {
        final t = Theme.of(context).textTheme;
        final mastery = ref.read(masteryEngineProvider);
        final overall = mastery.overall(content, p);
        final active = ref.read(diagnosisEngineProvider).active(content, p, limit: 6);
        final blindRate = p.decisionAttempts == 0 ? null : p.blindHits / p.decisionAttempts;
        final predTotal = p.predictions.length;
        final predOk = p.predictions.values.where((v) => v).length;
        final attempts = p.exercises.values.fold<int>(0, (s, r) => s + r.attempts);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  ProgressRing(value: overall, color: AppColors.amber, size: 86, stroke: 9),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Dominio del curso', style: t.titleMedium),
                      const SizedBox(height: 4),
                      Text('Dominio = 15 % lecciones + 15 % experimentos + 70 % práctica. Competente: 70 % de dominio y 70 % en la práctica.',
                          style: t.bodySmall),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: StatTile(label: 'Lecciones', value: '${p.completedLessons.length} / ${content.lessonCount}')),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'Experimentos', value: '${p.completedExperiments.length} / ${content.experimentCount}')),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'Casos', value: '${p.cases.length} / ${content.cases.length}')),
            ]),
            const SectionTitle('Dominio por módulo'),
            for (final m in content.modules)
              Builder(builder: (context) {
                final mm = mastery.forModule(m, content, p);
                final color = Color(m.colorValue);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => pushScreen(context, ModuleDetailScreen(moduleId: m.id)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        ModuleBadge(number: m.number, color: color, size: 28),
                        const SizedBox(width: 10),
                        Expanded(child: Text(m.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                        Pill(mm.level.label, color: mm.level == MasteryLevel.notStarted ? Colors.blueGrey : color),
                      ]),
                      const SizedBox(height: 10),
                      ThinProgress(value: mm.total, color: color, height: 8),
                      const SizedBox(height: 6),
                      Text(
                        'Práctica ${Fmt.percent(mm.practice, 0)} (${mm.practiceDone}/${mm.practiceTotal}) · '
                        'Lecciones ${Fmt.percent(mm.lessons, 0)} · Experimentos ${Fmt.percent(mm.experiments, 0)}',
                        style: t.bodySmall,
                      ),
                    ]),
                  ),
                );
              }),
            const SectionTitle('Confusiones activas'),
            if (active.isEmpty)
              const Callout(
                text: 'No hay confusiones activas. Aparecen cuando eliges distractores que delatan una idea equivocada, '
                    'y se desactivan al responder bien ítems que podrían detectarlas.',
                icon: Icons.verified_rounded,
                color: AppColors.teal,
              )
            else ...[
              for (final d in active)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: MisconceptionChip(d.misconception.id)),
                          Text('${d.occurrences}×', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                        ]),
                        const SizedBox(height: 6),
                        ThinProgress(value: (d.strength / 4).clamp(0.0, 1.0), color: AppColors.coral),
                        const SizedBox(height: 6),
                        Text(d.misconception.correction, style: t.bodySmall),
                      ]),
                    ),
                  ),
                ),
            ],
            const SectionTitle('Indicadores de aprendizaje'),
            Row(children: [
              Expanded(
                child: StatTile(
                  label: 'Acierto ciego',
                  value: blindRate == null ? '—' : Fmt.percent(blindRate, 0),
                  caption: 'decisiones bien con la razón mal',
                  color: const Color(0xFFC27D12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StatTile(
                  label: 'Intuición inicial',
                  value: predTotal == 0 ? '—' : '$predOk / $predTotal',
                  caption: 'predicciones acertadas',
                  color: AppColors.violet,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              'El acierto ciego mide cuántas veces eligió bien sin saber por qué: con 60 % de puntaje por decisión y 40 % por justificación, '
              'solo se alcanza el 70 % de dominio si las razones también son correctas. La intuición inicial compara tus predicciones '
              'con lo que mostraron las simulaciones; errar ahí es normal y útil.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: StatTile(label: 'Respuestas enviadas', value: '$attempts')),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'Días con actividad', value: '${p.activeDays.length}')),
            ]),
          ],
        );
      }),
    );
  }
}
