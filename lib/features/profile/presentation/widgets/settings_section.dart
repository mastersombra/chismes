import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/profile_settings.dart';
import '../controllers/profile_controller.dart';

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
          'profile.settings.title'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Notificaciones
        _buildCard(
          context,
          title: 'profile.settings.section_notifications'.tr(),
          icon: Icons.notifications_outlined,
          children: [
            _buildSwitchTile(
              context,
              title: 'profile.settings.general_notifications'.tr(),
              subtitle: 'profile.settings.general_notifications_subtitle'.tr(),
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
                title: 'profile.settings.push_notifications'.tr(),
                subtitle: 'profile.settings.push_notifications_subtitle'.tr(),
                value: settings.pushNotifications,
                onChanged: (value) => _updateSettings(
                  context,
                  settings.copyWith(pushNotifications: value),
                ),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                context,
                title: 'profile.settings.email_notifications'.tr(),
                subtitle: 'profile.settings.daily_summary_subtitle'.tr(),
                value: settings.emailNotifications,
                onChanged: (value) => _updateSettings(
                  context,
                  settings.copyWith(emailNotifications: value),
                ),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                context,
                title: 'profile.settings.comments'.tr(),
                subtitle: 'profile.settings.comments_subtitle'.tr(),
                value: settings.commentsNotifications,
                onChanged: (value) => _updateSettings(
                  context,
                  settings.copyWith(commentsNotifications: value),
                ),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                context,
                title: 'profile.settings.new_followers'.tr(),
                subtitle: 'profile.settings.new_followers_subtitle'.tr(),
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
          title: 'profile.settings.section_privacy'.tr(),
          icon: Icons.privacy_tip_outlined,
          children: [
            _buildListTile(
              context,
              title: 'profile.settings.privacy_level'.tr(),
              subtitle: _getPrivacyLevelText(settings.privacyLevel),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPrivacyDialog(context),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              context,
              title: 'profile.settings.show_email'.tr(),
              subtitle: 'profile.settings.show_email_subtitle'.tr(),
              value: settings.showEmail,
              onChanged: (value) => _updateSettings(
                context,
                settings.copyWith(showEmail: value),
              ),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              context,
              title: 'profile.settings.show_activity'.tr(),
              subtitle: 'profile.settings.show_activity_subtitle'.tr(),
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
          title: 'profile.settings.section_appearance'.tr(),
          icon: Icons.palette_outlined,
          children: [
            _buildListTile(
              context,
              title: 'profile.settings.language'.tr(),
              subtitle: settings.language == 'es' ? 'profile.settings.language_spanish'.tr() : 'profile.settings.language_english'.tr(),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageDialog(context),
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              context,
              title: 'profile.settings.dark_mode'.tr(),
              subtitle: 'profile.settings.dark_mode_subtitle'.tr(),
              value: settings.darkMode,
              onChanged: (value) => _updateSettings(
                context,
                settings.copyWith(darkMode: value),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppSpacing.md),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
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

  String _getPrivacyLevelText(String level) {
    switch (level) {
      case 'public':
        return '${'profile.settings.privacy_public'.tr()} - ${'profile.settings.privacy_public_subtitle'.tr()}';
      case 'friends':
        return '${'profile.settings.privacy_friends'.tr()} - ${'profile.settings.privacy_friends_subtitle'.tr()}';
      case 'private':
        return '${'profile.settings.privacy_private'.tr()} - ${'profile.settings.privacy_private_subtitle'.tr()}';
      default:
        return 'profile.settings.privacy_public'.tr();
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
          content: Text('profile.settings.update_error'.tr()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showPrivacyDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.settings.privacy_dialog_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPrivacyOption(
              context,
              title: 'profile.settings.privacy_public'.tr(),
              subtitle: 'profile.settings.privacy_public_subtitle'.tr(),
              value: 'public',
              currentValue: settings.privacyLevel,
            ),
            _buildPrivacyOption(
              context,
              title: 'profile.settings.privacy_friends'.tr(),
              subtitle: 'profile.settings.privacy_friends_subtitle'.tr(),
              value: 'friends',
              currentValue: settings.privacyLevel,
            ),
            _buildPrivacyOption(
              context,
              title: 'profile.settings.privacy_private'.tr(),
              subtitle: 'profile.settings.privacy_private_subtitle'.tr(),
              value: 'private',
              currentValue: settings.privacyLevel,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
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
    return RadioGroup<String>(
      groupValue: currentValue,
      onChanged: (newValue) {
        if (newValue != null) {
          Navigator.pop(context, newValue);
        }
      },
      child: RadioListTile<String>(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
      ),
    );
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.settings.language'.tr()),
        content: RadioGroup<String>(
          groupValue: settings.language,
          onChanged: (value) {
            if (value != null) {
              Navigator.pop(context, value);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text('profile.settings.language_spanish'.tr()),
                value: 'es',
              ),
              RadioListTile<String>(
                title: Text('profile.settings.language_english'.tr()),
                value: 'en',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common.cancel'.tr()),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      await _updateSettings(
        context,
        settings.copyWith(language: result),
      );
    }
  }
}
