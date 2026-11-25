import 'package:flutter/material.dart';
import '../../../../core/legal/legal_consent_text.dart';

import '../../../../core/di/injection_container.dart';
import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../core/widgets/language_selector.dart';
import '../controllers/signup_controller.dart';
import '../controllers/otp_verification_controller.dart';
import '../state/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/email_field.dart';
import '../widgets/password_field.dart';
import '../widgets/password_strength_indicator.dart';
import 'profile_setup_screen.dart';
import 'otp_verification_screen.dart';

/// Pantalla de registro de nuevo usuario
///
/// Permite crear cuenta con email y contraseña.
///
/// Flujo:
/// 1. Usuario ingresa email y contraseña
/// 2. Se envía código OTP de 6 dígitos al email
/// 3. Navega a OtpVerificationScreen
/// 4. Usuario verifica OTP
/// 5. Navega a ProfileSetupScreen
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final SignupController _controller;

  String _currentPassword = '';

  @override
  void initState() {
    super.initState();
    _controller = getIt<SignupController>();
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final state = _controller.state;

    if (state is AuthOtpSent) {
      // OTP enviado - navegar a verificación
      _navigateToOtpVerification(state.email);
    } else if (state is AuthSuccess) {
      // Autenticación exitosa (flujo legacy o después de OTP)
      _navigateToProfileSetup();
    } else if (state is AuthError) {
      // Mostrar error - traducir mensaje con BuildContext
      _showError(state.getMessage(context));
    }
  }

  void _navigateToOtpVerification(String email) {
    // Crear controller de OTP con el email
    final otpController = OtpVerificationController(
      authRepository: getIt(),
      logger: getIt<AppLogger>(),
      email: email,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          controller: otpController,
        ),
      ),
    );
  }

  void _navigateToProfileSetup() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileSetupScreen(),
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

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return context.l10n.signupConfirmPasswordRequired;
    }
    if (value != _passwordController.text) {
      return context.l10n.signupPasswordsMustMatch;
    }
    return null;
  }

  void _onSignUpPressed() {
    if (!_formKey.currentState!.validate()) return;

    _controller.signUpWithEmail(
      email: FormValidators.normalizeEmail(_emailController.text),
      password: _passwordController.text,
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
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final isLoading = _controller.state is AuthLoading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Título
                    Text(
                      context.l10n.signupSubtitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      context.l10n.signupDescription,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Email field
                    EmailField(
                      controller: _emailController,
                      enabled: !isLoading,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Password field
                    PasswordField(
                      controller: _passwordController,
                      enabled: !isLoading,
                      labelText: context.l10n.passwordHint,
                      onChanged: (value) {
                        setState(() {
                          _currentPassword = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return context.l10n.signupPasswordRequired;
                        }
                        if (value.length < 8) {
                          return context.l10n.signupPasswordMinLength;
                        }
                        return null;
                      },
                    ),

                    // Password strength indicator
                    PasswordStrengthIndicator(password: _currentPassword),

                    const SizedBox(height: AppSpacing.lg),

                    // Confirm password field
                    PasswordField(
                      controller: _confirmPasswordController,
                      enabled: !isLoading,
                      labelText: context.l10n.confirmPasswordHint,
                      validator: _validateConfirmPassword,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Aceptación de las políticas (el servidor la registra
                    // al crear la cuenta)
                    const LegalConsentText(),

                    const SizedBox(height: AppSpacing.xl),

                    // Sign up button
                    AuthButton(
                      text: context.l10n.signUpButton,
                      onPressed: _onSignUpPressed,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${context.l10n.alreadyHaveAccount} ',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: Text(context.l10n.signInLink),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
