import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';

/// Etiqueta compacta (prioridad, origen, razones, gravedad)
class ModerationTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;

  /// Solo borde: para las razones, que son secundarias a los estados
  final bool outlined;

  const ModerationTag({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foreground ?? scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: outlined ? null : (background ?? scheme.surfaceContainerHighest),
        border: outlined ? Border.all(color: scheme.outlineVariant) : null,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.md, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
