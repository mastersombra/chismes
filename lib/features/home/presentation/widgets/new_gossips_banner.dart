import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Banner que aparece cuando hay chismes nuevos.
///
/// **Uso:**
/// ```dart
/// if (state.hasNewGossips)
///   NewGossipsBanner(
///     count: state.newGossipsCount,
///     onTap: () => controller.loadNewGossips(),
///   ),
/// ```
class NewGossipsBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const NewGossipsBanner({
    super.key,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$count nuevos chismes · Tap aquí',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
