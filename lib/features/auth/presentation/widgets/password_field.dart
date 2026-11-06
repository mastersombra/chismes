import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Campo de contraseña con toggle de visibilidad
///
/// Widget reutilizable para ingreso de contraseña con:
/// - Toggle para mostrar/ocultar contraseña
/// - Validación customizable
/// - Estilo consistente
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final ValueChanged<String>? onChanged;

  const PasswordField({
    super.key,
    required this.controller,
    this.validator,
    this.enabled = true,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _obscureText,
      autocorrect: false,
      enableSuggestions: false,
      textCapitalization: TextCapitalization.none,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Contraseña',
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon ?? const Icon(Icons.lock_outlined),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          onPressed: _toggleVisibility,
          tooltip: _obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
        ),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      validator: widget.validator,
    );
  }
}
