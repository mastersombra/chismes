import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';

/// Pantalla de consentimiento de privacidad
///
/// **Muestra:**
/// - Información sobre datos recopilados
/// - Política de privacidad resumida
/// - Términos de uso resumidos
/// - Links a documentos completos
/// - Checkbox de aceptación
///
/// **Flujo:**
/// 1. Mostrar después de registro (primera vez)
/// 2. Usuario lee y acepta
/// 3. Guardar consentimiento en SharedPreferences
/// 4. Continuar a app
///
/// **Cumplimiento:**
/// - GDPR Art. 7 - Consentimiento
/// - CCPA - Transparencia
/// - LGPD - Consentimento
class PrivacyConsentScreen extends StatefulWidget {
  const PrivacyConsentScreen({super.key});

  @override
  State<PrivacyConsentScreen> createState() => _PrivacyConsentScreenState();
}

class _PrivacyConsentScreenState extends State<PrivacyConsentScreen> {
  bool _acceptedPrivacy = false;
  bool _acceptedTerms = false;
  bool _acceptedModeration = false;

  bool get _allAccepted =>
      _acceptedPrivacy && _acceptedTerms && _acceptedModeration;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.privacyConsentTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                context.l10n.privacyConsentHeader,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Subtítulo
              Text(
                context.l10n.privacyConsentSubheader,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Sección: Datos que recopilamos
              _buildSection(
                icon: '📊',
                title: context.l10n.privacyConsentDataCollectedTitle,
                items: [
                  context.l10n.privacyConsentDataCollectedItem1,
                  context.l10n.privacyConsentDataCollectedItem2,
                  context.l10n.privacyConsentDataCollectedItem3,
                  context.l10n.privacyConsentDataCollectedItem4,
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sección: Cómo los usamos
              _buildSection(
                icon: '🎯',
                title: context.l10n.privacyConsentDataUsageTitle,
                items: [
                  context.l10n.privacyConsentDataUsageItem1,
                  context.l10n.privacyConsentDataUsageItem2,
                  context.l10n.privacyConsentDataUsageItem3,
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sección: Moderación con OpenAI
              _buildSection(
                icon: '🤖',
                title: context.l10n.privacyConsentModerationTitle,
                items: [
                  context.l10n.privacyConsentModerationItem1,
                  context.l10n.privacyConsentModerationItem2,
                  context.l10n.privacyConsentModerationItem3,
                  context.l10n.privacyConsentModerationItem4,
                  context.l10n.privacyConsentModerationItem5,
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sección: Tu ubicación
              _buildSection(
                icon: '📍',
                title: context.l10n.privacyConsentLocationTitle,
                items: [
                  context.l10n.privacyConsentLocationItem1,
                  context.l10n.privacyConsentLocationItem2,
                  context.l10n.privacyConsentLocationItem3,
                  context.l10n.privacyConsentLocationItem4,
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sección: Tus derechos
              _buildSection(
                icon: '✅',
                title: context.l10n.privacyConsentRightsTitle,
                items: [
                  context.l10n.privacyConsentRightsItem1,
                  context.l10n.privacyConsentRightsItem2,
                  context.l10n.privacyConsentRightsItem3,
                  context.l10n.privacyConsentRightsItem4,
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Checkboxes de aceptación
              _buildCheckbox(
                value: _acceptedPrivacy,
                onChanged: (value) =>
                    setState(() => _acceptedPrivacy = value ?? false),
                label: _buildCheckboxLabel(
                  context.l10n.privacyConsentCheckboxPrivacy,
                  context.l10n.privacyConsentCheckboxPrivacyLink,
                  onTap: _openPrivacyPolicy,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              _buildCheckbox(
                value: _acceptedTerms,
                onChanged: (value) =>
                    setState(() => _acceptedTerms = value ?? false),
                label: _buildCheckboxLabel(
                  context.l10n.privacyConsentCheckboxTerms,
                  context.l10n.privacyConsentCheckboxTermsLink,
                  onTap: _openTermsOfService,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              _buildCheckbox(
                value: _acceptedModeration,
                onChanged: (value) =>
                    setState(() => _acceptedModeration = value ?? false),
                label: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: context.l10n.privacyConsentCheckboxModeration,
                      ),
                      TextSpan(
                        text: context.l10n.privacyConsentCheckboxModerationBold,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: context.l10n.privacyConsentCheckboxModerationSuffix,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Botón continuar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allAccepted ? _acceptAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                  ),
                  child: Text(
                    context.l10n.privacyConsentAcceptButton,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Botón cancelar (volver a login)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _cancel,
                  child: Text(context.l10n.privacyConsentDeclineButton),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Disclaimer
              Center(
                child: Text(
                  context.l10n.privacyConsentDisclaimer,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String icon,
    required String title,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.xl,
                bottom: AppSpacing.xs,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget label,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        Expanded(child: GestureDetector(
          onTap: () => onChanged(!value),
          child: label,
        )),
      ],
    );
  }

  Widget _buildCheckboxLabel(
    String normalText,
    String linkText, {
    required VoidCallback onTap,
  }) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: normalText),
          TextSpan(
            text: linkText,
            style: const TextStyle(
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
    );
  }

  Future<void> _openPrivacyPolicy() async {
    // En producción, esto debería abrir la política en web o in-app
    // Por ahora, mostrar un dialog con info
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.privacySettingsPrivacyPolicy),
        content: SingleChildScrollView(
          child: Text(
            '${context.l10n.privacyConsentDialogPrivacyAvailable}\n\n'
            '${context.l10n.privacyConsentDialogPrivacyUrl}\n\n'
            '${context.l10n.privacyConsentDialogPrivacyFile}\n\n'
            '${context.l10n.privacyConsentDialogPrivacySummary}\n'
            '${context.l10n.privacyConsentDialogPrivacyItem1}\n'
            '${context.l10n.privacyConsentDialogPrivacyItem2}\n'
            '${context.l10n.privacyConsentDialogPrivacyItem3}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _openTermsOfService() async {
    // En producción, esto debería abrir los términos en web o in-app
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.privacySettingsTermsOfUse),
        content: SingleChildScrollView(
          child: Text(
            '${context.l10n.privacyConsentDialogTermsAvailable}\n\n'
            '${context.l10n.privacyConsentDialogTermsUrl}\n\n'
            '${context.l10n.privacyConsentDialogTermsFile}\n\n'
            '${context.l10n.privacyConsentDialogTermsSummary}\n'
            '${context.l10n.privacyConsentDialogTermsItem1}\n'
            '${context.l10n.privacyConsentDialogTermsItem2}\n'
            '${context.l10n.privacyConsentDialogTermsItem3}\n'
            '${context.l10n.privacyConsentDialogTermsItem4}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptAndContinue() async {
    // Guardar consentimiento en SharedPreferences
    // TODO: Implementar guardado persistente
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setBool('privacy_consent_accepted', true);
    // await prefs.setString('privacy_consent_version', '1.0');
    // await prefs.setString('privacy_consent_date', DateTime.now().toIso8601String());

    if (!mounted) return;

    // ✅ Continuar a la app
    // AuthGate ya está mostrando MainNavigationScreen (usuario autenticado)
    // Solo cerramos esta pantalla modal
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    // Si no puede hacer pop, AuthGate ya está mostrando MainNavigationScreen
  }

  void _cancel() {
    // Volver a login
    Navigator.pop(context);
  }
}
