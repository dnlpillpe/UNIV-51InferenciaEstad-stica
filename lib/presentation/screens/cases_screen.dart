import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/common_widgets.dart';
import '../providers/app_providers.dart';
import '../widgets/content_builder.dart';
import '../widgets/open_target.dart';

/// Catálogo de casos profesionales, filtrable por carrera.
class CasesScreen extends ConsumerStatefulWidget {
  const CasesScreen({super.key});

  @override
  ConsumerState<CasesScreen> createState() => _CasesScreenState();
}

class _CasesScreenState extends ConsumerState<CasesScreen> {
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Casos profesionales')),
      body: ContentBuilder(builder: (context, content) {
        final careers = content.cases.map((c) => c.career).toSet().toList();
        final list = content.cases.where((c) => _filter == null || c.career == _filter).toList()
          ..sort((a, b) => (a.career == progress.career ? 0 : 1).compareTo(b.career == progress.career ? 0 : 1));
        final t = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Text('Cada caso reproduce una decisión real de una carrera. La app hace los cálculos; tú eliges el '
                'procedimiento, interpretas y asumes el riesgo.', style: t.bodyMedium),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(label: const Text('Todas'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
                ),
                for (final c in careers)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(label: Text(c), selected: _filter == c, onSelected: (v) => setState(() => _filter = v ? c : null)),
                  ),
              ]),
            ),
            const SizedBox(height: 12),
            for (final cs in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => OpenTarget.caseStudy(context, content, cs.id),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.m5.withValues(alpha: 0.14),
                      child: Icon(iconFor(cs.icon), color: AppColors.m5),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(cs.career.toUpperCase(), style: t.labelSmall?.copyWith(letterSpacing: 1, fontWeight: FontWeight.w800, color: AppColors.m5)),
                        Text(cs.title, style: t.titleMedium),
                        const SizedBox(height: 4),
                        Text(cs.question, style: t.bodySmall),
                        const SizedBox(height: 8),
                        Wrap(spacing: 6, runSpacing: 6, children: [
                          Pill('${cs.steps.length} pasos', color: Colors.blueGrey),
                          Pill('Dificultad ${'●' * cs.difficulty}', color: Colors.blueGrey),
                          if (progress.cases[cs.id] != null)
                            Pill('Mejor: ${(progress.cases[cs.id]! * 100).round()} %', color: AppColors.teal, icon: Icons.check_rounded),
                          if (cs.career == progress.career) const Pill('Tu carrera', color: AppColors.m3),
                        ]),
                      ]),
                    ),
                  ]),
                ),
              ),
          ],
        );
      }),
    );
  }
}
