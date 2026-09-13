import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

enum OptionState { idle, selected, correct, wrong, dimmed }

/// Opción seleccionable reutilizada en lecciones, ejercicios, casos y laboratorios.
class OptionTile extends StatelessWidget {
  const OptionTile({super.key, required this.text, required this.state, this.onTap, this.accent});
  final String text;
  final OptionState state;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final a = accent ?? (dark ? const Color(0xFFB8C2FF) : AppColors.indigo);
    final (Color border, Color bg, IconData? icon) = switch (state) {
      OptionState.idle => (Theme.of(context).dividerColor, Colors.transparent, null),
      OptionState.selected => (a, a.withValues(alpha: 0.10), Icons.radio_button_checked_rounded),
      OptionState.correct => (AppColors.teal, AppColors.teal.withValues(alpha: 0.12), Icons.check_circle_rounded),
      OptionState.wrong => (AppColors.coral, AppColors.coral.withValues(alpha: 0.12), Icons.cancel_rounded),
      OptionState.dimmed => (Theme.of(context).dividerColor, Colors.transparent, null),
    };
    return Opacity(
      opacity: state == OptionState.dimmed ? 0.55 : 1,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border, width: state == OptionState.idle || state == OptionState.dimmed ? 1 : 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(children: [
              Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyLarge)),
              if (icon != null) ...[const SizedBox(width: 8), Icon(icon, color: border, size: 22)],
            ]),
          ),
        ),
      ),
    );
  }
}
