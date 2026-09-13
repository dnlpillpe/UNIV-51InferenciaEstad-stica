import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/curve_backdrop.dart';
import '../../domain/engine/procedures.dart';
import '../../domain/models/case_models.dart';
import '../../domain/stats/inference_registry.dart';
import '../providers/app_providers.dart';
import '../widgets/misconception_chip.dart';
import '../widgets/option_tile.dart';
import '../widgets/result_views.dart';

/// Reproduce un caso profesional paso a paso.
///
/// En cada paso de elección cuenta el primer intento (para el puntaje),
/// pero el estudiante puede reintentar hasta dar con la respuesta: el caso
/// avanza como avanzaría en la realidad, con la decisión correcta.
class CasePlayerScreen extends ConsumerStatefulWidget {
  const CasePlayerScreen({super.key, required this.caseStudy});
  final CaseStudy caseStudy;

  @override
  ConsumerState<CasePlayerScreen> createState() => _CasePlayerScreenState();
}

class _CasePlayerScreenState extends ConsumerState<CasePlayerScreen> {
  /// -1 = introducción; steps.length = cierre.
  int _step = -1;
  final Map<int, List<int>> _picks = {};
  bool _recorded = false;

  CaseStudy get cs => widget.caseStudy;

  bool _stepSolved(int i) {
    final s = cs.steps[i];
    if (s.type == CaseStepType.compute) return true;
    final picks = _picks[i] ?? const [];
    return picks.any((p) => s.options[p].correct);
  }

  double get _score {
    var ok = 0;
    var total = 0;
    for (var i = 0; i < cs.steps.length; i++) {
      final s = cs.steps[i];
      if (s.type != CaseStepType.choice) continue;
      total++;
      final picks = _picks[i];
      if (picks != null && picks.isNotEmpty && s.options[picks.first].correct) ok++;
    }
    return total == 0 ? 1 : ok / total;
  }

  List<String> get _tags => [
        for (var i = 0; i < cs.steps.length; i++)
          for (final p in _picks[i] ?? const <int>[])
            if (cs.steps[i].options[p].tag != null) cs.steps[i].options[p].tag!,
      ];

  void _finish() {
    if (!_recorded) {
      final tags = _tags;
      ref.read(progressProvider.notifier).recordCase(
            cs.id,
            _score,
            tags,
            _score >= 0.999 ? cs.detectableTags : const {},
          );
      _recorded = true;
    }
    setState(() => _step = cs.steps.length);
  }

