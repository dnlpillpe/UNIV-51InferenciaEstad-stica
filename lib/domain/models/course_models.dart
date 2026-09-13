import 'json_utils.dart';

enum CardType { concept, formula, example, warning, check }

CardType _cardType(String s) => switch (s) {
      'formula' => CardType.formula,
      'example' => CardType.example,
      'warning' => CardType.warning,
      'check' => CardType.check,
      _ => CardType.concept,
    };

/// Tarjeta de una lección. Las de tipo `check` son una pregunta rápida
/// sin puntaje: activan el recuerdo antes de pasar a la siguiente idea.
class LessonCard {
  const LessonCard({
    required this.type,
    required this.title,
    required this.body,
    this.formula,
    this.visual,
    this.tag,
    this.question,
    this.options = const [],
    this.answer,
    this.explanation,
  });

  final CardType type;
  final String title;
  final String body;
  final String? formula;
  final String? visual;
  final String? tag;
  final String? question;
  final List<String> options;
  final int? answer;
  final String? explanation;

  factory LessonCard.fromJson(Json j) => LessonCard(
        type: _cardType(jStr(j, 'type')),
        title: jStr(j, 'title'),
        body: jStr(j, 'body'),
        formula: jStrOrNull(j, 'formula'),
        visual: jStrOrNull(j, 'visual'),
        tag: jStrOrNull(j, 'tag'),
        question: jStrOrNull(j, 'question'),
        options: jStrings(j, 'options'),
        answer: j['answer'] is num ? (j['answer'] as num).round() : null,
        explanation: jStrOrNull(j, 'explanation'),
      );
}

class Lesson {
  const Lesson({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.summary,
    required this.minutes,
    required this.cards,
  });

  final String id;
  final String moduleId;
  final String title;
  final String summary;
  final int minutes;
  final List<LessonCard> cards;

  factory Lesson.fromJson(Json j, String moduleId) => Lesson(
        id: jStr(j, 'id'),
        moduleId: moduleId,
        title: jStr(j, 'title'),
        summary: jStr(j, 'summary'),
        minutes: jInt(j, 'minutes', 4),
        cards: jList(j, 'cards').map(LessonCard.fromJson).toList(),
      );
}

class CourseModule {
  const CourseModule({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.keyQuestion,
    required this.competency,
    required this.colorValue,
    required this.icon,
    required this.labId,
    required this.lessons,
    this.recommendedAfter,
  });

  final String id;
  final int number;
  final String title;
  final String subtitle;
  final String description;
  final String keyQuestion;
  final String competency;
  final int colorValue;
  final String icon;
  final String labId;
  final List<Lesson> lessons;
  final String? recommendedAfter;

  factory CourseModule.fromJson(Json j) {
    final id = jStr(j, 'id');
    return CourseModule(
      id: id,
      number: jInt(j, 'number'),
      title: jStr(j, 'title'),
      subtitle: jStr(j, 'subtitle'),
      description: jStr(j, 'description'),
      keyQuestion: jStr(j, 'keyQuestion'),
      competency: jStr(j, 'competency'),
      colorValue: parseHexColor(jStr(j, 'color')),
      icon: jStr(j, 'icon'),
      labId: jStr(j, 'labId'),
      lessons: jList(j, 'lessons').map((l) => Lesson.fromJson(l, id)).toList(),
      recommendedAfter: jStrOrNull(j, 'recommendedAfter'),
    );
  }
}
