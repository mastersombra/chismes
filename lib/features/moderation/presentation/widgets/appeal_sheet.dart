import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/validation/form_validators.dart';
import '../../domain/validators/appeal_validator.dart';

/// Hoja para escribir una apelación. Devuelve el mensaje o null si se cancela.
class AppealSheet extends StatefulWidget {
  /// Asunto del contenido apelado (contexto para el usuario)
  final String subject;

  const AppealSheet({super.key, required this.subject});

  static Future<String?> show(BuildContext context, {required String subject}) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => AppealSheet(subject: subject),
    );
  }

  @override
  State<AppealSheet> createState() => _AppealSheetState();
}

class _AppealSheetState extends State<AppealSheet> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final trimmed = value?.trim();
    return FormValidators.required(context, trimmed, context.l10n.appealMessageLabel) ??
        FormValidators.minLength(context, trimmed, AppealValidator.minMessageLength) ??
        FormValidators.maxLength(context, trimmed, AppealValidator.maxMessageLength);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_messageController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.appealSheetTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                widget.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.appealSheetHint,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextFormField(
                key: const Key('appealMessageField'),
                controller: _messageController,
                maxLength: AppealValidator.maxMessageLength,
                minLines: 3,
                maxLines: 6,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                validator: _validate,
                decoration: InputDecoration(
                  labelText: l10n.appealMessageLabel,
                  hintText: l10n.appealMessageHint,
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
                      key: const Key('submitAppealButton'),
                      onPressed: _submit,
                      child: Text(l10n.appealSubmit),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
