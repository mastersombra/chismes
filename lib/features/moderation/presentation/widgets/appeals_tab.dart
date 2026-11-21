import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/error/error_codes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/moderation_appeal.dart';
import '../controllers/appeals_controller.dart';
import 'moderation_labels.dart';
import 'moderation_tag.dart';

/// Pestaña "Apelaciones" del panel: filtro por estado + lista paginada
class AppealsTab extends StatelessWidget {
  /// Distancia al final de la lista para pedir la siguiente página
  static const double _loadMoreThreshold = 200;

  final AppealsController controller;
  final ValueChanged<ModerationAppeal> onOpen;

  const AppealsTab({super.key, required this.controller, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<AppealStatus>(
                showSelectedIcon: false,
                segments: [
                  for (final status in AppealStatus.values)
                    ButtonSegment(
                      value: status,
                      label: Text(
                        ModerationLabels.appealFilter(context, status),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                selected: {controller.selected},
                onSelectionChanged: (selection) => controller.select(selection.first),
              ),
            ),
          ),
          Expanded(child: _buildList(context, l10n)),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, AppLocalizations l10n) {
    final status = controller.selected;
    final state = controller.current;

    if (!state.loaded || (state.isLoading && state.items.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorCode != null && state.items.isEmpty) {
      final forbidden = state.errorCode == ErrorCode.forbidden;
      return _Message(
        icon: forbidden ? Icons.lock_outline : Icons.cloud_off_outlined,
        title: forbidden ? l10n.moderationForbidden : l10n.moderationLoadError,
        action: forbidden
            ? null
            : FilledButton.tonal(onPressed: () => controller.refresh(status), child: Text(l10n.commonRetry)),
      );
    }

    if (state.items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => controller.refresh(status),
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: _Message(
                icon: status == AppealStatus.pending ? Icons.task_alt : Icons.history,
                title: status == AppealStatus.pending ? l10n.appealsEmptyPending : l10n.moderationEmptyHistory,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.refresh(status),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - _loadMoreThreshold) controller.loadMore(status);
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final appeal = state.items[index];
            return AppealCard(appeal: appeal, onTap: () => onOpen(appeal));
          },
        ),
      ),
    );
  }
}

/// Apelación en la lista: qué se rechazó y qué dice el usuario
class AppealCard extends StatelessWidget {
  final ModerationAppeal appeal;
  final VoidCallback onTap;

  const AppealCard({super.key, required this.appeal, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
                  if (appeal.originalSeverity != null)
                    ModerationTag(
                      label: ModerationLabels.severity(context, appeal.originalSeverity!),
                      background: scheme.errorContainer,
                      foreground: scheme.onErrorContainer,
                    ),
                  if (appeal.originalReason != null)
                    ModerationTag(
                      label: ModerationLabels.decisionReason(context, appeal.originalReason!),
                      outlined: true,
                    ),
                  if (!appeal.isPending)
                    ModerationTag(label: ModerationLabels.appealStatus(context, appeal.status)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                appeal.subject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '“${appeal.message}”',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                ModerationLabels.dateTime(context, appeal.decidedAt ?? appeal.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? action;

  const _Message({required this.icon, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.xxxl, color: muted),
            const SizedBox(height: AppSpacing.lg),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
