import 'package:flutter/material.dart';
import 'package:chismes/core/l10n/l10n.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/feed_gossip.dart';

/// Etiqueta discreta sobre cada chisme del feed: de dónde es y si es tendencia.
///
/// Explica por qué aparece un chisme de otra ciudad/país ("📍 Madrid ·
/// 🔥 Tendencia"). Sin datos que mostrar, no ocupa espacio.
class FeedGossipLabel extends StatelessWidget {
  final FeedGossip gossip;

  const FeedGossipLabel({super.key, required this.gossip});

  @override
  Widget build(BuildContext context) {
    final cityName = gossip.cityName;
    final parts = <String>[
      if (cityName != null && cityName.isNotEmpty) '📍 $cityName',
      if (gossip.isTrending) '🔥 ${context.l10n.homePopularTrendingBadge}',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        parts.join('  ·  '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
