import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/validation/form_validators.dart';
import '../controllers/profile_setup_controller.dart';
import '../state/auth_state.dart';
import '../widgets/auth_button.dart';

/// Pantalla de configuración de perfil
///
/// Permite al usuario completar su perfil después del registro:
/// - Username (obligatorio para publicar)
/// - Display name (obligatorio)
/// - Avatar (opcional)
/// - Bio (opcional)
///
/// Soporta flujo progresivo: usuario puede saltarlo y completarlo después.
class ProfileSetupScreen extends StatefulWidget {
  final bool canSkip;

  const ProfileSetupScreen({
    super.key,
    this.canSkip = true,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();

  late final ProfileSetupController _controller;

  Timer? _usernameDebounce;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ProfileSetupController>();
    _controller.addListener(_onStateChanged);

    // ✅ AuthGate ya validó que el usuario está autenticado antes de llegar aquí
    // No necesitamos validaciones de sesión duplicadas
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _usernameDebounce?.cancel();
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onStateChanged() {
    final state = _controller.state;

    if (state is AuthSuccess) {
      // ✅ Perfil actualizado exitosamente
      // AuthGate ya está escuchando authStateChanges, pero como el usuario YA está
      // autenticado, AuthGate ya muestra MainNavigationScreen. Solo necesitamos volver.
      // Si esta pantalla se abrió desde onboarding, pop() la cierra.
      // Si esta pantalla es la raíz (después de registro), AuthGate ya muestra Home.
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      // Si no puede hacer pop, AuthGate ya está mostrando MainNavigationScreen
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

  void _onUsernameChanged(String value) {
    // Debounce para no hacer demasiadas requests
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () {
      if (value.isNotEmpty && value.length >= 3) {
        _controller.checkUsernameAvailability(value);
      } else {
        _controller.resetUsernameCheck();
      }
    });
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.usernameRequired;
    }
    if (value.length < 3) {
      return AppLocalizations.usernameTooShort;
    }
    if (value.length > 30) {
      return AppLocalizations.usernameTooLong;
    }
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(value)) {
      return AppLocalizations.usernameInvalidChars;
    }

    // Verificar disponibilidad
    if (_controller.usernameAvailable == false) {
      return AppLocalizations.profileSetupUsernameTaken;
    }

    return null;
  }

  void _onSavePressed() {
    if (!_formKey.currentState!.validate()) return;

    // Verificar que username esté disponible
    if (_controller.usernameAvailable != true) {
      _showError(AppLocalizations.profileSetupUsernameAvailabilityCheck);
      return;
    }

    _controller.updateProfile(
      username: _usernameController.text.trim(),
      displayName: _displayNameController.text.trim(),
      bio: _bioController.text.trim().isNotEmpty
          ? _bioController.text.trim()
          : null,
    );
  }

  void _onSkipPressed() {
    if (!widget.canSkip) return;

    // ✅ Usuario saltó configuración de perfil
    // AuthGate ya está mostrando MainNavigationScreen (usuario autenticado)
    // Solo cerramos esta pantalla
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    // Si no puede hacer pop, AuthGate ya está mostrando MainNavigationScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.profileSetupTitle),
        automaticallyImplyLeading: false,
        actions: [
          if (widget.canSkip)
            TextButton(
              onPressed: _onSkipPressed,
              child: Text(AppLocalizations.laterButton),
            ),
        ],
      ),
      body: SafeArea(
        child: ChangeNotifierProvider.value(
          value: _controller,
          child: Consumer<ProfileSetupController>(
            builder: (context, controller, _) {
              final isLoading = controller.state is AuthLoading;

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
                        AppLocalizations.profileSetupWelcome,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        AppLocalizations.profileSetupSubtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Avatar placeholder (TODO: implementar upload)
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[300],
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    // TODO: Implementar upload de avatar
                                    _showError(AppLocalizations.profileSetupAvatarUploadSoon);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Username field
                      TextFormField(
                        controller: _usernameController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.profileSetupUsernameLabel,
                          hintText: AppLocalizations.usernameHint,
                          prefixText: '@',
                          prefixIcon: const Icon(Icons.alternate_email),
                          suffixIcon: _buildUsernameSuffixIcon(controller),
                          border: const OutlineInputBorder(),
                          helperText: AppLocalizations.profileSetupUsernameHelper,
                          helperMaxLines: 2,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        onChanged: _onUsernameChanged,
                        validator: _validateUsername,
                        textCapitalization: TextCapitalization.none,
                        autocorrect: false,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Display name field
                      TextFormField(
                        controller: _displayNameController,
                        enabled: !isLoading,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.profileSetupDisplayNameLabel,
                          hintText: AppLocalizations.displayNameHint,
                          prefixIcon: const Icon(Icons.person_outline),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        validator: (v) => FormValidators.required(v, 'nombre a mostrar'),
                        textCapitalization: TextCapitalization.words,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // Bio field (opcional)
                      TextFormField(
                        controller: _bioController,
                        enabled: !isLoading,
                        maxLines: 3,
                        maxLength: 160,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.profileSetupBioLabel,
                          hintText: AppLocalizations.bioHint,
                          prefixIcon: const Icon(Icons.description_outlined),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Colors.blue,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                AppLocalizations.profileSetupInfoMessage,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Save button
                      AuthButton(
                        text: AppLocalizations.profileSetupSaveButton,
                        onPressed: _onSavePressed,
                        isLoading: isLoading,
                      ),

                      if (widget.canSkip) ...[
                        const SizedBox(height: AppSpacing.md),
                        TextButton(
                          onPressed: isLoading ? null : _onSkipPressed,
                          child: Text(AppLocalizations.doItLater),
                        ),
                      ],
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

  Widget? _buildUsernameSuffixIcon(ProfileSetupController controller) {
    if (controller.checkingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (controller.usernameAvailable == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (controller.usernameAvailable == false) {
      return const Icon(Icons.error, color: Colors.red);
    }

    return null;
  }
}
