import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/common_widgets.dart';
import '../../domain/models/course_content.dart';
import '../providers/app_providers.dart';

/// Resuelve el contenido asíncrono y muestra carga o error de forma uniforme.
class ContentBuilder extends ConsumerWidget {
  const ContentBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, CourseContent content) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contentProvider);
    return async.when(
      data: (c) => builder(context, c),
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView('$e'),
    );
  }
}
