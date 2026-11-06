import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/validators/auth_validator.dart';

/// Indicador visual de fortaleza de contraseña
///
/// Muestra una barra de color y texto indicando qué tan fuerte es la contraseña.
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = AuthValidator.getPasswordStrengthLevel(password);
    final percentage = AuthValidator.calculatePasswordStrength(password);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getStrengthColor(strength),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _getStrengthText(strength),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _getStrengthColor(strength),
              ),
            ),
          ],
        ),
        if (strength != PasswordStrength.strong) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            _getHintText(password),
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  Color _getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  String _getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Débil';
      case PasswordStrength.medium:
        return 'Media';
      case PasswordStrength.strong:
        return 'Fuerte';
    }
  }

  String _getHintText(String password) {
    final hints = <String>[];

    if (password.length < 8) {
      hints.add('mínimo 8 caracteres');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      hints.add('una mayúscula');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      hints.add('una minúscula');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      hints.add('un número');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/;~`]'))) {
      hints.add('un símbolo');
    }

    if (hints.isEmpty) return '';

    return 'Agrega: ${hints.join(', ')}';
  }
}
