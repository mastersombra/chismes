import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/usecases/is_username_available.dart';
import '../../domain/usecases/update_profile.dart';
import '../state/auth_state.dart';

/// Controller para la pantalla de configuración de perfil
///
/// Maneja la actualización del perfil del usuario (username, display name, avatar, bio).
@injectable
class ProfileSetupController extends ChangeNotifier {
  final UpdateProfileUseCase _updateProfile;
  final IsUsernameAvailableUseCase _isUsernameAvailable;
  final AppLogger _logger;

  ProfileSetupController(
    this._updateProfile,
    this._isUsernameAvailable,
    this._logger,
  );

  AuthState _state = const AuthInitial();
  AuthState get state => _state;

  // Estado de validación de username
  bool? _usernameAvailable;
  bool? get usernameAvailable => _usernameAvailable;

  bool _checkingUsername = false;
  bool get checkingUsername => _checkingUsername;

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Actualiza el perfil del usuario
  Future<void> updateProfile({
    String? username,
    String? displayName,
    String? avatarUrl,
    String? bio,
  }) async {
    _setState(const AuthLoading());

    _logger.i('Update profile attempt', context: {
      'hasUsername': username != null,
      'hasDisplayName': displayName != null,
      'hasAvatar': avatarUrl != null,
      'hasBio': bio != null,
    });

    final result = await _updateProfile(
      username: username,
      displayName: displayName,
      avatarUrl: avatarUrl,
      bio: bio,
    );

    result.when(
      onFailure: (failure) {
        _logger.w('Update profile failed',
            error: failure, context: {'code': failure.code});
        _setState(AuthError(failure));
      },
      onSuccess: (user) {
        _logger.i('Update profile successful', context: {'userId': user.id});
        _setState(AuthSuccess(user));
      },
    );
  }

  /// Verifica si un username está disponible
  ///
  /// Actualiza [usernameAvailable] con el resultado.
  Future<void> checkUsernameAvailability(String username) async {
    if (username.isEmpty) {
      _usernameAvailable = null;
      notifyListeners();
      return;
    }

    _checkingUsername = true;
    _usernameAvailable = null;
    notifyListeners();

    _logger.d('Checking username availability', context: {'username': username});

    final result = await _isUsernameAvailable(username);

    result.when(
      onFailure: (failure) {
        _logger.w('Check username failed',
            error: failure, context: {'username': username});
        _checkingUsername = false;
        _usernameAvailable = null;
        notifyListeners();
      },
      onSuccess: (available) {
        _logger.d('Username availability checked',
            context: {'username': username, 'available': available});
        _checkingUsername = false;
        _usernameAvailable = available;
        notifyListeners();
      },
    );
  }

  /// Resetea el estado de verificación de username
  void resetUsernameCheck() {
    _usernameAvailable = null;
    _checkingUsername = false;
    notifyListeners();
  }

  /// Resetea el estado a inicial
  void resetState() {
    _setState(const AuthInitial());
    resetUsernameCheck();
  }
}
