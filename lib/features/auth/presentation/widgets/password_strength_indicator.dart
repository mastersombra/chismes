import 'package:flutter/material.dart';
import 'package:chismes/core/l10n/l10n.dart';

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
              _getStrengthText(context, strength),
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
            _getHintText(context, password),
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

  String _getStrengthText(BuildContext context, PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return context.l10n.authPasswordStrengthWeak;
      case PasswordStrength.medium:
        return context.l10n.authPasswordStrengthMedium;
      case PasswordStrength.strong:
        return context.l10n.authPasswordStrengthStrong;
    }
  }

  String _getHintText(BuildContext context, String password) {
    final hints = <String>[];

    if (password.length < 8) {
      hints.add(context.l10n.authPasswordStrengthHintMinLength);
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      hints.add(context.l10n.authPasswordStrengthHintUppercase);
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      hints.add(context.l10n.authPasswordStrengthHintLowercase);
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      hints.add(context.l10n.authPasswordStrengthHintNumber);
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/;~`]'))) {
      hints.add(context.l10n.authPasswordStrengthHintSymbol);
    }

    if (hints.isEmpty) return '';

    return context.l10n.authPasswordStrengthHintAdd(hints.join(', '));
  }
}