  @override
  Widget build(BuildContext context) {
    final total = cs.steps.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(cs.title),
        bottom: _step >= 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ThinProgress(value: (_step.clamp(0, total)) / total, color: AppColors.m5, height: 5),
                ),
              )
            : null,
      ),
      body: _step < 0
          ? _intro(context)
          : _step >= total
              ? _debrief(context)
              : _stepView(context, _step),
    );
  }

  Widget _dataCard(BuildContext context, {bool initiallyExpanded = true}) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: const Icon(Icons.table_chart_rounded, color: AppColors.m5),
          title: Text('Datos del caso', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          children: [
            for (final d in cs.data)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 5, child: Text(d.label, style: t.bodyMedium)),
                  Expanded(flex: 6, child: Text(d.value, style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w800))),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _intro(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CurveBackdrop(
          color: AppColors.m5,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(radius: 24, backgroundColor: Colors.white24, child: Icon(iconFor(cs.icon), color: Colors.white)),
              const SizedBox(width: 12),
              Expanded(child: Text(cs.career.toUpperCase(), style: t.labelMedium?.copyWith(color: Colors.white70, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
            ]),
            const SizedBox(height: 12),
            Text(cs.title, style: t.headlineSmall?.copyWith(color: Colors.white)),
            const SizedBox(height: 6),
            Text(cs.role, style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85), fontStyle: FontStyle.italic)),
          ]),
        ),
        const SizedBox(height: 14),
        Text(cs.brief, style: t.bodyLarge),
        const SizedBox(height: 12),
        Callout(title: 'La pregunta', text: cs.question, icon: Icons.help_rounded, color: AppColors.m5),
        const SizedBox(height: 12),
        _dataCard(context),
        const SizedBox(height: 20),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.m5),
          onPressed: () => setState(() => _step = 0),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text('Resolver en ${cs.steps.length} pasos'),
        ),
      ],
    );
  }

  Widget _stepView(BuildContext context, int i) {
    final s = cs.steps[i];
    final t = Theme.of(context).textTheme;
    final solved = _stepSolved(i);
    final picks = _picks[i] ?? const <int>[];
    final last = picks.isEmpty ? null : picks.last;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(children: [
          Pill('Paso ${i + 1} de ${cs.steps.length}', color: AppColors.m5),
          const SizedBox(width: 6),
          Pill(s.title, color: Colors.blueGrey),
        ]),
        const SizedBox(height: 10),
        _dataCard(context, initiallyExpanded: false),
        const SizedBox(height: 12),
        Text(s.prompt, style: t.titleMedium?.copyWith(height: 1.35)),
        const SizedBox(height: 14),
        if (s.type == CaseStepType.compute) _compute(context, s),
        if (s.type == CaseStepType.choice) ...[
          for (var o = 0; o < s.options.length; o++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OptionTile(
                text: s.options[o].text,
                accent: AppColors.m5,
                state: picks.contains(o)
                    ? (s.options[o].correct ? OptionState.correct : OptionState.wrong)
                    : (solved ? OptionState.dimmed : OptionState.idle),
                onTap: solved || picks.contains(o)
                    ? null
                    : () => setState(() => _picks[i] = [...picks, o]),
              ),
            ),
          if (last != null) ...[
            const SizedBox(height: 6),
            Callout(
              text: s.options[last].feedback.isEmpty
                  ? (s.options[last].correct ? 'Correcto.' : 'No es la mejor opción.')
                  : s.options[last].feedback,
              icon: s.options[last].correct ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: s.options[last].correct ? AppColors.teal : AppColors.coral,
              title: s.options[last].correct ? 'Bien' : 'Inténtalo de nuevo',
            ),
            if (s.options[last].tag != null && !s.options[last].correct)
              Padding(padding: const EdgeInsets.only(top: 8), child: Align(alignment: Alignment.centerLeft, child: MisconceptionChip(s.options[last].tag!))),
          ],
        ],
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.m5),
          onPressed: solved
              ? () {
                  if (i == cs.steps.length - 1) {
                    _finish();
                  } else {
                    setState(() => _step = i + 1);
                  }
                }
              : null,
          child: Text(i == cs.steps.length - 1 ? 'Ver cierre del caso' : 'Continuar'),
        ),
      ],
    );
  }

  Widget _compute(BuildContext context, CaseStep s) {
    final a = cs.analysis;
    if (a == null) return const SizedBox.shrink();
    final t = Theme.of(context).textTheme;
    final test = InferenceRegistry.test(a.fn, a.args);
    final ci = InferenceRegistry.interval(a.fn, a.args);
    final comp = a.companion == null ? null : InferenceRegistry.interval(a.companion!.fn, a.companion!.args);
    final percent = a.fn.contains('prop');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (s.note != null) ...[FormulaBox(s.note!, color: AppColors.m5), const SizedBox(height: 14)],
      if (test != null) ...[
        Text('Prueba de hipótesis', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TestResultView(result: test, alpha: a.alpha),
      ],
      if (ci != null) ...[
        Text('Intervalo de confianza', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        IntervalView(ci: ci, percent: percent),
        const SizedBox(height: 8),
        Text(Interpretation.interval(ci, percent ? 'la proporción poblacional' : 'el parámetro', percent: percent), style: t.bodySmall),
      ],
      if (comp != null) ...[
        const SizedBox(height: 16),
        Text('Intervalo que acompaña a la prueba', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        IntervalView(ci: comp, percent: percent, reference: test != null ? _reference(a.args) : null, referenceLabel: 'H0'),
      ],
    ]);
  }

  double? _reference(Map<String, dynamic> args) {
    if (args['mu0'] is num) return (args['mu0'] as num).toDouble();
    if (args['p0'] is num) return (args['p0'] as num).toDouble();
    if (args.containsKey('mean1') || args.containsKey('x1')) return 0;
    return null;
  }

  Widget _debrief(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final tags = _tags.toSet().toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(child: ProgressRing(value: _score, color: AppColors.m5, size: 110, stroke: 11)),
        const SizedBox(height: 8),
        Center(child: Text('Pasos acertados al primer intento', style: t.bodySmall)),
        const SectionTitle('Cierre del caso'),
        Text(cs.debrief, style: t.bodyLarge),
        if (tags.isNotEmpty) ...[
          const SectionTitle('Confusiones que aparecieron'),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final tg in tags) MisconceptionChip(tg)]),
        ],
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            _picks.clear();
            _recorded = false;
            _step = -1;
          }),
          icon: const Icon(Icons.replay_rounded),
          label: const Text('Resolver de nuevo'),
        ),
        const SizedBox(height: 10),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.m5),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Terminar'),
        ),
      ],
    );
  }
}
