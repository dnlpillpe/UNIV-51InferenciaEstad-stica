import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/app_logo.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/curve_backdrop.dart';
import '../../domain/engine/recommendation_engine.dart';
import '../../domain/models/case_models.dart';
import '../../domain/models/course_content.dart';
import '../../domain/models/progress_models.dart';
import '../providers/app_providers.dart';
import '../widgets/content_builder.dart';
import '../widgets/nav.dart';
import '../widgets/open_target.dart';
import 'glossary_screen.dart';
import 'module_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(progressProvider);
    return ContentBuilder(
      builder: (context, content) {
        final rec = ref.read(recommendationEngineProvider).next(content, progress);
        final overall = ref.read(masteryEngineProvider).overall(content, progress);
        final diag = ref.read(diagnosisEngineProvider).active(content, progress, limit: 1);
        final cases = _casesForCareer(content, progress);
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Header(overall: overall, days: progress.activeDays.length, onSettings: () => pushScreen(context, const SettingsScreen())),
              const SizedBox(height: 16),
              _NextCard(rec: rec, onOpen: () => OpenTarget.recommendation(context, content, rec)),
              SectionTitle('Tu ruta', trailing: TextButton(onPressed: () => onNavigate(1), child: const Text('Ver todo'))),
              SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: content.modules.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final m = content.modules[i];
                    final mm = ref.read(masteryEngineProvider).forModule(m, content, progress);
                    final color = Color(m.colorValue);
                    return SizedBox(
                      width: 142,
                      child: AppCard(
                        padding: const EdgeInsets.all(12),
                        onTap: () => pushScreen(context, ModuleDetailScreen(moduleId: m.id)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              ModuleBadge(number: m.number, color: color, size: 30, icon: iconFor(m.icon)),
                              const Spacer(),
                              ProgressRing(value: mm.total, color: color, size: 36, stroke: 4),
                            ]),
                            const Spacer(),
                            Text(m.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (diag.isNotEmpty) ...[
                const SectionTitle('Confusión a vigilar'),
                AppCard(
                  onTap: () {
                    final m = diag.first.misconception;
                    final exp = m.remedyExperiment;
                    if (exp != null) {
                      OpenTarget.experiment(context, content, exp);
                    } else if (m.remedyLesson != null) {
                      OpenTarget.lesson(context, content, m.remedyLesson!);
                    }
                  },
                  child: Row(children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.coral, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(diag.first.misconception.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(diag.first.misconception.correction, style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ]),
                ),
              ],
              SectionTitle(progress.career == null ? 'Casos profesionales' : 'Casos para ti'),
              SizedBox(
                height: 168,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: cases.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _CaseMini(
                    cs: cases[i],
                    score: progress.cases[cases[i].id],
                    mine: cases[i].career == progress.career,
                    onTap: () => OpenTarget.caseStudy(context, content, cases[i].id),
                  ),
                ),
              ),
              const SectionTitle('Herramientas'),
              Row(children: [
                Expanded(child: _ToolButton(icon: Icons.science_rounded, label: 'Laboratorios', onTap: () => onNavigate(2))),
                const SizedBox(width: 10),
                Expanded(child: _ToolButton(icon: Icons.calculate_rounded, label: 'Calculadora', onTap: () => onNavigate(3))),
                const SizedBox(width: 10),
                Expanded(child: _ToolButton(icon: Icons.menu_book_rounded, label: 'Glosario', onTap: () => pushScreen(context, const GlossaryScreen()))),
              ]),
            ],
          ),
        );
      },
    );
  }

  List<CaseStudy> _casesForCareer(CourseContent c, ProgressState p) {
    final list = [...c.cases];
    list.sort((a, b) {
      final am = a.career == p.career ? 0 : 1;
      final bm = b.career == p.career ? 0 : 1;
      if (am != bm) return am.compareTo(bm);
      final ad = p.cases.containsKey(a.id) ? 1 : 0;
      final bd = p.cases.containsKey(b.id) ? 1 : 0;
      return ad.compareTo(bd);
    });
    return list;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.overall, required this.days, required this.onSettings});
  final double overall;
  final int days;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return CurveBackdrop(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const AppLogo(size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Inferencia Estadística', style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                Text('De la muestra a la decisión', style: t.bodySmall?.copyWith(color: Colors.white70)),
              ]),
            ),
            IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.settings_rounded, color: Colors.white),
              tooltip: 'Ajustes',
            ),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            ProgressRing(value: overall, color: AppColors.amber, size: 66, stroke: 7, textColor: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Dominio del curso', style: t.labelLarge?.copyWith(color: Colors.white70)),
                const SizedBox(height: 2),
                Text(
                  overall < 0.05 ? 'Empieza por la ruta sugerida' : overall >= 0.7 ? 'Nivel competente' : 'Vas construyendo',
                  style: t.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text('$days ${days == 1 ? 'día' : 'días'} con actividad', style: t.bodySmall?.copyWith(color: Colors.white60)),
              ]),
            ),
          ]),
        ],
      ),
    );
  }
}

class _NextCard extends StatelessWidget {
  const _NextCard({required this.rec, required this.onOpen});
  final Recommendation rec;
  final VoidCallback onOpen;

  IconData get _icon => switch (rec.kind) {
        RecommendationKind.lesson => Icons.auto_stories_rounded,
        RecommendationKind.experiment => Icons.science_rounded,
        RecommendationKind.practice => Icons.edit_note_rounded,
        RecommendationKind.caseStudy => Icons.work_rounded,
        RecommendationKind.remedy => Icons.healing_rounded,
        RecommendationKind.done => Icons.emoji_events_rounded,
      };

  String get _kicker => switch (rec.kind) {
        RecommendationKind.lesson => 'SIGUIENTE LECCIÓN',
        RecommendationKind.experiment => 'EXPERIMENTO SUGERIDO',
        RecommendationKind.practice => 'PRÁCTICA',
        RecommendationKind.caseStudy => 'CASO PROFESIONAL',
        RecommendationKind.remedy => 'REFUERZO PERSONALIZADO',
        RecommendationKind.done => 'COMPLETADO',
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      onTap: rec.kind == RecommendationKind.done ? null : onOpen,
      child: Row(children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
          child: Icon(_icon, color: const Color(0xFFC27D12), size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_kicker, style: t.labelSmall?.copyWith(letterSpacing: 1.1, fontWeight: FontWeight.w800, color: const Color(0xFFC27D12))),
            const SizedBox(height: 3),
            Text(rec.title, style: t.titleMedium),
            const SizedBox(height: 2),
            Text(rec.reason, style: t.bodySmall),
          ]),
        ),
        if (rec.kind != RecommendationKind.done) Icon(Icons.play_circle_fill_rounded, size: 36, color: Theme.of(context).colorScheme.primary),
      ]),
    );
  }
}

class _CaseMini extends StatelessWidget {
  const _CaseMini({required this.cs, required this.score, required this.mine, required this.onTap});
  final CaseStudy cs;
  final double? score;
  final bool mine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 210,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.m5.withValues(alpha: 0.15),
                child: Icon(iconFor(cs.icon), color: AppColors.m5, size: 20),
              ),
              const Spacer(),
              if (score != null) Pill('${(score! * 100).round()} %', color: AppColors.teal, icon: Icons.check_rounded),
              if (score == null && mine) const Pill('Tu carrera', color: AppColors.m3),
            ]),
            const SizedBox(height: 10),
            Text(cs.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(cs.career, style: t.labelSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(children: [
        Icon(icon, color: AppColors.indigoSoft),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      ]),
    );
  }
}
