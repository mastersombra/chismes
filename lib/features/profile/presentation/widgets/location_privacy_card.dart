import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/services/location_service.dart';
import 'settings_card.dart';

/// Perfil → Ubicación: ciudad guardada (con "Olvidar ubicación") y
/// "No guardar ubicación". Cumple la sección 5.7 de la Política de privacidad.
///
/// La ciudad solo vive en el teléfono (SharedPreferences, ver
/// [LocationService]); nada de esto toca el servidor.
class LocationPrivacyCard extends StatefulWidget {
  const LocationPrivacyCard({super.key, required this.locationService});

  final LocationService locationService;

  @override
  State<LocationPrivacyCard> createState() => _LocationPrivacyCardState();
}

class _LocationPrivacyCardState extends State<LocationPrivacyCard> {
  SavedLocation? _savedLocation;
  bool _dontSave = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait<Object?>([
      widget.locationService.getDefaultLocation(),
      widget.locationService.isAnonymousModeEnabled(),
    ]);
    if (!mounted) return;
    setState(() {
      _savedLocation = results[0] as SavedLocation?;
      _dontSave = results[1]! as bool;
      _loading = false;
    });
  }

  Future<void> _forget() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.locationPrivacyForgetDialogTitle),
        content: Text(context.l10n.locationPrivacyForgetDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            key: const Key('locationPrivacyForgetConfirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.forget),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await widget.locationService.clearDefaultLocation();
    if (!mounted) return;
    setState(() => _savedLocation = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.locationPrivacyForgotten)),
    );
  }

  Future<void> _setDontSave(bool value) async {
    setState(() => _saving = true);
    final ok = await widget.locationService.setAnonymousMode(value);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) {
        _dontSave = value;
        // Al activarlo, el servicio también borra la ciudad guardada
        if (value) _savedLocation = null;
      }
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.locationPrivacyError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = _savedLocation;
    return SettingsCard(
      title: context.l10n.locationPrivacyTitle,
      icon: Icons.location_on_outlined,
      children: [
        ListTile(
          key: const Key('locationPrivacySavedCity'),
          title: Text(context.l10n.locationPrivacySavedCity),
          subtitle: Text(
            _loading
                ? '…'
                : saved?.displayText ?? context.l10n.locationPrivacyNotSaved,
          ),
          trailing: saved == null
              ? null
              : IconButton(
                  key: const Key('locationPrivacyForgetButton'),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: context.l10n.locationPrivacyForget,
                  onPressed: _forget,
                ),
        ),
        const Divider(height: 1),
        SwitchListTile(
          key: const Key('locationPrivacyDontSaveSwitch'),
          title: Text(context.l10n.locationPrivacyDontSave),
          subtitle: Text(context.l10n.locationPrivacyDontSaveSubtitle),
          value: _dontSave,
          onChanged: _loading || _saving ? null : _setDontSave,
        ),
      ],
    );
  }
}
