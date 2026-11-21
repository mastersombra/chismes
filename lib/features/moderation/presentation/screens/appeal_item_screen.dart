import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/moderation_appeal.dart';
import '../../domain/validators/appeal_validator.dart';
import '../controllers/appeal_decision_controller.dart';
import '../widgets/moderation_detail.dart';
import '../widgets/moderation_labels.dart';
import '../widgets/moderation_tag.dart';

/// Detalle de una apelación: el contenido, la decisión original y lo que
/// escribió el usuario. Aceptar anula la falta y republica el texto.
///
/// Hace `pop(true)` cuando deja de estar pendiente (decidida aquí o por otro
/// moderador) para que la lista la saque.
class AppealItemScreen extends StatefulWidget {
  final ModerationAppeal appeal;

  const AppealItemScreen({super.key, required this.appeal});

  @override
  State<AppealItemScreen> createState() => _AppealItemScreenState();
}

class _AppealItemScreenState extends State<AppealItemScreen> {
  late final AppealDecisionController _controller;

  ModerationAppeal get _appeal => widget.appeal;

  @override
  void initState() {
    super.initState();
    _controller = getIt<AppealDecisionController>();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decide({required bool accept}) async {
    final l10n = context.l10n;
    final note = await _AppealDecisionDialog.show(context, accept: accept);
    if (note == null || !mounted) return;

    final outcome = await _controller.decide(_appeal.id, accept: accept, note: note.isEmpty ? null : note);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case AppealDecisionOutcome.done:
        messenger.showSnackBar(SnackBar(
          content: Text(accept ? l10n.appealAcceptedMessage : l10n.appealRejectedMessage),
        ));
        Navigator.of(context).pop(true);
      case AppealDecisionOutcome.alreadyDecided:
        messenger.showSnackBar(SnackBar(content: Text(l10n.appealAlreadyDecided)));
        Navigator.of(context).pop(true);
      case AppealDecisionOutcome.needsAnotherModerator:
        messenger.showSnackBar(SnackBar(content: Text(l10n.appealNeedsAnotherModerator)));
      case AppealDecisionOutcome.failed:
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
      appBar: AppBar(title: Text(l10n.appealDetailTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              ModerationTag(label: ModerationLabels.appealStatus(context, _appeal.status)),
              ModerationTag(label: ModerationLabels.source(context, _appeal.originalSource)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SelectableText(
            _appeal.subject,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          SelectableText(_appeal.content, style: theme.textTheme.bodyLarge),
          DetailSection(
            title: l10n.appealUserMessageTitle,
            children: [
              SelectableText(
                _appeal.message,
                style: theme.textTheme.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
              ),
              DetailInfoRow(
                icon: Icons.schedule,
                text: l10n.appealSentAt(ModerationLabels.dateTime(context, _appeal.createdAt)),
              ),
            ],
          ),
          DetailSection(
            title: l10n.appealOriginalDecisionTitle,
            children: [
              if (_appeal.originalSeverity != null)
                DetailInfoRow(
                  icon: Icons.report_outlined,
                  text: '${l10n.moderationSeverityLabel}: '
                      '${ModerationLabels.severity(context, _appeal.originalSeverity!)}',
                ),
              if (_appeal.originalReason != null)
                DetailInfoRow(
                  icon: Icons.label_outline,
                  text: '${l10n.moderationRejectReasonLabel}: '
                      '${ModerationLabels.decisionReason(context, _appeal.originalReason!)}',
                ),
              for (final reason in _appeal.originalReasons)
                DetailInfoRow(icon: Icons.label_outline, text: ModerationLabels.reason(context, reason)),
              if (_appeal.originalReportCount > 0)
                DetailInfoRow(
                  icon: Icons.flag_outlined,
                  text: l10n.moderationReportCount(_appeal.originalReportCount),
                ),
              if (_appeal.originalNote != null) DetailInfoRow(icon: Icons.notes, text: _appeal.originalNote!),
              if (_appeal.originalDecidedAt != null)
                DetailInfoRow(
                  icon: Icons.schedule,
                  text: l10n.moderationDecidedAt(ModerationLabels.dateTime(context, _appeal.originalDecidedAt!)),
                ),
            ],
          ),
          DetailSection(
            title: l10n.moderationAuthorLabel,
            children: [
              DetailInfoRow(icon: Icons.person_outline, text: _appeal.authorName ?? l10n.moderationAuthorNoName),
              if (_appeal.publishedAnonymously)
                DetailInfoRow(
                  icon: Icons.visibility_off_outlined,
                  text: l10n.moderationAnonymousAuthor,
                  color: scheme.error,
                ),
            ],
          ),
          if (!_appeal.isPending)
            DetailSection(
              title: l10n.appealDecisionTitle,
              children: [
                DetailInfoRow(
                  icon: _appeal.status == AppealStatus.accepted ? Icons.check_circle_outline : Icons.block,
                  text: ModerationLabels.appealStatus(context, _appeal.status),
                ),
                if (_appeal.decisionNote != null) DetailInfoRow(icon: Icons.notes, text: _appeal.decisionNote!),
                if (_appeal.decidedAt != null)
                  DetailInfoRow(
                    icon: Icons.schedule,
                    text: l10n.moderationDecidedAt(ModerationLabels.dateTime(context, _appeal.decidedAt!)),
                  ),
              ],
            ),
        ],
      ),
      bottomNavigationBar: _appeal.isPending ? _buildActions(context) : null,
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
                  child: OutlinedButton(
                    key: const Key('rejectAppealButton'),
                    onPressed: busy ? null : () => _decide(accept: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: scheme.error,
                      side: BorderSide(color: scheme.error),
                    ),
                    child: Text(l10n.appealReject, textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const Key('acceptAppealButton'),
                    onPressed: busy ? null : () => _decide(accept: true),
                    child: busy
                        ? const SizedBox.square(
                            dimension: AppSpacing.lg,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.appealAccept, textAlign: TextAlign.center),
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

/// Confirmación con nota interna opcional. Devuelve la nota ('' sin nota) o
/// null si se cancela.
class _AppealDecisionDialog extends StatefulWidget {
  final bool accept;

  const _AppealDecisionDialog({required this.accept});

  static Future<String?> show(BuildContext context, {required bool accept}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _AppealDecisionDialog(accept: accept),
    );
  }

  @override
  State<_AppealDecisionDialog> createState() => _AppealDecisionDialogState();
}

class _AppealDecisionDialogState extends State<_AppealDecisionDialog> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accept = widget.accept;

    return AlertDialog(
      title: Text(accept ? l10n.appealAcceptConfirmTitle : l10n.appealRejectConfirmTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(accept ? l10n.appealAcceptConfirmBody : l10n.appealRejectConfirmBody),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('appealNoteField'),
              controller: _noteController,
              maxLength: AppealValidator.maxNoteLength,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.moderationNoteLabel,
                hintText: l10n.moderationNoteHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
        FilledButton(
          key: const Key('confirmAppealDecisionButton'),
          onPressed: () => Navigator.pop(context, _noteController.text.trim()),
          child: Text(accept ? l10n.appealAccept : l10n.appealReject),
        ),
      ],
    );
  }
}
