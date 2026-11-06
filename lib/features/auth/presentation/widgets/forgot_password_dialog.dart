import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/validation/form_validators.dart';
import 'email_field.dart';

/// Dialog para solicitar reset de contraseña
///
/// Solicita email y envía código OTP de 6 dígitos.
class ForgotPasswordDialog extends StatefulWidget {
  /// Callback cuando se envía el código exitosamente
  final Function(String email) onCodeSent;

  const ForgotPasswordDialog({
    super.key,
    required this.onCodeSent,
  });

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSendPressed() {
    if (!_formKey.currentState!.validate()) return;

    final email = FormValidators.normalizeEmail(_emailController.text);

    setState(() => _isLoading = true);

    // Llamar callback y cerrar dialog
    widget.onCodeSent(email);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.forgotPasswordTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono
              Icon(
                Icons.email_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Mensaje
              Text(
                AppLocalizations.forgotPasswordMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Email field
              EmailField(
                controller: _emailController,
                enabled: !_isLoading,
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Botón cancelar
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.cancel),
        ),

        // Botón enviar
        FilledButton(
          onPressed: _isLoading ? null : _onSendPressed,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppLocalizations.sendCodeButton),
        ),
      ],
    );
  }
}
