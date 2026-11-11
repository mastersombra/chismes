
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/l10n/locale_notifier.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/profile_controller.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_stats_card.dart';
import '../widgets/settings_section.dart';
import 'package:chismes/core/l10n/l10n.dart';

/// Pantalla de perfil del usuario
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ProfileController>();
    _controller.addListener(_onControllerChanged);

    // Cargar datos del perfil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadProfile();
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;

    // Sincronizar idioma con LocaleNotifier cuando se cargan los settings
    final settings = _controller.settings;
    final localeNotifier = getIt<LocaleNotifier>();
    if (settings != null && localeNotifier.locale.languageCode != settings.language) {
      // Cambiar el idioma de la app si no coincide con los settings
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          localeNotifier.setLocale(Locale(settings.language));
        }
      });
    }

    // Mostrar errores si hay
    if (_controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage!),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _handleRefresh() async {
    await _controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.navigationProfile),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _handleRefresh,
            tooltip: context.l10n.profileScreenRefreshTooltip,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.state == ProfileState.loading &&
              _controller.currentUser == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_controller.state == ProfileState.error &&
              _controller.currentUser == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _controller.errorMessage ?? context.l10n.profileScreenErrorLoading,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: _handleRefresh,
                    child: Text(context.l10n.commonBack),
                  ),
                ],
              ),
            );
          }

          final user = _controller.currentUser;
          if (user == null) {
            return Center(
              child: Text(context.l10n.profileScreenNoUser),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // Header con foto de perfil y nombre
                ProfileHeader(user: user),

                const SizedBox(height: AppSpacing.xl),

                // Estadísticas
                if (_controller.userStats != null)
                  ProfileStatsCard(stats: _controller.userStats!),

                const SizedBox(height: AppSpacing.xl),

                // Configuraciones
                if (_controller.settings != null)
                  SettingsSection(
                    settings: _controller.settings!,
                    controller: _controller,
                  ),

                const SizedBox(height: AppSpacing.xxl),

                // Botón de cerrar sesión
                _buildSignOutButton(context),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    final isSigningOut = _controller.state == ProfileState.signingOut;

    return ElevatedButton.icon(
      onPressed: isSigningOut ? null : () => _showSignOutDialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
      ),
      icon: isSigningOut
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Icon(Icons.logout),
      label: Text(isSigningOut ? context.l10n.profileScreenSigningOut : context.l10n.profileScreenSignOutButton),
    );
  }

  Future<void> _showSignOutDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.profileScreenSignOutDialogTitle),
        content: Text(context.l10n.profileScreenSignOutDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.profileScreenSignOutButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _controller.signOut();
      // ✅ AuthGate detectará el cambio automáticamente y navegará a LoginScreen
      // No necesitamos navegar manualmente
    }
  }
}
