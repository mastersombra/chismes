
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/l10n/locale_notifier.dart';
import '../../../../core/theme/theme_mode_notifier.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/profile_settings.dart';
import '../controllers/profile_controller.dart';
import 'settings_card.dart';
import 'package:chismes/core/l10n/l10n.dart';

/// Widget para la sección de configuraciones
class SettingsSection extends StatelessWidget {
  final ProfileSettings settings;
  final ProfileController controller;

  const SettingsSection({
    super.key,
    required this.settings,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.profileSettingsTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Notificaciones
        _buildCard(
          context,
          title: context.l10n.profileSettingsSectionNotifications,
          icon: Icons.notifications_outlined,
          children: [
            _buildSwitchTile(
              context,
              title: context.l10n.profileSettingsGeneralNotifications,
              subtitle: context.l10n.profileSettingsGeneralNotificationsSubtitle,
              value: settings.notificationsEnabled,
              onChanged: (value) => _updateSettings(
                context,
                settings.copyWith(notificationsEnabled: value),
              ),
            ),
            if (settings.notificationsEnabled) ...[
              const Divider(height: 1),
              _buildSwitchTile(
                context,
                title: context.l10n.profileSettingsPushNotifications,
                subtitle: context.l10n.profileSettingsPushNotificationsSubtitle,
                value: settings.pushNotifications,
                onChanged: (value) => _updateSettings(
                  context,
                  settings.copyWith(pushNotifications: value),
                ),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                context,
                title: context.l10n.profileSettingsEmailNotifications,
                subtitle: context.l10n.profileSettingsDailySummarySubtitle,
                value: settings.emailNotifications,
                onChanged: (value) => _updateSettings(
                  context,
                  settings.copyWith(emailNotifications: value),
                ),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                context,
                title: context.l10n.profileSettingsComments,
                subtitle: context.l10n.profileSettingsCommentsSubtitle,
                value: settings.commentsNotifications,
                onChanged: (value) => _updateSettings(
                  context,
                  settings.copyWith(commentsNotifications: value),
                ),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                context,
                title: context.l10n.profileSettingsNewFollowers,
                subtitle: context.l10n.profileSettingsNewFollowersSubtitle,
                value: settings.followNotifications,
                onChanged: (value) => _updateSettings(
                  context,
                  settings.copyWith(followNotifications: value),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Privacidad
        _buildCard(
          context,
          title: context.l10n.profileSettingsSectionPrivacy,
          icon: Icons.privacy_tip_outlined,
          children: [
            _buildListTile(
              context,
              title: context.l10n.profileSettingsPrivacyLevel,
              subtitle: _getPrivacyLevelText(context, settings.privacyLevel),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPrivacyDialog(context),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              context,
              title: context.l10n.profileSettingsShowEmail,
              subtitle: context.l10n.profileSettingsShowEmailSubtitle,
              value: settings.showEmail,
              onChanged: (value) => _updateSettings(
                context,
                settings.copyWith(showEmail: value),
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              context,
              title: context.l10n.profileSettingsShowActivity,
              subtitle: context.l10n.profileSettingsShowActivitySubtitle,
              value: settings.showActivity,
              onChanged: (value) => _updateSettings(
                context,
                settings.copyWith(showActivity: value),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Idioma y apariencia
        _buildCard(
          context,
          title: context.l10n.profileSettingsSectionAppearance,
          icon: Icons.palette_outlined,
          children: [
            _buildListTile(
              context,
              title: context.l10n.profileSettingsLanguage,
              // Idioma activo de la app (LocaleNotifier → MaterialApp), no settings.language
              subtitle: Localizations.localeOf(context).languageCode == 'es'
                  ? context.l10n.profileSettingsLanguageSpanish
                  : context.l10n.profileSettingsLanguageEnglish,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageDialog(context),
            ),
            const Divider(height: 1),
            // Tema: preferencia del teléfono (ThemeModeNotifier → MaterialApp)
            ListenableBuilder(
              listenable: getIt<ThemeModeNotifier>(),
              builder: (context, _) => _buildListTile(
                context,
                title: context.l10n.profileSettingsTheme,
                subtitle: _themeModeLabel(context, getIt<ThemeModeNotifier>().mode),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return SettingsCard(title: title, icon: icon, children: children);
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
    );
  }

  String _getPrivacyLevelText(BuildContext context, String level) {
    switch (level) {
      case 'public':
        return '${context.l10n.profileSettingsPrivacyPublic} - ${context.l10n.profileSettingsPrivacyPublicSubtitle}';
      case 'private':
        return '${context.l10n.profileSettingsPrivacyPrivate} - ${context.l10n.profileSettingsPrivacyPrivateSubtitle}';
      default:
        return context.l10n.profileSettingsPrivacyPublic;
    }
  }

  Future<void> _updateSettings(
    BuildContext context,
    ProfileSettings newSettings,
  ) async {
    final success = await controller.updateSetting(newSettings);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileSettingsUpdateError),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showPrivacyDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.profileSettingsPrivacyDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPrivacyOption(
              context,
              title: context.l10n.profileSettingsPrivacyPublic,
              subtitle: context.l10n.profileSettingsPrivacyPublicSubtitle,
              value: 'public',
              currentValue: settings.privacyLevel,
            ),
            _buildPrivacyOption(
              context,
              title: context.l10n.profileSettingsPrivacyPrivate,
              subtitle: context.l10n.profileSettingsPrivacyPrivateSubtitle,
              value: 'private',
              currentValue: settings.privacyLevel,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.commonCancel),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      await _updateSettings(
        context,
        settings.copyWith(privacyLevel: result),
      );
    }
  }

  Widget _buildPrivacyOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String value,
    required String currentValue,
  }) {
    final isSelected = value == currentValue;
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      onTap: () => Navigator.pop(context, value),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        final currentLanguage = Localizations.localeOf(context).languageCode;
        return AlertDialog(
          title: Text(context.l10n.profileSettingsLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(context.l10n.profileSettingsLanguageSpanish),
                leading: Icon(
                  currentLanguage == 'es'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: currentLanguage == 'es'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onTap: () => Navigator.pop(context, 'es'),
              ),
              ListTile(
                title: Text(context.l10n.profileSettingsLanguageEnglish),
                leading: Icon(
                  currentLanguage == 'en'
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: currentLanguage == 'en'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onTap: () => Navigator.pop(context, 'en'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.commonCancel),
            ),
          ],
        );
      },
    );

    if (result != null) {
      if (!context.mounted) return;

      // LocaleNotifier es la única fuente de verdad del idioma (persiste en
      // SharedPreferences). No se escribe en settings.language: los settings
      // remotos aún no se persisten y al recargarlos pisaban esta elección.
      await getIt<LocaleNotifier>().setLocale(Locale(result));
    }
  }

  String _themeModeLabel(BuildContext context, ThemeMode mode) => switch (mode) {
        ThemeMode.system => context.l10n.profileSettingsThemeSystem,
        ThemeMode.light => context.l10n.profileSettingsThemeLight,
        ThemeMode.dark => context.l10n.profileSettingsThemeDark,
      };

  Future<void> _showThemeDialog(BuildContext context) async {
    final notifier = getIt<ThemeModeNotifier>();
    final selected = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.profileSettingsTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ThemeMode.values)
              ListTile(
                key: Key('themeOption_${mode.name}'),
                title: Text(_themeModeLabel(context, mode)),
                leading: Icon(
                  notifier.mode == mode
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: notifier.mode == mode
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                onTap: () => Navigator.pop(dialogContext, mode),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.commonCancel),
          ),
        ],
      ),
    );
    if (selected != null) await notifier.setMode(selected);
  }
}
