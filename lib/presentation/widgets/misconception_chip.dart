import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/app_providers.dart';
import 'open_target.dart';

/// Etiqueta de confusión: al tocarla explica la confusión y ofrece el remedio.
class MisconceptionChip extends ConsumerWidget {
  const MisconceptionChip(this.tag, {super.key});
  final String tag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider).valueOrNull;
    final m = content?.misconception(tag);
    if (m == null) return const SizedBox.shrink();
    return ActionChip(
      avatar: const Icon(Icons.psychology_alt_rounded, size: 18, color: AppColors.coral),
      label: Text(m.name),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      side: BorderSide(color: AppColors.coral.withValues(alpha: 0.5)),
      backgroundColor: AppColors.coral.withValues(alpha: 0.08),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Confusión detectada', style: Theme.of(sheet).textTheme.labelMedium?.copyWith(color: AppColors.coral, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(m.name, style: Theme.of(sheet).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(m.description, style: Theme.of(sheet).textTheme.bodyLarge),
                const SizedBox(height: 12),
                Text('La idea correcta', style: Theme.of(sheet).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(m.correction, style: Theme.of(sheet).textTheme.bodyLarge),
                const SizedBox(height: 18),
                Wrap(spacing: 10, runSpacing: 8, children: [
                  if (m.remedyExperiment != null)
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheet);
                        OpenTarget.experiment(context, content!, m.remedyExperiment!);
                      },
                      icon: const Icon(Icons.science_rounded),
                      label: const Text('Ver el experimento'),
                    ),
                  if (m.remedyLesson != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheet);
                        OpenTarget.lesson(context, content!, m.remedyLesson!);
                      },
                      icon: const Icon(Icons.auto_stories_rounded),
                      label: const Text('Repasar la lección'),
                    ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
