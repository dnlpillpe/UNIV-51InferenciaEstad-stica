import 'package:flutter/material.dart';

import '../../domain/engine/recommendation_engine.dart';
import '../../domain/models/course_content.dart';
import '../screens/case_player_screen.dart';
import '../screens/exercise_session_screen.dart';
import '../screens/lab_screen.dart';
import '../screens/lesson_screen.dart';
import 'nav.dart';

/// Abre el destino de una recomendación o de un remedio de confusión.
class OpenTarget {
  OpenTarget._();

  static void lesson(BuildContext context, CourseContent c, String lessonId) {
    final l = c.lesson(lessonId);
    if (l == null) return;
    pushScreen(context, LessonScreen(lesson: l));
  }

  static void experiment(BuildContext context, CourseContent c, String experimentId) {
    final e = c.experiment(experimentId);
    if (e == null) return;
    final lab = c.lab(e.labId);
    if (lab == null) return;
    pushScreen(context, LabScreen(lab: lab, initialExperimentId: e.id));
  }

  static void practice(BuildContext context, CourseContent c, String moduleId) {
    final list = [...c.exercisesOf(moduleId)]..sort((a, b) => a.difficulty.compareTo(b.difficulty));
    if (list.isEmpty) return;
    final m = c.module(moduleId);
    pushScreen(context, ExerciseSessionScreen(title: m?.title ?? 'Práctica', exercises: list, colorValue: m?.colorValue));
  }

  static void caseStudy(BuildContext context, CourseContent c, String caseId) {
    final cs = c.caseStudy(caseId);
    if (cs == null) return;
    pushScreen(context, CasePlayerScreen(caseStudy: cs));
  }

  static void recommendation(BuildContext context, CourseContent c, Recommendation r) {
    switch (r.kind) {
      case RecommendationKind.lesson:
        lesson(context, c, r.targetId!);
      case RecommendationKind.experiment:
        experiment(context, c, r.targetId!);
      case RecommendationKind.practice:
        practice(context, c, r.moduleId!);
      case RecommendationKind.caseStudy:
        caseStudy(context, c, r.targetId!);
      case RecommendationKind.remedy:
        final id = r.targetId!;
        if (c.experiment(id) != null) {
          experiment(context, c, id);
        } else {
          lesson(context, c, id);
        }
      case RecommendationKind.done:
        break;
    }
  }
}
