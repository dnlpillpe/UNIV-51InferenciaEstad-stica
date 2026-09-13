import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common_widgets.dart';
import '../../domain/engine/procedures.dart';
import '../../domain/stats/inference.dart';
import '../widgets/result_views.dart';

/// Calculadora inferencial: siempre a mano para que el esfuerzo vaya a
/// elegir el procedimiento e interpretar, no a la aritmética.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  Procedure _p = Procedure.ciMean;
  final Map<String, TextEditingController> _ctrl = {};
  double _conf = 0.95;
  double _alpha = 0.05;
  Tail _tail = Tail.twoSided;
  bool _knownSigma = false;
  ProcedureOutcome? _out;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    _ctrl.clear();
    for (final f in _p.fields) {
      _ctrl[f.key] = TextEditingController(text: f.initial == null ? '' : Fmt.number(f.initial!, f.integer ? 0 : (f.initial! < 1 ? 2 : 1)).replaceAll(' ', ''));
    }
    _out = null;
    _knownSigma = false;
    _tail = _p == Procedure.testMean ? Tail.greater : Tail.twoSided;
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _run() {
    FocusScope.of(context).unfocus();
    final values = <String, double>{
      for (final f in _p.fields) f.key: Fmt.parse(_ctrl[f.key]!.text) ?? double.nan,
    };
    setState(() {
      _out = const ProcedureRunner().run(_p, values, conf: _conf, alpha: _alpha, tail: _tail, knownSigma: _knownSigma);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final out = _out;
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora inferencial')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          InputDecorator(
            decoration: const InputDecoration(labelText: 'Procedimiento'),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Procedure>(
                value: _p,
                isExpanded: true,
                isDense: true,
                items: [for (final p in Procedure.values) DropdownMenuItem(value: p, child: Text(p.label))],
                onChanged: (p) => setState(() {
                  _p = p!;
                  _load();
                }),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(_p.description, style: t.bodySmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final f in _p.fields)
                SizedBox(
                  width: _p.fields.length > 4 ? 100 : 150,
                  child: TextField(
                    controller: _ctrl[f.key],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                    decoration: InputDecoration(labelText: f.label),
                  ),
                ),
            ],
          ),
          if (_p.canUseKnownSigma)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _knownSigma,
              onChanged: (v) => setState(() => _knownSigma = v),
              title: const Text('σ poblacional conocida (usar z)'),
              subtitle: const Text('Solo si σ viene de información externa, no de esta muestra.'),
            ),
          if (_p.usesConfidence) ...[
            const SizedBox(height: 8),
            Text('Nivel de confianza', style: t.labelLarge),
            const SizedBox(height: 4),
            SegmentedButton<double>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0.90, label: Text('90 %')),
                ButtonSegment(value: 0.95, label: Text('95 %')),
                ButtonSegment(value: 0.99, label: Text('99 %')),
              ],
              selected: {_conf},
              onSelectionChanged: (s) => setState(() => _conf = s.first),
            ),
          ],
          if (_p.usesTail) ...[
            const SizedBox(height: 12),
            Text('Hipótesis alternativa (decídela antes de ver el resultado)', style: t.labelLarge),
            const SizedBox(height: 4),
            SegmentedButton<Tail>(
              showSelectedIcon: false,
              segments: [for (final tl in Tail.values) ButtonSegment(value: tl, label: Text('H1: ${tl.symbol}'))],
              selected: {_tail},
              onSelectionChanged: (s) => setState(() => _tail = s.first),
            ),
            const SizedBox(height: 12),
            Text('Nivel de significancia α', style: t.labelLarge),
            const SizedBox(height: 4),
            SegmentedButton<double>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0.10, label: Text('0,10')),
                ButtonSegment(value: 0.05, label: Text('0,05')),
                ButtonSegment(value: 0.01, label: Text('0,01')),
              ],
              selected: {_alpha},
              onSelectionChanged: (s) => setState(() => _alpha = s.first),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _run, icon: const Icon(Icons.calculate_rounded), label: const Text('Calcular')),
          if (out != null) ...[
            const SizedBox(height: 16),
            if (!out.ok)
              for (final e in out.errors)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Callout(text: e, icon: Icons.error_outline_rounded, color: AppColors.coral),
                ),
            if (out.ok) ...[
              if (out.sampleSize != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Text('Tamaño de muestra necesario', style: t.labelLarge),
                      const SizedBox(height: 4),
                      Text('n = ${Fmt.integer(out.sampleSize!)}', style: t.displaySmall?.copyWith(fontWeight: FontWeight.w900)),
                      Text('Se redondea siempre hacia arriba.', style: t.bodySmall),
                    ]),
                  ),
                ),
              if (out.interval != null) ...[
                const SectionTitle('Intervalo de confianza'),
                IntervalView(
                  ci: out.interval!,
                  percent: _p == Procedure.ciProportion || _p == Procedure.diffProportions,
                  reference: _p == Procedure.diffMeans || _p == Procedure.diffProportions ? 0 : null,
                  referenceLabel: '0',
                ),
                const SizedBox(height: 8),
                Callout(text: out.intervalText!, icon: Icons.record_voice_over_rounded, color: AppColors.m3, title: 'Cómo decirlo'),
              ],
              if (out.test != null) ...[
                const SectionTitle('Prueba de hipótesis'),
                TestResultView(result: out.test!, alpha: _alpha),
                const SizedBox(height: 8),
                Callout(text: out.testText!, icon: Icons.record_voice_over_rounded, color: AppColors.m4, title: 'Cómo decirlo'),
              ],
              if (out.warnings.isNotEmpty) ...[
                const SectionTitle('Condiciones y advertencias'),
                for (final w in out.warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Callout(text: w, icon: Icons.warning_amber_rounded, color: const Color(0xFFC27D12)),
                  ),
              ],
            ],
          ],
        ],
      ),
    );
  }
}
