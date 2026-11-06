import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/usecases/update_password_usecase.dart';
import '../state/auth_state.dart';

/// Controller para reset de contraseña
///
/// Maneja la actualización de contraseña después de verificar OTP.
@injectable
class ResetPasswordController extends ChangeNotifier {
  final UpdatePasswordUseCase _updatePassword;
  final AppLogger _logger;

  ResetPasswordController(
    this._updatePassword,
    this._logger,
  );

  AuthState _state = const AuthInitial();
  AuthState get state => _state;

  void _setState(AuthState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Actualiza la contraseña del usuario
  Future<void> updatePassword({
    required String newPassword,
  }) async {
    _setState(const AuthLoading());

    _logger.i('Updating password');

    final result = await _updatePassword(newPassword: newPassword);

    result.when(
      onFailure: (failure) {
        _logger.w('Update password failed',
            error: failure, context: {'code': failure.code});
        _setState(AuthError(failure));
      },
      onSuccess: (_) {
        _logger.i('Password updated successfully');
        _setState(const AuthPasswordUpdated());
      },
    );
  }

  /// Resetea el estado a inicial
  void resetState() {
    _setState(const AuthInitial());
  }
}
