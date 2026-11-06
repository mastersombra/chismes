import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../core/widgets/language_selector.dart';
import '../controllers/reset_password_controller.dart';
import '../state/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/password_field.dart';
import '../widgets/password_strength_indicator.dart';
import 'login_screen.dart';

/// Pantalla para establecer nueva contraseña
///
/// Se muestra después de verificar el código OTP en el flujo de reset password.
class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final ResetPasswordController _controller;

  String _currentPassword = '';

  @override
  void initState() {
    super.initState();
    _controller = getIt<ResetPasswordController>();
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final state = _controller.state;

    if (state is AuthPasswordUpdated) {
      // Password actualizada - mostrar mensaje y navegar a login
      _showSuccessAndNavigateToLogin();
    } else if (state is AuthError) {
      // Mostrar error
      _showError(state.message);
    }
  }

  void _showSuccessAndNavigateToLogin() {
    if (!mounted) return;

    // Mostrar dialog de éxito
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(AppLocalizations.passwordUpdatedSuccessTitle),
        content: Text(AppLocalizations.passwordUpdatedSuccessMessage),
        actions: [
          FilledButton(
            onPressed: () {
              // Cerrar dialog
              Navigator.pop(context);
              // Navegar a login (remover toda la pila)
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: Text(AppLocalizations.resetPasswordOkButton),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onChangePasswordPressed() {
    if (!_formKey.currentState!.validate()) return;

    _controller.updatePassword(
      newPassword: _newPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: const [
          LanguageSelector(),
        ],
      ),
      body: SafeArea(
        child: ChangeNotifierProvider.value(
          value: _controller,
          child: Consumer<ResetPasswordController>(
            builder: (context, controller, _) {
              final isLoading = controller.state is AuthLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icono
                      Icon(
                        Icons.lock_reset,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Título
                      Text(
                        AppLocalizations.resetPasswordSubtitle,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Descripción
                      Text(
                        AppLocalizations.resetPasswordDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Nueva contraseña
                      PasswordField(
                        controller: _newPasswordController,
                        enabled: !isLoading,
                        validator: FormValidators.password,
                        labelText: AppLocalizations.newPasswordHint,
                        onChanged: (value) {
                          setState(() => _currentPassword = value);
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Indicador de fortaleza
                      PasswordStrengthIndicator(password: _currentPassword),
                      const SizedBox(height: AppSpacing.lg),

                      // Confirmar contraseña
                      PasswordField(
                        controller: _confirmPasswordController,
                        enabled: !isLoading,
                        labelText: AppLocalizations.resetPasswordConfirmHint,
                        validator: (value) {
                          final passwordValidation = FormValidators.password(value);
                          if (passwordValidation != null) return passwordValidation;

                          // Validar que coincidan
                          if (value != _newPasswordController.text) {
                            return AppLocalizations.passwordsMustMatch;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Botón cambiar contraseña
                      AuthButton(
                        text: AppLocalizations.changePasswordButton,
                        onPressed: _onChangePasswordPressed,
                        isLoading: isLoading,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
