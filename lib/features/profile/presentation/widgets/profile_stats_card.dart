import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/user_stats.dart';

/// Widget para mostrar estadísticas del usuario
class ProfileStatsCard extends StatelessWidget {
  final UserStats stats;

  /// Abre mis seguidores / seguidos (sin callback el contador no es tocable)
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  const ProfileStatsCard({
    super.key,
    required this.stats,
    this.onFollowersTap,
    this.onFollowingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.profileStatsTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.chat_bubble_outline,
                  label: context.l10n.profileStatsGossips,
                  value: stats.gossipsCount,
                  color: Colors.purple,
                ),
                _buildStatItem(
                  context,
                  icon: Icons.comment_outlined,
                  label: context.l10n.profileStatsComments,
                  value: stats.commentsCount,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  icon: Icons.people_outline,
                  label: context.l10n.profileStatsFollowers,
                  value: stats.followersCount,
                  color: Colors.green,
                  onTap: onFollowersTap,
                  tapKey: const Key('profileFollowersStat'),
                ),
                _buildStatItem(
                  context,
                  icon: Icons.person_add_outlined,
                  label: context.l10n.profileStatsFollowing,
                  value: stats.followingCount,
                  color: Colors.orange,
                  onTap: onFollowingTap,
                  tapKey: const Key('profileFollowingStat'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    VoidCallback? onTap,
    Key? tapKey,
  }) {
    final item = Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 28,
            color: color,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _formatNumber(value),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
    if (onTap == null) return item;
    return InkWell(
      key: tapKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: item,
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
