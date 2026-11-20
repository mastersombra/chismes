import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/moderation_item.dart';
import 'moderation_labels.dart';
import 'moderation_tag.dart';

/// Ítem de la cola en la lista: lo justo para decidir qué abrir primero
class ModerationItemCard extends StatelessWidget {
  /// Razones visibles antes de "+N"
  static const int maxVisibleReasons = 3;
  static const double thumbnailSize = 56;

  final ModerationItem item;
  final VoidCallback onTap;

  const ModerationItemCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final hiddenReasons = item.reasons.length - maxVisibleReasons;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (item.highPriority)
                    ModerationTag(
                      label: l10n.moderationHighPriority,
                      icon: Icons.priority_high,
                      background: scheme.errorContainer,
                      foreground: scheme.onErrorContainer,
                    ),
                  ModerationTag(label: ModerationLabels.source(context, item.source)),
                  if (item.autoHidden && item.isPending)
                    ModerationTag(
                      label: l10n.moderationAutoHidden,
                      icon: Icons.visibility_off_outlined,
                    ),
                  if (item.decisionSeverity != null)
                    ModerationTag(
                      label: ModerationLabels.severity(context, item.decisionSeverity!),
                      background: scheme.errorContainer,
                      foreground: scheme.onErrorContainer,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          item.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (item.displayImageUrl != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    _Thumbnail(url: item.displayImageUrl!),
                  ],
                ],
              ),
              if (item.reasons.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final reason in item.reasons.take(maxVisibleReasons))
                      ModerationTag(
                        label: ModerationLabels.reason(context, reason),
                        outlined: true,
                      ),
                    if (hiddenReasons > 0) ModerationTag(label: '+$hiddenReasons', outlined: true),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              DefaultTextStyle.merge(
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                child: Row(
                  children: [
                    if (item.reportCount > 0) ...[
                      Icon(Icons.flag_outlined, size: AppSpacing.lg, color: scheme.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.xs),
                      Text(l10n.moderationReportCount(item.reportCount)),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    if (item.hasAudio) ...[
                      Icon(Icons.mic_none, size: AppSpacing.lg, color: scheme.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.md),
                    ],
                    Expanded(
                      child: Text(
                        ModerationLabels.dateTime(context, item.decidedAt ?? item.queuedAt),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String url;

  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Image.network(
        url,
        width: ModerationItemCard.thumbnailSize,
        height: ModerationItemCard.thumbnailSize,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: ModerationItemCard.thumbnailSize,
          height: ModerationItemCard.thumbnailSize,
          color: scheme.surfaceContainerHighest,
          child: Icon(Icons.broken_image_outlined, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
