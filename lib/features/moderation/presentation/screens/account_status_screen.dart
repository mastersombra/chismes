import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/account_status.dart';
import '../controllers/account_status_controller.dart';
import '../widgets/account_rejection_card.dart';
import '../widgets/appeal_sheet.dart';
import '../widgets/moderation_labels.dart';

/// Perfil → Estado de la cuenta: sanción vigente, puntos de faltas,
/// contenido rechazado y apelaciones.
///
/// Lo que se muestra lo decide el servidor (`account-status`): la app no
/// calcula sanciones.
class AccountStatusScreen extends StatefulWidget {
  const AccountStatusScreen({super.key});

  @override
  State<AccountStatusScreen> createState() => _AccountStatusScreenState();
}

class _AccountStatusScreenState extends State<AccountStatusScreen> {
  late final AccountStatusController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<AccountStatusController>();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _appeal(AccountRejection rejection) async {
    final l10n = context.l10n;
    final message = await AppealSheet.show(context, subject: rejection.subject);
    if (message == null || !mounted) return;

    final outcome = await _controller.submitAppeal(queueId: rejection.queueId, message: message);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case AppealOutcome.done:
        messenger.showSnackBar(SnackBar(content: Text(l10n.appealSentMessage)));
      case AppealOutcome.notAllowed:
        messenger.showSnackBar(SnackBar(content: Text(l10n.appealNotAllowedMessage)));
      case AppealOutcome.failed:
        final code = _controller.appealErrorCode;
        messenger.showSnackBar(SnackBar(
          content: Text(code != null ? ErrorMessages.getMessage(context, code) : l10n.appealErrorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.accountStatusTitle)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final status = _controller.status;

          if (status == null && _controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (status == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: AppSpacing.xxxl,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(l10n.accountStatusLoadError, textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.tonal(onPressed: _controller.load, child: Text(l10n.commonRetry)),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _controller.load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _StatusHeader(status: status),
                const SizedBox(height: AppSpacing.lg),
                _PointsCard(status: status),
                if (status.inherited != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _InheritedCard(inherited: status.inherited!),
                ],
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.accountStatusRejectionsTitle, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.md),
                if (status.rejections.isEmpty)
                  Text(
                    l10n.accountStatusNoRejections,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  )
                else
                  for (final rejection in status.rejections) ...[
                    AccountRejectionCard(
                      rejection: rejection,
                      submitting: _controller.submittingQueueId == rejection.queueId,
                      onAppeal: () => _appeal(rejection),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Lo primero que ve el usuario: ¿puedo publicar?
class _StatusHeader extends StatelessWidget {
  final AccountStatus status;

  const _StatusHeader({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    final (IconData icon, Color background, Color foreground, String title, String body) = switch (status.state) {
      AccountState.ok => (
          Icons.verified_user_outlined,
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          l10n.accountStatusOkTitle,
          l10n.accountStatusOkBody,
        ),
      AccountState.restricted => (
          Icons.timer_outlined,
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
          status.restrictedUntil != null
              ? l10n.accountStatusRestrictedTitle(ModerationLabels.dateTime(context, status.restrictedUntil!))
              : l10n.accountStatusRestrictedTitleNoDate,
          l10n.accountStatusRestrictedBody,
        ),
      AccountState.suspended => (
          Icons.block,
          scheme.errorContainer,
          scheme.onErrorContainer,
          l10n.accountStatusSuspendedTitle,
          l10n.accountStatusSuspendedBody,
        ),
    };

    return Container(
      key: Key('accountState_${status.state.value}'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: foreground, size: AppSpacing.xxl),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(color: foreground, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: foreground)),
                if (status.hasPendingAppeal) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.accountStatusPendingAppeal,
                    style: theme.textTheme.bodySmall?.copyWith(color: foreground),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Puntos vigentes frente al umbral de suspensión, y cómo funcionan
class _PointsCard extends StatelessWidget {
  final AccountStatus status;

  const _PointsCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final limit = status.thresholds.suspension;
    final progress = limit > 0 ? (status.activePoints / limit).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.accountStatusPointsTitle, style: theme.textTheme.titleSmall)),
                Text(
                  l10n.accountStatusPointsValue(status.activePoints, limit),
                  key: const Key('activePoints'),
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.xs),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: AppSpacing.sm,
                backgroundColor: scheme.surfaceContainerHighest,
                color: progress >= 1 ? scheme.error : scheme.tertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.accountStatusPointsExplanation(
                status.thresholds.restrictionShort,
                status.thresholds.restrictionLong,
                status.thresholds.suspension,
                status.expiryDays,
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faltas de una cuenta anterior eliminada con el mismo email
class _InheritedCard extends StatelessWidget {
  final InheritedStrikes inherited;

  const _InheritedCard({required this.inherited});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.history),
        title: Text(l10n.accountStatusInheritedTitle),
        subtitle: Text(
          l10n.accountStatusInheritedBody(inherited.points, ModerationLabels.date(context, inherited.expiresAt)),
          style: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}
