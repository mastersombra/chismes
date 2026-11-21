import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';

/// Diálogo de eliminación de cuenta con doble confirmación
///
/// 1. Explica qué se borra (y el registro anónimo de faltas que se conserva)
/// 2. Exige escribir la palabra de confirmación para habilitar el botón
///
/// Devuelve `true` solo si el usuario confirmó.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
    return confirmed ?? false;
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _confirmController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool _matches(String word) =>
      _confirmController.text.trim().toUpperCase() == word.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final word = l10n.profileDeleteAccountConfirmWord;
    final canConfirm = _matches(word);

    return AlertDialog(
      icon: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
      title: Text(l10n.profileDeleteAccountDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.profileDeleteAccountDialogContent),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.profileDeleteAccountDialogRetention,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              key: const Key('deleteAccountConfirmField'),
              controller: _confirmController,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.profileDeleteAccountConfirmLabel(word),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          key: const Key('deleteAccountConfirmButton'),
          onPressed: canConfirm ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          child: Text(l10n.profileDeleteAccountConfirmButton),
        ),
      ],
    );
  }
}
