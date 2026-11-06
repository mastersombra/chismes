import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../../core/widgets/language_selector.dart';
import '../controllers/login_controller.dart';
import '../controllers/otp_verification_controller.dart';
import '../state/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/email_field.dart';
import '../widgets/forgot_password_dialog.dart';
import '../widgets/password_field.dart';
import '../widgets/social_login_buttons.dart';
import 'otp_verification_screen.dart';
import 'reset_password_screen.dart';
import 'signup_screen.dart';

/// Pantalla de inicio de sesión
///
/// Permite al usuario autenticarse con:
/// - Email + Contraseña
/// - Google OAuth
/// - Apple OAuth
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<LoginController>();
    _controller.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final state = _controller.state;

    if (state is AuthSuccess) {
      // ✅ Login exitoso - AuthGate detectará el cambio automáticamente
      // No navegamos manualmente, AuthGate escucha authStateChanges
      // y navega a MainNavigationScreen cuando detecta usuario autenticado
    } else if (state is AuthError) {
      // Mostrar error
      _showError(state.message);
    }
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

  void _onSignInPressed() {
    if (!_formKey.currentState!.validate()) return;

    _controller.signInWithEmail(
      email: FormValidators.normalizeEmail(_emailController.text),
      password: _passwordController.text,
    );
  }

  void _onGooglePressed() {
    _controller.signInWithGoogle();
  }

  void _onApplePressed() {
    _controller.signInWithApple();
  }

  void _onSignUpPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SignupScreen(),
      ),
    );
  }

  void _onForgotPasswordPressed() {
    showDialog(
      context: context,
      builder: (_) => ForgotPasswordDialog(
        onCodeSent: (email) {
          // Cerrar dialog
          Navigator.pop(context);

          // Enviar OTP
          _controller.resetPassword(email: email);

          // Esperar un momento para que el state se actualice
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;

            // Navegar a OTP screen
            _navigateToOtpVerification(email);
          });
        },
      ),
    );
  }

  void _navigateToOtpVerification(String email) {
    // Crear controller de OTP con el email para reset password
    final otpController = OtpVerificationController(
      authRepository: getIt(),
      logger: getIt<AppLogger>(),
      email: email,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          controller: otpController,
          onSuccess: () {
            // Después de verificar OTP, navegar a reset password screen
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(email: email),
              ),
            );
          },
        ),
      ),
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
          child: Consumer<LoginController>(
            builder: (context, controller, _) {
              final isLoading = controller.state is AuthLoading;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.xl),

                      // Logo o título
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Chismes',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppLocalizations.appTagline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
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
                        validator: FormValidators.password,
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : _onForgotPasswordPressed,
                          child: Text(AppLocalizations.forgotPassword),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Sign in button
                      AuthButton(
                        text: AppLocalizations.signInButton,
                        onPressed: _onSignInPressed,
                        isLoading: isLoading,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey[400])),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            child: Text(
                              AppLocalizations.orContinueWith,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey[400])),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Social login buttons
                      SocialLoginButtons(
                        onGooglePressed: _onGooglePressed,
                        onApplePressed: _onApplePressed,
                        isLoading: isLoading,
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Sign up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${AppLocalizations.noAccount} ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: isLoading ? null : _onSignUpPressed,
                            child: Text(AppLocalizations.signUpLink),
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
      ),
    );
  }
}
