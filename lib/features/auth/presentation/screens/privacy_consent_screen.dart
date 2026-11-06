import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../../core/localization/app_localizations.dart';
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
        title: Text(AppLocalizations.privacyConsentTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              const Text(
                '🔒 Tu privacidad es importante',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Subtítulo
              const Text(
                'Antes de comenzar, queremos que sepas cómo manejamos tus datos.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Sección: Datos que recopilamos
              _buildSection(
                icon: '📊',
                title: '¿Qué datos recopilamos?',
                items: [
                  'Tu email y contraseña (encriptada)',
                  'Solo tu ciudad (NO coordenadas exactas)',
                  'Contenido de tus chismes (texto, imagen, audio)',
                  'Estadísticas de uso (para mejorar la app)',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sección: Cómo los usamos
              _buildSection(
                icon: '🎯',
                title: '¿Cómo los usamos?',
                items: [
                  'Proporcionar el servicio (publicar chismes)',
                  'Moderar contenido (mantener comunidad segura)',
                  'Mejorar la app (analizar uso)',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sección: Moderación con OpenAI
              _buildSection(
                icon: '🤖',
                title: 'Moderación de contenido',
                items: [
                  'Usamos OpenAI para analizar texto',
                  'Solo se envía el texto del chisme',
                  'NO enviamos tu nombre, ubicación ni otros datos',
                  'OpenAI retiene el texto por 30 días, luego lo elimina',
                  'NO se usa para entrenar modelos de IA',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sección: Tu ubicación
              _buildSection(
                icon: '📍',
                title: 'Tu ubicación',
                items: [
                  'Solo detectamos tu ciudad (ej: "Bogotá")',
                  'Coordenadas GPS se descartan inmediatamente',
                  'NUNCA almacenamos ni enviamos coordenadas exactas',
                  'Puedes elegir la ciudad manualmente',
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Sección: Tus derechos
              _buildSection(
                icon: '✅',
                title: 'Tus derechos',
                items: [
                  'Acceder a tus datos en cualquier momento',
                  'Eliminar tu cuenta y datos',
                  'Olvidar tu ubicación guardada',
                  'Exportar tus datos (portabilidad)',
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Checkboxes de aceptación
              _buildCheckbox(
                value: _acceptedPrivacy,
                onChanged: (value) =>
                    setState(() => _acceptedPrivacy = value ?? false),
                label: _buildCheckboxLabel(
                  'He leído y acepto la ',
                  'Política de Privacidad',
                  onTap: _openPrivacyPolicy,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              _buildCheckbox(
                value: _acceptedTerms,
                onChanged: (value) =>
                    setState(() => _acceptedTerms = value ?? false),
                label: _buildCheckboxLabel(
                  'He leído y acepto los ',
                  'Términos de Uso',
                  onTap: _openTermsOfService,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              _buildCheckbox(
                value: _acceptedModeration,
                onChanged: (value) =>
                    setState(() => _acceptedModeration = value ?? false),
                label: const Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Acepto que el texto de mis chismes se envíe a ',
                      ),
                      TextSpan(
                        text: 'OpenAI',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' para moderación de contenido (30 días de retención)',
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
                  child: const Text(
                    'Aceptar y Continuar',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Botón cancelar (volver a login)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _cancel,
                  child: Text(AppLocalizations.privacyConsentDeclineButton),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Disclaimer
              Center(
                child: Text(
                  'Al continuar, aceptas nuestras políticas',
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
        title: Text(AppLocalizations.privacySettingsPrivacyPolicy),
        content: const SingleChildScrollView(
          child: Text(
            'La política de privacidad completa está disponible en:\n\n'
            'https://chismes.app/privacy\n\n'
            'O en el archivo PRIVACY_POLICY.md del proyecto.\n\n'
            'Resumen:\n'
            '• Solo recopilamos datos necesarios\n'
            '• No vendemos tus datos\n'
            '• Puedes eliminar tu cuenta en cualquier momento',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.close),
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
        title: Text(AppLocalizations.privacySettingsTermsOfUse),
        content: const SingleChildScrollView(
          child: Text(
            'Los términos de uso completos están disponibles en:\n\n'
            'https://chismes.app/terms\n\n'
            'O en el archivo TERMS_OF_SERVICE.md del proyecto.\n\n'
            'Resumen:\n'
            '• Edad mínima: 13 años\n'
            '• No publicar contenido inapropiado\n'
            '• Moderación automática + manual\n'
            '• Podemos suspender cuentas que violen normas',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.close),
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
