import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';

/// Banner que muestra cuando el email del usuario no está verificado
///
/// Muestra un mensaje claro y un botón para reenviar el email de verificación.
/// Se muestra típicamente en pantallas donde el usuario necesita tener
/// email verificado para realizar acciones (crear gossips, comentar, etc.).
class EmailVerificationBanner extends StatelessWidget {
  /// Callback cuando se presiona el botón de reenviar
  final VoidCallback onResend;

  /// Si el banner está en estado de carga (reenv iando email)
  final bool isLoading;

  const EmailVerificationBanner({
    super.key,
    required this.onResend,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha:0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono + Título
          Row(
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Verifica tu email',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Mensaje
          Text(
            'Necesitas verificar tu email para publicar chismes y comentar. '
            'Revisa tu bandeja de entrada y haz click en el enlace que te enviamos.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withValues(alpha:0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Botón de reenviar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isLoading ? null : onResend,
              icon: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary.withValues(alpha:0.5),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.send_outlined,
                      size: 18,
                      color: colorScheme.primary,
                    ),
              label: Text(
                isLoading ? 'Enviando...' : 'Reenviar email',
                style: TextStyle(
                  color: isLoading
                      ? colorScheme.onSurface.withValues(alpha:0.38)
                      : colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: isLoading
                      ? colorScheme.outline.withValues(alpha:0.5)
                      : colorScheme.primary,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
