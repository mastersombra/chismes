import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/validation/form_validators.dart';

/// Campo de email con validación
///
/// Widget reutilizable para ingreso de email con:
/// - Validación de formato
/// - Keyboard type email
/// - Autocorrección deshabilitada
/// - Conversión automática a minúsculas
/// - Estilo consistente
class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? hintText;
  final Widget? prefixIcon;

  const EmailField({
    super.key,
    required this.controller,
    this.validator,
    this.enabled = true,
    this.hintText,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      textCapitalization: TextCapitalization.none,
      inputFormatters: [
        // Convierte automáticamente a minúsculas mientras el usuario escribe
        LowercaseTextInputFormatter(),
      ],
      decoration: InputDecoration(
        labelText: AppLocalizations.emailHint,
        hintText: hintText ?? AppLocalizations.emailHintPlaceholder,
        prefixIcon: prefixIcon ?? const Icon(Icons.email_outlined),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      validator: validator ?? FormValidators.email,
    );
  }
}

/// Formatter que convierte el texto a minúsculas automáticamente
class LowercaseTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}
