import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';

/// Fila de botones de simulación: «×1», «×10», «×100»...
class RunButtons extends StatelessWidget {
  const RunButtons({
    super.key,
    required this.counts,
    required this.onRun,
    required this.color,
    this.onReset,
    this.verb = 'Simular',
  });

  final List<int> counts;
  final ValueChanged<int> onRun;
  final VoidCallback? onReset;
  final Color color;
  final String verb;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < counts.length; i++)
          i == 0
              ? FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: color),
                  onPressed: () => onRun(counts[i]),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(counts[i] == 1 ? verb : '$verb ×${Fmt.integer(counts[i])}'),
                )
              : FilledButton.tonal(
                  onPressed: () => onRun(counts[i]),
                  child: Text('×${Fmt.integer(counts[i])}'),
                ),
        if (onReset != null)
          IconButton(onPressed: onReset, icon: const Icon(Icons.restart_alt_rounded), tooltip: 'Reiniciar'),
      ],
    );
  }
}

/// Selector discreto sobre una lista de valores (tamaños de muestra, etc.).
class DiscreteSlider extends StatelessWidget {
  const DiscreteSlider({
    super.key,
    required this.label,
    required this.values,
    required this.value,
    required this.onChanged,
    this.format,
  });

  final String label;
  final List<num> values;
  final num value;
  final ValueChanged<num> onChanged;
  final String Function(num)? format;

  @override
  Widget build(BuildContext context) {
    final idx = values.indexOf(value).clamp(0, values.length - 1);
    final f = format ?? (v) => Fmt.number(v.toDouble(), v is int ? 0 : 2);
    return Row(children: [
      SizedBox(width: 92, child: Text('$label: ${f(value)}', style: const TextStyle(fontWeight: FontWeight.w700))),
      Expanded(
        child: Slider(
          value: idx.toDouble(),
          min: 0,
          max: (values.length - 1).toDouble(),
          divisions: values.length - 1,
          label: f(values[idx]),
          onChanged: (v) => onChanged(values[v.round()]),
        ),
      ),
    ]);
  }
}

/// Panel con título para un gráfico.
class ChartPanel extends StatelessWidget {
  const ChartPanel({super.key, required this.title, required this.child, this.height = 150, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget child;
  final double height;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(title, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800))),
            if (trailing != null) trailing!,
          ]),
          if (subtitle != null) Text(subtitle!, style: t.bodySmall),
          const SizedBox(height: 4),
          SizedBox(height: height, width: double.infinity, child: child),
        ]),
      ),
    );
  }
}
