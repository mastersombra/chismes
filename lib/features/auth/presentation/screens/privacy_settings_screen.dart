import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/services/location_service.dart';
import 'package:get_it/get_it.dart';

/// Pantalla de configuración de privacidad
///
/// **Muestra:**
/// - Datos guardados localmente
/// - Opción de olvidar ubicación
/// - Opción de modo anónimo
/// - Dashboard de datos
/// - Links a políticas
///
/// **Funcionalidades:**
/// - Olvidar ubicación guardada
/// - Toggle modo anónimo (no guardar ubicación)
/// - Ver qué datos almacena la app
/// - Exportar datos (futuro)
/// - Eliminar cuenta
class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final LocationService _locationService = GetIt.I<LocationService>();

  SavedLocation? _savedLocation;
  bool _anonymousMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final location = await _locationService.getDefaultLocation();
      final prefs = await SharedPreferences.getInstance();
      final anonymousMode = prefs.getBool('anonymous_mode') ?? false;

      setState(() {
        _savedLocation = location;
        _anonymousMode = anonymousMode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.privacySettingsTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Sección: Ubicación
                _buildSection(
                  title: 'profile.privacy_settings.sections.location'.tr(),
                  children: [
                    ListTile(
                      title: Text(AppLocalizations.privacySettingsSavedCity),
                      subtitle: Text(
                        _savedLocation?.displayText ??
                        'profile.privacy_settings.location.not_saved'.tr(),
                      ),
                      trailing: _savedLocation != null
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: _forgetLocation,
                              tooltip: 'profile.privacy_settings.location.forget_tooltip'.tr(),
                            )
                          : null,
                    ),
                    SwitchListTile(
                      title: Text(AppLocalizations.privacySettingsAnonymousMode),
                      subtitle: Text(
                        'profile.privacy_settings.location.anonymous_mode_subtitle'.tr(),
                      ),
                      value: _anonymousMode,
                      onChanged: _toggleAnonymousMode,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      child: Text(
                        'profile.privacy_settings.location.anonymous_mode_description'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(),

                // Sección: Datos almacenados
                _buildSection(
                  title: 'profile.privacy_settings.sections.stored_data'.tr(),
                  children: [
                    ListTile(
                      title: Text(AppLocalizations.privacySettingsViewMyData),
                      subtitle: Text(AppLocalizations.privacySettingsViewMyDataSubtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataDashboardScreen(),
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(),

                // Sección: Políticas
                _buildSection(
                  title: 'profile.privacy_settings.sections.policies'.tr(),
                  children: [
                    ListTile(
                      title: Text(AppLocalizations.privacySettingsPrivacyPolicy),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: _openPrivacyPolicy,
                    ),
                    ListTile(
                      title: Text(AppLocalizations.privacySettingsTermsOfUse),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: _openTermsOfService,
                    ),
                  ],
                ),

                const Divider(),

                // Sección: Cuenta
                _buildSection(
                  title: 'profile.privacy_settings.sections.account'.tr(),
                  children: [
                    ListTile(
                      title: Text(
                        'profile.privacy_settings.account.delete_title'.tr(),
                        style: const TextStyle(color: Colors.red),
                      ),
                      subtitle: Text(
                        'profile.privacy_settings.account.delete_subtitle'.tr(),
                      ),
                      trailing: const Icon(Icons.delete_forever,
                          color: Colors.red),
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Future<void> _forgetLocation() async {
    // Confirmar
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.privacy_settings.dialogs.forget_location_title'.tr()),
        content: Text(
          'profile.privacy_settings.dialogs.forget_location_message'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.forget),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Olvidar ubicación
    await _locationService.clearDefaultLocation();

    // Recargar
    await _loadSettings();

    if (!mounted) return;

    // Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('profile.privacy_settings.snackbars.location_forgotten'.tr()),
      ),
    );
  }

  Future<void> _toggleAnonymousMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('anonymous_mode', value);

    setState(() => _anonymousMode = value);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'profile.privacy_settings.snackbars.anonymous_mode_on'.tr()
              : 'profile.privacy_settings.snackbars.anonymous_mode_off'.tr(),
        ),
      ),
    );
  }

  void _openPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.privacySettingsPrivacyPolicy),
        content: SingleChildScrollView(
          child: Text(
            'profile.privacy_settings.dialogs.privacy_policy_content'.tr(),
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

  void _openTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.privacySettingsTermsOfUse),
        content: SingleChildScrollView(
          child: Text(
            'profile.privacy_settings.dialogs.terms_of_use_content'.tr(),
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

  Future<void> _deleteAccount() async {
    // Confirmar con doble paso
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.privacy_settings.dialogs.delete_account_title'.tr()),
        content: Text(
          'profile.privacy_settings.dialogs.delete_account_message'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    // Segundo paso: Confirmar escribiendo "ELIMINAR"
    final controller = TextEditingController();
    final doubleConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.privacySettingsConfirmDeletion),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'profile.privacy_settings.dialogs.delete_account_confirm_prompt'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'profile.privacy_settings.dialogs.delete_account_confirm_placeholder'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.cancel),
          ),
          TextButton(
            onPressed: () {
              if (controller.text == 'ELIMINAR') {
                Navigator.pop(context, true);
              } else {
                Navigator.pop(context, false);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.permanentlyDelete),
          ),
        ],
      ),
    );

    if (doubleConfirmed != true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.privacySettingsDeletionCancelled)),
      );
      return;
    }

    // TODO: Implementar eliminación real con backend
    // await AuthService.deleteAccount();

    if (!mounted) return;

    // Logout y volver a login
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.privacySettingsAccountDeleted)),
    );

    Navigator.pushReplacementNamed(context, '/login');
  }
}

/// Dashboard de datos almacenados
class DataDashboardScreen extends StatefulWidget {
  const DataDashboardScreen({super.key});

  @override
  State<DataDashboardScreen> createState() => _DataDashboardScreenState();
}

class _DataDashboardScreenState extends State<DataDashboardScreen> {
  Map<String, dynamic> _data = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final data = <String, dynamic>{};
      for (final key in keys) {
        data[key] = prefs.get(key);
      }

      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.privacySettingsMyData),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportData,
            tooltip: 'profile.privacy_settings.export_data_tooltip'.tr(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data.isEmpty
              ? Center(
                  child: Text('profile.privacy_settings.no_local_data'.tr()),
                )
              : ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    // Explicación
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'profile.privacy_settings.local_data_info_title'.tr(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'profile.privacy_settings.local_data_info_message'.tr(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Datos
                    ...(_data.entries.map((entry) => Card(
                          margin:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: ListTile(
                            title: Text(
                              entry.key,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              entry.value.toString(),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ))),

                    const SizedBox(height: AppSpacing.lg),

                    // Botón eliminar todos
                    OutlinedButton.icon(
                      onPressed: _clearAllData,
                      icon: const Icon(Icons.delete_sweep, color: Colors.red),
                      label: const Text(
                        'Borrar todos los datos locales',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _exportData() async {
    // TODO: Implementar exportación real (JSON file)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('profile.privacy_settings.export_coming_soon'.tr()),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('profile.privacy_settings.dialogs.delete_all_data_title'.tr()),
        content: Text(
          'profile.privacy_settings.dialogs.delete_all_data_message'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.privacySettingsEraseButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    await _loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('profile.privacy_settings.snackbars.data_erased'.tr()),
      ),
    );
  }
}
