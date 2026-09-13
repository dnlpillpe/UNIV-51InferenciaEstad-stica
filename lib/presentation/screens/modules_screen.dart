import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/engine/mastery_engine.dart';
import '../providers/app_providers.dart';
import '../widgets/content_builder.dart';
import '../widgets/nav.dart';
import 'module_detail_screen.dart';

/// La ruta del curso: cinco módulos en orden, con su dominio.
/// Ningún módulo se bloquea; si falta la base se muestra una recomendación.
class ModulesScreen extends ConsumerWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    final mastery = ref.read(masteryEngineProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ruta del curso')),
      body: ContentBuilder(builder: (context, content) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: content.modules.length,
          itemBuilder: (context, i) {
            final m = content.modules[i];
            final mm = mastery.forModule(m, content, progress);
            final color = Color(m.colorValue);
            final prevId = m.recommendedAfter;
            final prev = prevId == null ? null : content.module(prevId);
            final prevWeak = prev != null && !mastery.forModule(prev, content, progress).isCompetent;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(children: [
                      Expanded(child: Container(width: 3, color: i == 0 ? Colors.transparent : color.withValues(alpha: 0.35))),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: mm.level == MasteryLevel.notStarted ? Theme.of(context).scaffoldBackgroundColor : color,
                          border: Border.all(color: color, width: 3),
                        ),
                      ),
                      Expanded(child: Container(width: 3, color: i == content.modules.length - 1 ? Colors.transparent : color.withValues(alpha: 0.35))),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: AppCard(
                        onTap: () => pushScreen(context, ModuleDetailScreen(moduleId: m.id)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              ModuleBadge(number: m.number, color: color, icon: iconFor(m.icon)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('MÓDULO ${m.number}',
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                  Text(m.title, style: Theme.of(context).textTheme.titleMedium),
                                ]),
                              ),
                              ProgressRing(value: mm.total, color: color, size: 46, stroke: 5),
                            ]),
                            const SizedBox(height: 10),
                            Text('«${m.keyQuestion}»',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                            const SizedBox(height: 10),
                            Wrap(spacing: 6, runSpacing: 6, children: [
                              Pill(mm.level.label, color: color),
                              Pill('${m.lessons.length} lecciones', color: Colors.blueGrey),
                              Pill('${mm.practiceTotal} actividades', color: Colors.blueGrey),
                            ]),
                            if (prevWeak && mm.level == MasteryLevel.notStarted) ...[
                              const SizedBox(height: 10),
                              Text('Recomendado después de «${prev!.title}»',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
