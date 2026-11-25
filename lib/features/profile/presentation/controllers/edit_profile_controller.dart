import 'package:flutter/foundation.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/auth_service.dart';
import '../../../auth/domain/entities/user.dart';

/// Estado de la pantalla Editar perfil.
///
/// Envía solo lo que cambió (el servidor modera texto y foto, aplica
/// sanciones y el límite de cambio de @usuario). Un campo vaciado se envía
/// como `''` para borrarlo.
class EditProfileController extends ChangeNotifier {
  EditProfileController(this._authService, this.initialUser);

  final AuthService _authService;

  /// Perfil al abrir la pantalla (referencia para saber qué cambió)
  final User initialUser;

  bool _saving = false;
  bool get saving => _saving;

  Failure? _failure;
  Failure? get failure => _failure;

  Uint8List? _newAvatar;

  /// Foto elegida y comprimida, aún sin guardar
  Uint8List? get newAvatar => _newAvatar;

  bool _removeAvatar = false;
  bool get removeAvatar => _removeAvatar;

  /// Hay foto para mostrar (la nueva o la actual, si no se quitó)
  bool get hasAvatar => _newAvatar != null || (initialUser.hasAvatar && !_removeAvatar);

  void setNewAvatar(Uint8List bytes) {
    _newAvatar = bytes;
    _removeAvatar = false;
    _failure = null;
    notifyListeners();
  }

  void clearAvatar() {
    _newAvatar = null;
    _removeAvatar = initialUser.hasAvatar;
    _failure = null;
    notifyListeners();
  }

  /// Hay algo para guardar
  bool hasChanges({
    required String username,
    required String displayName,
    required String bio,
  }) =>
      _newAvatar != null ||
      _removeAvatar ||
      _changed(username, initialUser.username) ||
      _changed(displayName, initialUser.displayName) ||
      _changed(bio, initialUser.bio);

  static bool _changed(String value, String? original) => value.trim() != (original ?? '').trim();

  /// Guarda los cambios. Retorna true si se guardó (o no había cambios).
  Future<bool> save({
    required String username,
    required String displayName,
    required String bio,
  }) async {
    if (_saving) return false;
    if (!hasChanges(username: username, displayName: displayName, bio: bio)) return true;

    _saving = true;
    _failure = null;
    notifyListeners();

    final result = await _authService.updateProfile(
      username: _changed(username, initialUser.username) ? username.trim() : null,
      displayName: _changed(displayName, initialUser.displayName) ? displayName.trim() : null,
      bio: _changed(bio, initialUser.bio) ? bio.trim() : null,
      avatar: _newAvatar,
      removeAvatar: _removeAvatar,
    );

    _saving = false;
    final saved = result.when(
      onFailure: (failure) {
        _failure = failure;
        return false;
      },
      onSuccess: (_) => true,
    );
    notifyListeners();
    return saved;
  }
}
