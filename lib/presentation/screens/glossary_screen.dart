import 'package:flutter/material.dart';

import '../../core/widgets/common_widgets.dart';
import '../widgets/content_builder.dart';

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  String _q = '';

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ñ', 'n');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Glosario')),
      body: ContentBuilder(builder: (context, content) {
        final t = Theme.of(context).textTheme;
        final q = _norm(_q);
        final list = content.glossary
            .where((g) => q.isEmpty || _norm(g.term).contains(q) || _norm(g.definition).contains(q))
            .toList()
          ..sort((a, b) => _norm(a.term).compareTo(_norm(b.term)));
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Buscar término o idea'),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 12),
            for (final g in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(g.term, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800))),
                        if (g.symbol != null) Pill(g.symbol!),
                        const SizedBox(width: 6),
                        Builder(builder: (context) {
                          final m = content.module(g.moduleId);
                          return m == null ? const SizedBox.shrink() : Pill('M${m.number}', color: Color(m.colorValue));
                        }),
                      ]),
                      const SizedBox(height: 6),
                      Text(g.definition, style: t.bodyMedium),
                      if (g.example != null) ...[
                        const SizedBox(height: 4),
                        Text('Ejemplo: ${g.example}', style: t.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                      ],
                    ]),
                  ),
                ),
              ),
            if (list.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('Sin resultados.'))),
          ],
        );
      }),
    );
  }
}
