import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../domain/models/lab_models.dart';
import '../labs/decision_room_lab.dart';
import '../labs/interval_lab.dart';
import '../labs/null_world_lab.dart';
import '../labs/sampling_lab.dart';
import '../labs/survey_lab.dart';
import '../providers/app_providers.dart';

/// Contenedor de un laboratorio: selector de experimento y cuerpo del lab.
class LabScreen extends ConsumerStatefulWidget {
  const LabScreen({super.key, required this.lab, this.initialExperimentId});
  final Lab lab;
  final String? initialExperimentId;

  @override
  ConsumerState<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends ConsumerState<LabScreen> {
  /// null = modo libre.
  String? _experimentId;

  @override
  void initState() {
    super.initState();
    _experimentId = widget.initialExperimentId ?? widget.lab.experiments.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider).valueOrNull;
    final module = content?.module(widget.lab.moduleId);
    final color = module == null ? AppColors.indigo : Color(module.colorValue);
    final done = ref.watch(progressProvider.select((p) => p.completedExperiments));
    final exp = _experimentId == null
        ? null
        : widget.lab.experiments.firstWhere((e) => e.id == _experimentId);
    return Scaffold(
      appBar: AppBar(title: Text(widget.lab.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          Text(widget.lab.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (var i = 0; i < widget.lab.experiments.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: done.contains(widget.lab.experiments[i].id)
                        ? const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.teal)
                        : null,
                    label: Text('${i + 1}. ${widget.lab.experiments[i].title}'),
                    selected: _experimentId == widget.lab.experiments[i].id,
                    onSelected: (_) => setState(() => _experimentId = widget.lab.experiments[i].id),
                  ),
                ),
              ChoiceChip(
                avatar: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Modo libre'),
                selected: _experimentId == null,
                onSelected: (_) => setState(() => _experimentId = null),
              ),
            ]),
          ),
          const SizedBox(height: 14),
          KeyedSubtree(
            key: ValueKey('${widget.lab.id}-${_experimentId ?? 'free'}'),
            child: _body(exp, color),
          ),
        ],
      ),
    );
  }

  Widget _body(LabExperiment? e, Color color) {
    switch (widget.lab.id) {
      case 'lab1':
        return SurveyLab(experiment: e, color: color);
      case 'lab2':
        return SamplingLab(experiment: e, color: color);
      case 'lab3':
        return IntervalLab(experiment: e, color: color);
      case 'lab4':
        return NullWorldLab(experiment: e, color: color);
      case 'lab5':
        return DecisionRoomLab(experiment: e, color: color);
    }
    return const SizedBox.shrink();
  }
}
