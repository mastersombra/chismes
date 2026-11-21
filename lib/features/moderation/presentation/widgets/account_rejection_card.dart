import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/account_status.dart';
import 'moderation_labels.dart';
import 'moderation_tag.dart';

/// Un contenido propio rechazado: la falta, su sanción y la apelación
class AccountRejectionCard extends StatelessWidget {
  final AccountRejection rejection;

  /// Se está enviando la apelación de este rechazo
  final bool submitting;
  final VoidCallback onAppeal;

  const AccountRejectionCard({
    super.key,
    required this.rejection,
    required this.submitting,
    required this.onAppeal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final muted = theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (rejection.overturned)
                  ModerationTag(
                    label: l10n.accountStatusOverturned,
                    icon: Icons.check_circle_outline,
                    background: scheme.primaryContainer,
                    foreground: scheme.onPrimaryContainer,
                  )
                else ...[
                  if (rejection.severity != null)
                    ModerationTag(
                      label: ModerationLabels.severity(context, rejection.severity!),
                      background: scheme.errorContainer,
                      foreground: scheme.onErrorContainer,
                    ),
                  if (rejection.sanction != null)
                    ModerationTag(label: ModerationLabels.sanction(context, rejection.sanction!)),
                ],
                if (rejection.reason != null)
                  ModerationTag(
                    label: ModerationLabels.decisionReason(context, rejection.reason!),
                    outlined: true,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              rejection.subject,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              rejection.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(l10n.accountStatusRejectedOn(ModerationLabels.date(context, rejection.decidedAt)), style: muted),
            if (!rejection.overturned && rejection.points != null)
              Text(
                l10n.accountStatusPointsUntil(
                  rejection.points!,
                  ModerationLabels.date(context, rejection.expiresAt),
                ),
                style: muted,
              ),
            const SizedBox(height: AppSpacing.md),
            _AppealArea(rejection: rejection, submitting: submitting, onAppeal: onAppeal),
          ],
        ),
      ),
    );
  }
}

class _AppealArea extends StatelessWidget {
  final AccountRejection rejection;
  final bool submitting;
  final VoidCallback onAppeal;

  const _AppealArea({required this.rejection, required this.submitting, required this.onAppeal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final appeal = rejection.appeal;

    if (appeal != null) {
      final (icon, color) = switch (appeal.status) {
        AppealStatus.pending => (Icons.hourglass_top, scheme.onSurfaceVariant),
        AppealStatus.accepted => (Icons.check_circle_outline, scheme.primary),
        AppealStatus.rejected => (Icons.cancel_outlined, scheme.error),
      };
      return Row(
        children: [
          Icon(icon, size: AppSpacing.lg, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              ModerationLabels.appealStatus(context, appeal.status),
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      );
    }

    if (rejection.canAppeal) {
      return Row(
        children: [
          Expanded(
            child: Text(
              l10n.accountStatusAppealUntil(ModerationLabels.date(context, rejection.appealDeadline)),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          OutlinedButton.icon(
            key: Key('appealButton_${rejection.queueId}'),
            onPressed: submitting ? null : onAppeal,
            icon: submitting
                ? const SizedBox.square(
                    dimension: AppSpacing.lg,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.gavel_outlined),
            label: Text(l10n.appealButton),
          ),
        ],
      );
    }

    if (rejection.overturned) return const SizedBox.shrink();

    return Text(
      l10n.accountStatusAppealClosed,
      style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
    );
  }
}
