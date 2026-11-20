import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/moderation_item.dart';
import '../../domain/entities/review_decision.dart';
import '../../domain/validators/review_decision_validator.dart';
import 'moderation_labels.dart';

/// Lo que eligió el moderador al rechazar
class RejectSelection {
  final ModerationSeverity severity;
  final RejectReason? reason;
  final String? note;

  const RejectSelection({required this.severity, this.reason, this.note});
}

/// Hoja para rechazar: gravedad obligatoria (base de sanciones), motivo y
/// nota opcionales. Devuelve [RejectSelection] o null si se cancela.
class RejectDecisionSheet extends StatefulWidget {
  const RejectDecisionSheet({super.key});

  static Future<RejectSelection?> show(BuildContext context) {
    return showModalBottomSheet<RejectSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const RejectDecisionSheet(),
    );
  }

  @override
  State<RejectDecisionSheet> createState() => _RejectDecisionSheetState();
}

class _RejectDecisionSheetState extends State<RejectDecisionSheet> {
  final _noteController = TextEditingController();
  ModerationSeverity? _severity;
  RejectReason? _reason;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _confirm() {
    final severity = _severity;
    if (severity == null) return;
    final note = _noteController.text.trim();
    Navigator.of(context).pop(RejectSelection(
      severity: severity,
      reason: _reason,
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.moderationRejectTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.moderationRejectHint,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.moderationSeverityLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final severity in ModerationSeverity.values)
                  ChoiceChip(
                    label: Text(ModerationLabels.severity(context, severity)),
                    selected: _severity == severity,
                    onSelected: (_) => setState(() => _severity = severity),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.moderationRejectReasonLabel, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final reason in RejectReason.values)
                  ChoiceChip(
                    label: Text(ModerationLabels.rejectReason(context, reason)),
                    selected: _reason == reason,
                    onSelected: (selected) => setState(() => _reason = selected ? reason : null),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _noteController,
              maxLength: ReviewDecisionValidator.maxNoteLength,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.moderationNoteLabel,
                hintText: l10n.moderationNoteHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.commonCancel),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    key: const Key('confirmRejectButton'),
                    onPressed: _severity == null ? null : _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                    ),
                    child: Text(l10n.moderationReject),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
