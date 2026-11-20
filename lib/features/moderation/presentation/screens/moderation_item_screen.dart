import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/moderation_item.dart';
import '../controllers/review_decision_controller.dart';
import '../widgets/moderation_labels.dart';
import '../widgets/moderation_tag.dart';
import '../widgets/reject_decision_sheet.dart';

/// Detalle de un ítem de la cola: todo lo necesario para decidir.
///
/// Hace `pop(true)` cuando el ítem deja de estar pendiente (decidido aquí o
/// por otro moderador) para que la lista lo saque.
class ModerationItemScreen extends StatefulWidget {
  final ModerationItem item;

  const ModerationItemScreen({super.key, required this.item});

  @override
  State<ModerationItemScreen> createState() => _ModerationItemScreenState();
}

class _ModerationItemScreenState extends State<ModerationItemScreen> {
  static const double _maxImageHeight = 360;

  late final ReviewDecisionController _controller;

  ModerationItem get _item => widget.item;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ReviewDecisionController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.moderationApproveConfirmTitle),
        content: Text(l10n.moderationApproveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('confirmApproveButton'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.moderationApprove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final outcome = await _controller.approve(_item.id);
    _finish(outcome, l10n.moderationApprovedMessage);
  }

  Future<void> _reject() async {
    final l10n = context.l10n;
    final selection = await RejectDecisionSheet.show(context);
    if (selection == null || !mounted) return;

    final outcome = await _controller.reject(
      _item.id,
      severity: selection.severity,
      reason: selection.reason,
      note: selection.note,
    );
    _finish(outcome, l10n.moderationRejectedMessage);
  }

  void _finish(DecisionOutcome outcome, String successMessage) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    switch (outcome) {
      case DecisionOutcome.done:
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
        Navigator.of(context).pop(true);
      case DecisionOutcome.alreadyDecided:
        messenger.showSnackBar(SnackBar(content: Text(l10n.moderationAlreadyDecided)));
        Navigator.of(context).pop(true);
      case DecisionOutcome.failed:
        final code = _controller.errorCode;
        messenger.showSnackBar(SnackBar(
          content: Text(code != null ? ErrorMessages.getMessage(context, code) : l10n.moderationDecisionError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moderationTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (_item.highPriority)
                ModerationTag(
                  label: l10n.moderationHighPriority,
                  icon: Icons.priority_high,
                  background: scheme.errorContainer,
                  foreground: scheme.onErrorContainer,
                ),
              ModerationTag(label: ModerationLabels.source(context, _item.source)),
              if (_item.autoHidden && _item.isPending)
                ModerationTag(label: l10n.moderationAutoHidden, icon: Icons.visibility_off_outlined),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SelectableText(
            _item.subject,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(_item.content, style: theme.textTheme.bodyLarge),
          if (_item.displayImageUrl != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: _maxImageHeight),
                child: Image.network(
                  _item.displayImageUrl!,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    color: scheme.surfaceContainerHighest,
                    child: Text(l10n.moderationImageUnavailable, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ],
          if (_item.hasAudio) ...[
            const SizedBox(height: AppSpacing.md),
            _InfoRow(icon: Icons.mic_none, text: l10n.moderationHasAudio),
          ],
          _Section(
            title: l10n.moderationReasonsTitle,
            children: [
              for (final reason in _item.reasons)
                _InfoRow(icon: Icons.label_outline, text: ModerationLabels.reason(context, reason)),
              if (_item.reportCount > 0)
                _InfoRow(icon: Icons.flag_outlined, text: l10n.moderationReportCount(_item.reportCount)),
              _InfoRow(icon: Icons.favorite_border, text: l10n.moderationInteractions(_item.interactions)),
            ],
          ),
          _Section(
            title: l10n.moderationAuthorLabel,
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                text: _item.authorName ?? l10n.moderationAuthorNoName,
              ),
              if (_item.publishedAnonymously)
                _InfoRow(
                  icon: Icons.visibility_off_outlined,
                  text: l10n.moderationAnonymousAuthor,
                  color: scheme.error,
                ),
              _InfoRow(
                icon: Icons.schedule,
                text: l10n.moderationQueuedAt(ModerationLabels.dateTime(context, _item.queuedAt)),
              ),
            ],
          ),
          if (!_item.isPending)
            _Section(
              title: l10n.moderationDecisionTitle,
              children: [
                _InfoRow(
                  icon: _item.status == ModerationQueueStatus.approved
                      ? Icons.check_circle_outline
                      : Icons.block,
                  text: _item.status == ModerationQueueStatus.approved
                      ? l10n.moderationTabApproved
                      : l10n.moderationTabRejected,
                ),
                if (_item.decisionSeverity != null)
                  _InfoRow(
                    icon: Icons.report_outlined,
                    text: '${l10n.moderationSeverityLabel}: '
                        '${ModerationLabels.severity(context, _item.decisionSeverity!)}',
                  ),
                if (_item.decisionReason != null)
                  _InfoRow(
                    icon: Icons.label_outline,
                    text: '${l10n.moderationRejectReasonLabel}: '
                        '${ModerationLabels.decisionReason(context, _item.decisionReason!)}',
                  ),
                if (_item.decisionNote != null)
                  _InfoRow(icon: Icons.notes, text: _item.decisionNote!),
                if (_item.decidedAt != null)
                  _InfoRow(
                    icon: Icons.schedule,
                    text: l10n.moderationDecidedAt(ModerationLabels.dateTime(context, _item.decidedAt!)),
                  ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: _item.isPending ? _buildActions(context) : null,
    );
  }

  Widget _buildActions(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final busy = _controller.isSubmitting;
            return Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('rejectButton'),
                    onPressed: busy ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error),
                    ),
                    icon: const Icon(Icons.block),
                    label: Text(l10n.moderationReject),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('approveButton'),
                    onPressed: busy ? null : _approve,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: AppSpacing.lg,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(l10n.moderationApprove),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.xl, color: color ?? scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
