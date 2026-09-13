import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/asset_content_repository.dart';
import '../../data/prefs_progress_repository.dart';
import '../../domain/engine/diagnosis_engine.dart';
import '../../domain/engine/grading_engine.dart';
import '../../domain/engine/mastery_engine.dart';
import '../../domain/engine/recommendation_engine.dart';
import '../../domain/models/course_content.dart';
import '../../domain/models/progress_models.dart';
import '../../domain/repositories/repositories.dart';
import 'progress_notifier.dart';

/// Se sobreescribe en `main()` con la instancia real ya inicializada.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider debe sobreescribirse en main()'),
);

final contentRepositoryProvider = Provider<ContentRepository>((ref) => AssetContentRepository());

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => PrefsProgressRepository(ref.watch(sharedPreferencesProvider)),
);

final contentProvider = FutureProvider<CourseContent>(
  (ref) => ref.watch(contentRepositoryProvider).load(),
);

final progressProvider = NotifierProvider<ProgressNotifier, ProgressState>(ProgressNotifier.new);

final gradingEngineProvider = Provider<GradingEngine>((ref) => const GradingEngine());
final masteryEngineProvider = Provider<MasteryEngine>((ref) => const MasteryEngine());
final diagnosisEngineProvider = Provider<DiagnosisEngine>((ref) => const DiagnosisEngine());
final recommendationEngineProvider =
    Provider<RecommendationEngine>((ref) => const RecommendationEngine());
