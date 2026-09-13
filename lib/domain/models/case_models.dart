import 'exercise_models.dart';
import 'json_utils.dart';
import 'verify_claim.dart';

enum CaseStepType { choice, compute }

class CaseStep {
  const CaseStep({
    required this.type,
    required this.title,
    required this.prompt,
    this.options = const [],
    this.note,
  });

  final CaseStepType type;
  final String title;
  final String prompt;
  final List<ChoiceOption> options;
  final String? note;

  factory CaseStep.fromJson(Json j) => CaseStep(
        type: jStr(j, 'type') == 'compute' ? CaseStepType.compute : CaseStepType.choice,
        title: jStr(j, 'title'),
        prompt: jStr(j, 'prompt'),
        options: jList(j, 'options').map(ChoiceOption.fromJson).toList(),
        note: jStrOrNull(j, 'note'),
      );
}

class CaseDataItem {
  const CaseDataItem(this.label, this.value);
  final String label;
  final String value;

  factory CaseDataItem.fromJson(Json j) => CaseDataItem(jStr(j, 'label'), jStr(j, 'value'));
}

/// Procedimiento que la app ejecuta con los datos del caso.
class CaseAnalysis {
  const CaseAnalysis({required this.fn, required this.args, this.alpha = 0.05, this.companion});

  final String fn;
  final Map<String, dynamic> args;
  final double alpha;

  /// Intervalo complementario (p. ej. el IC que acompaña a una prueba).
  final CaseAnalysis? companion;

  factory CaseAnalysis.fromJson(Json j) => CaseAnalysis(
        fn: jStr(j, 'fn'),
        args: Map<String, dynamic>.from((j['args'] as Map?) ?? const {}),
        alpha: jDouble(j, 'alpha', 0.05),
        companion: j['companion'] is Map
            ? CaseAnalysis.fromJson(Map<String, dynamic>.from(j['companion'] as Map))
            : null,
      );
}

/// Caso profesional: un problema de una carrera concreta que se resuelve
/// paso a paso, desde identificar el parámetro hasta asumir el riesgo.
class CaseStudy {
  const CaseStudy({
    required this.id,
    required this.title,
    required this.career,
    required this.icon,
    required this.difficulty,
    required this.brief,
    required this.role,
    required this.question,
    required this.data,
    required this.steps,
    required this.debrief,
    this.moduleRefs = const [],
    this.analysis,
    this.expectedReject,
    this.verify = const [],
    this.rawData = const [],
  });

  final String id;
  final String title;
  final String career;
  final String icon;
  final int difficulty;
  final String brief;
  final String role;
  final String question;
  final List<CaseDataItem> data;
  final List<CaseStep> steps;
  final String debrief;
  final List<String> moduleRefs;
  final CaseAnalysis? analysis;
  final bool? expectedReject;
  final List<VerifyClaim> verify;
  final List<double> rawData;

  int get choiceSteps => steps.where((s) => s.type == CaseStepType.choice).length;

  Set<String> get detectableTags => {
        for (final s in steps) ...s.options.map((o) => o.tag).whereType<String>(),
      };

  factory CaseStudy.fromJson(Json j) => CaseStudy(
        id: jStr(j, 'id'),
        title: jStr(j, 'title'),
        career: jStr(j, 'career'),
        icon: jStr(j, 'icon'),
        difficulty: jInt(j, 'difficulty', 2),
        brief: jStr(j, 'brief'),
        role: jStr(j, 'role'),
        question: jStr(j, 'question'),
        data: jList(j, 'data').map(CaseDataItem.fromJson).toList(),
        steps: jList(j, 'steps').map(CaseStep.fromJson).toList(),
        debrief: jStr(j, 'debrief'),
        moduleRefs: jStrings(j, 'modules'),
        analysis: j['analysis'] is Map
            ? CaseAnalysis.fromJson(Map<String, dynamic>.from(j['analysis'] as Map))
            : null,
        expectedReject: j['expectedReject'] is bool ? j['expectedReject'] as bool : null,
        verify: jList(j, 'verify').map(VerifyClaim.fromJson).toList(),
        rawData: (j['raw'] is List)
            ? (j['raw'] as List).whereType<num>().map((e) => e.toDouble()).toList()
            : const [],
      );
}
