import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/error/error_codes.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/media/image_compressor.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/validation/form_validators.dart';
import '../../../auth/domain/entities/user.dart';
import '../controllers/edit_profile_controller.dart';

/// Elige una foto y la devuelve comprimida (null = canceló o falló)
typedef AvatarPicker = Future<Uint8List?> Function(ImageSource source);

/// Límites de `profiles` (005) y de update-profile
const int kDisplayNameMaxLength = 50;
const int kBioMaxLength = 160;

/// Editar perfil: foto, nombre, @usuario y bio.
///
/// Todo se guarda vía update-profile: el servidor modera texto y foto,
/// aplica sanciones y el límite de cambio de @usuario. Devuelve `true` al
/// cerrar si se guardó algo.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.user, this.avatarPicker});

  final User user;

  /// Para tests; por defecto usa la galería/cámara y comprime a 400×400
  final AvatarPicker? avatarPicker;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final EditProfileController _controller;
  late final TextEditingController _username;
  late final TextEditingController _displayName;
  late final TextEditingController _bio;

  @override
  void initState() {
    super.initState();
    _controller = EditProfileController(getIt<AuthService>(), widget.user)
      ..addListener(_onChanged);
    _username = TextEditingController(text: widget.user.username ?? '')..addListener(_onChanged);
    _displayName = TextEditingController(text: widget.user.displayName ?? '')..addListener(_onChanged);
    _bio = TextEditingController(text: widget.user.bio ?? '')..addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _username.dispose();
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  bool get _dirty => _controller.hasChanges(
        username: _username.text,
        displayName: _displayName.text,
        bio: _bio.text,
      );

  /// Errores que se muestran bajo el campo @usuario (el resto, en un aviso)
  static const _usernameErrors = {
    ErrorCode.usernameAlreadyTaken,
    ErrorCode.usernameChangeCooldown,
    ErrorCode.usernameReserved,
  };

  String? get _usernameServerError {
    final failure = _controller.failure;
    if (failure == null || !_usernameErrors.contains(failure.code)) return null;
    if (failure.code == ErrorCode.usernameAlreadyTaken) {
      return context.l10n.profileSetupUsernameTaken;
    }
    return ErrorMessages.forFailure(context, failure);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final saved = await _controller.save(
      username: _username.text,
      displayName: _displayName.text,
      bio: _bio.text,
    );
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (saved) {
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.editProfileSaved)));
      Navigator.of(context).pop(true);
      return;
    }

    final failure = _controller.failure;
    if (failure != null && !_usernameErrors.contains(failure.code)) {
      messenger.showSnackBar(SnackBar(
        content: Text(ErrorMessages.forFailure(context, failure)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ));
    }
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = widget.avatarPicker ?? _defaultPicker;
    try {
      final bytes = await picker(source);
      if (bytes != null) _controller.setNewAvatar(bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.editProfilePhotoError)),
      );
    }
  }

  static Future<Uint8List?> _defaultPicker(ImageSource source) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return null;
    return ImageCompressor.compressAvatar(File(file.path));
  }

  Future<void> _showPhotoOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('editProfilePhotoGallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.editProfilePhotoGallery),
              onTap: () => Navigator.pop(sheetContext, 'gallery'),
            ),
            ListTile(
              key: const Key('editProfilePhotoCamera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.l10n.editProfilePhotoCamera),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            if (_controller.hasAvatar)
              ListTile(
                key: const Key('editProfilePhotoRemove'),
                leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                title: Text(
                  context.l10n.editProfilePhotoRemove,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
          ],
        ),
      ),
    );
    switch (action) {
      case 'gallery':
        await _pickAvatar(ImageSource.gallery);
      case 'camera':
        await _pickAvatar(ImageSource.camera);
      case 'remove':
        _controller.clearAvatar();
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.editProfileDiscardTitle),
        content: Text(context.l10n.editProfileDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            key: const Key('editProfileDiscardConfirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.editProfileDiscard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final saving = _controller.saving;

    return PopScope(
      canPop: !_dirty || saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.editProfileTitle),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: saving
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: SizedBox.square(
                        dimension: AppSpacing.xl,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      key: const Key('editProfileSave'),
                      onPressed: _dirty ? _save : null,
                      child: Text(context.l10n.editProfileSave),
                    ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Center(child: _buildAvatar(context, saving)),
                const SizedBox(height: AppSpacing.xxl),
                TextFormField(
                  key: const Key('editProfileDisplayName'),
                  controller: _displayName,
                  enabled: !saving,
                  maxLength: kDisplayNameMaxLength,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: context.l10n.profileSetupDisplayNameLabel,
                    hintText: context.l10n.displayNameHint,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => FormValidators.maxLength(context, v?.trim(), kDisplayNameMaxLength),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('editProfileUsername'),
                  controller: _username,
                  enabled: !saving,
                  autocorrect: false,
                  textCapitalization: TextCapitalization.none,
                  decoration: InputDecoration(
                    labelText: context.l10n.profileSetupUsernameLabel,
                    hintText: context.l10n.usernameHint,
                    prefixText: '@',
                    prefixIcon: const Icon(Icons.alternate_email),
                    border: const OutlineInputBorder(),
                    helperText: context.l10n.editProfileUsernameHelper,
                    helperMaxLines: 2,
                    errorText: _usernameServerError,
                    errorMaxLines: 3,
                  ),
                  validator: (v) => FormValidators.username(context, v?.trim()),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  key: const Key('editProfileBio'),
                  controller: _bio,
                  enabled: !saving,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: kBioMaxLength,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: context.l10n.profileSetupBioLabel,
                    hintText: context.l10n.bioHint,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => FormValidators.maxLength(context, v?.trim(), kBioMaxLength),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  context.l10n.editProfileModerationNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, bool saving) {
    final scheme = Theme.of(context).colorScheme;
    final newAvatar = _controller.newAvatar;
    final ImageProvider? image = newAvatar != null
        ? MemoryImage(newAvatar)
        : (_controller.hasAvatar ? NetworkImage(widget.user.avatarUrl!) : null);

    return Semantics(
      button: true,
      label: context.l10n.editProfileChangePhoto,
      child: InkWell(
        key: const Key('editProfileAvatar'),
        customBorder: const CircleBorder(),
        onTap: saving ? null : _showPhotoOptions,
        child: Stack(
          children: [
            CircleAvatar(
              radius: 56,
              backgroundColor: scheme.primaryContainer,
              backgroundImage: image,
              child: image == null
                  ? Icon(Icons.person, size: 56, color: scheme.onPrimaryContainer)
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: scheme.primary,
                child: Icon(Icons.photo_camera, size: 18, color: scheme.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
