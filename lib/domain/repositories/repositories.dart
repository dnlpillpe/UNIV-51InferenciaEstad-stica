import '../models/course_content.dart';
import '../models/progress_models.dart';

/// Fuente del contenido del curso (hoy: JSON empaquetado en la app).
abstract interface class ContentRepository {
  Future<CourseContent> load();
}

/// Persistencia del progreso (hoy: almacenamiento local del dispositivo).
abstract interface class ProgressRepository {
  ProgressState read();
  Future<void> write(ProgressState state);
  Future<void> clear();
}
