
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../moderation/presentation/screens/account_status_screen.dart';
import '../../../moderation/presentation/screens/moderation_queue_screen.dart';
import '../controllers/profile_controller.dart';
import 'edit_profile_screen.dart';
import '../../../auth/domain/entities/user.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/legal_card.dart';
import '../widgets/location_privacy_card.dart';
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
  late final LocationService _locationService;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ProfileController>();
    _locationService = getIt<LocationService>();
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

    // El idioma NO se sincroniza desde los settings: su única fuente de verdad
    // es LocaleNotifier (preferencia local). Los settings remotos aún son un
    // placeholder con 'es' fijo y al refrescar reseteaban el idioma elegido.

    // Mostrar errores si hay
    final errorMessage = _controller.getErrorMessage(context);
    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
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
                    _controller.getErrorMessage(context) ?? context.l10n.profileScreenErrorLoading,
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
                ProfileHeader(
                  user: user,
                  onEdit: () => _openEditProfile(context, user),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Estadísticas
                if (_controller.userStats != null)
                  ProfileStatsCard(stats: _controller.userStats!),

                const SizedBox(height: AppSpacing.xl),

                // Estado de la cuenta (sanciones y apelaciones): todos
                _buildAccountStatusEntry(context),
                const SizedBox(height: AppSpacing.md),

                // Panel de moderación: solo se muestra a moderadores (el
                // servidor valida el rol en cada llamada)
                if (user.isModerator) ...[
                  _buildModerationEntry(context),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Configuraciones
                if (_controller.settings != null)
                  SettingsSection(
                    settings: _controller.settings!,
                    controller: _controller,
                  ),

                const SizedBox(height: AppSpacing.lg),

                // Ubicación guardada en el teléfono (Política de privacidad 5.7)
                LocationPrivacyCard(locationService: _locationService),

                const SizedBox(height: AppSpacing.lg),

                // Política de privacidad y Términos de uso
                const LegalCard(),

                const SizedBox(height: AppSpacing.xxl),

                // Botón de cerrar sesión
                _buildSignOutButton(context),

                const SizedBox(height: AppSpacing.lg),

                // Eliminar cuenta (requisito de App Store y Google Play)
                _buildDeleteAccountButton(context),

                const SizedBox(height: AppSpacing.xxxl),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditProfile(BuildContext context, User user) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: user)),
    );
    if (saved == true) _controller.onProfileEdited();
  }

  Widget _buildAccountStatusEntry(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const Key('accountStatusEntry'),
        leading: const Icon(Icons.verified_user_outlined),
        title: Text(context.l10n.accountStatusEntryTitle),
        subtitle: Text(context.l10n.accountStatusEntrySubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AccountStatusScreen()),
        ),
      ),
    );
  }

  Widget _buildModerationEntry(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        key: const Key('moderationEntry'),
        leading: const Icon(Icons.shield_outlined),
        title: Text(context.l10n.moderationEntryTitle),
        subtitle: Text(context.l10n.moderationEntrySubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ModerationQueueScreen()),
        ),
      ),
    );
  }

  bool get _isBusy =>
      _controller.state == ProfileState.signingOut ||
      _controller.state == ProfileState.deletingAccount;

  Widget _buildSignOutButton(BuildContext context) {
    final isSigningOut = _controller.state == ProfileState.signingOut;

    return ElevatedButton.icon(
      onPressed: _isBusy ? null : () => _showSignOutDialog(context),
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

  Widget _buildDeleteAccountButton(BuildContext context) {
    final isDeleting = _controller.state == ProfileState.deletingAccount;
    final errorColor = Theme.of(context).colorScheme.error;

    return TextButton.icon(
      key: const Key('deleteAccountButton'),
      onPressed: _isBusy ? null : () => _handleDeleteAccount(context),
      style: TextButton.styleFrom(
        foregroundColor: errorColor,
        minimumSize: const Size(double.infinity, 48),
      ),
      icon: isDeleting
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(errorColor),
              ),
            )
          : const Icon(Icons.delete_forever_outlined),
      label: Text(
        isDeleting
            ? context.l10n.profileDeleteAccountDeleting
            : context.l10n.profileDeleteAccountButton,
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final confirmed = await DeleteAccountDialog.show(context);
    if (!confirmed || !context.mounted) return;

    // Capturados antes: si se borra, AuthGate reemplaza esta pantalla
    final messenger = ScaffoldMessenger.of(context);
    final successText = context.l10n.profileDeleteAccountSuccess;
    final errorText = context.l10n.profileDeleteAccountError;
    final errorColor = Theme.of(context).colorScheme.error;

    final deleted = await _controller.deleteAccount();
    messenger.showSnackBar(
      SnackBar(
        content: Text(deleted ? successText : errorText),
        backgroundColor: deleted ? null : errorColor,
      ),
    );
  }
}
