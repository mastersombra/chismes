import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';

/// Botones para login social (Google, Apple)
///
/// Widgets consistentes para OAuth login con estilo de cada proveedor.
class SocialLoginButtons extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final VoidCallback onApplePressed;
  final bool isLoading;

  const SocialLoginButtons({
    super.key,
    required this.onGooglePressed,
    required this.onApplePressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Google Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onGooglePressed,
            icon: Image.asset(
              'assets/images/google_logo.png',
              height: 24,
              width: 24,
              errorBuilder: (context, error, stackTrace) {
                // Fallback si no existe el asset
                return const Icon(Icons.g_mobiledata, size: 24);
              },
            ),
            label: Text(AppLocalizations.continueWithGoogle),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Apple Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : onApplePressed,
            icon: const Icon(Icons.apple, size: 24),
            label: Text(AppLocalizations.continueWithApple),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[300]!),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Botón individual de Google
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: Image.asset(
          'assets/images/google_logo.png',
          height: 24,
          width: 24,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.g_mobiledata, size: 24);
          },
        ),
        label: Text(AppLocalizations.continueWithGoogle),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}

/// Botón individual de Apple
class AppleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const AppleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: const Icon(Icons.apple, size: 24),
        label: Text(AppLocalizations.continueWithApple),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
    );
  }
}
