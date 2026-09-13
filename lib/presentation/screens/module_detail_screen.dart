import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/curve_backdrop.dart';
import '../../domain/models/exercise_models.dart';
import '../providers/app_providers.dart';
import '../widgets/content_builder.dart';
import '../widgets/nav.dart';
import '../widgets/open_target.dart';
import 'exercise_session_screen.dart';
import 'lab_screen.dart';
import 'lesson_screen.dart';

class ModuleDetailScreen extends ConsumerWidget {
  const ModuleDetailScreen({super.key, required this.moduleId});
  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(),
      body: ContentBuilder(builder: (context, content) {
        final m = content.module(moduleId)!;
        final color = Color(m.colorValue);
        final mm = ref.read(masteryEngineProvider).forModule(m, content, progress);
        final lab = content.labOf(m.id);
        final exercises = [...content.exercisesOf(m.id)]..sort((a, b) => a.difficulty.compareTo(b.difficulty));
        final failed = exercises.where((e) => (progress.exercises[e.id]?.bestScore ?? 1) < 0.999).toList();
        final cases = content.casesFor(m.id);
        final t = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            CurveBackdrop(
              color: color,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  ModuleBadge(number: m.number, color: Colors.white24, icon: iconFor(m.icon), size: 44),
                  const Spacer(),
                  ProgressRing(value: mm.total, color: Colors.white, size: 58, stroke: 6, textColor: Colors.white),
                ]),
                const SizedBox(height: 14),
                Text('MÓDULO ${m.number}', style: t.labelSmall?.copyWith(color: Colors.white70, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
                Text(m.title, style: t.headlineSmall?.copyWith(color: Colors.white)),
                Text(m.subtitle, style: t.bodyMedium?.copyWith(color: Colors.white70)),
              ]),
            ),
            const SizedBox(height: 14),
            Text(m.description, style: t.bodyMedium),
            const SizedBox(height: 10),
            Callout(title: 'Competencia', text: m.competency, icon: Icons.workspace_premium_rounded, color: color),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: StatTile(label: 'Lecciones', value: '${(mm.lessons * 100).round()} %', color: color)),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'Experimentos', value: '${(mm.experiments * 100).round()} %', color: color)),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'Práctica', value: '${(mm.practice * 100).round()} %', color: color)),
            ]),
            const SectionTitle('Lecciones'),
            for (final l in m.lessons)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  onTap: () => pushScreen(context, LessonScreen(lesson: l)),
                  child: Row(children: [
                    Icon(
                      progress.completedLessons.contains(l.id) ? Icons.check_circle_rounded : Icons.play_circle_outline_rounded,
                      color: color,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        Text(l.summary, style: t.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Text('${l.minutes} min', style: t.labelSmall),
                  ]),
                ),
              ),
            if (lab != null) ...[
              const SectionTitle('Laboratorio'),
              AppCard(
                onTap: () => pushScreen(context, LabScreen(lab: lab)),
                child: Row(children: [
                  CircleAvatar(radius: 26, backgroundColor: color.withValues(alpha: 0.15), child: Icon(iconFor(lab.icon), color: color, size: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(lab.title, style: t.titleMedium),
                      Text(lab.subtitle, style: t.bodySmall),
                      const SizedBox(height: 6),
                      Text(
                        '${lab.experiments.where((e) => progress.completedExperiments.contains(e.id)).length} de ${lab.experiments.length} experimentos',
                        style: t.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: color),
                      ),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              ),
            ],
            SectionTitle('Práctica (${exercises.length} ejercicios)'),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: color),
                  onPressed: () => OpenTarget.practice(context, content, m.id),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Practicar'),
                ),
              ),
              if (failed.isNotEmpty && failed.length < exercises.length) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => pushScreen(context, ExerciseSessionScreen(title: 'Repaso: ${m.title}', exercises: failed, colorValue: m.colorValue)),
                    icon: const Icon(Icons.replay_rounded),
                    label: Text('Repasar (${failed.length})'),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in exercises)
                  _ExerciseDot(
                    exercise: e,
                    score: progress.exercises[e.id]?.bestScore,
                    color: color,
                    onTap: () => pushScreen(context, ExerciseSessionScreen(title: m.title, exercises: [e], colorValue: m.colorValue)),
                  ),
              ],
            ),
            if (cases.isNotEmpty) ...[
              const SectionTitle('Casos profesionales'),
              for (final cs in cases)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    onTap: () => OpenTarget.caseStudy(context, content, cs.id),
                    child: Row(children: [
                      Icon(iconFor(cs.icon), color: color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(cs.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                          Text(cs.career, style: t.bodySmall),
                        ]),
                      ),
                      if (progress.cases[cs.id] != null)
                        Pill('${(progress.cases[cs.id]! * 100).round()} %', color: color),
                    ]),
                  ),
                ),
            ],
          ],
        );
      }),
    );
  }
}

class _ExerciseDot extends StatelessWidget {
  const _ExerciseDot({required this.exercise, required this.score, required this.color, required this.onTap});
  final Exercise exercise;
  final double? score;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = score;
    final bg = s == null
        ? Theme.of(context).dividerColor
        : s >= 0.999
            ? color
            : s > 0
                ? color.withValues(alpha: 0.45)
                : const Color(0x55E5484D);
    final number = exercise.id.split('_').last;
    return Tooltip(
      message: exercise.type.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
          child: Text(number, style: TextStyle(fontWeight: FontWeight.w800, color: s != null && s >= 0.999 ? Colors.white : null)),
        ),
      ),
    );
  }
}
