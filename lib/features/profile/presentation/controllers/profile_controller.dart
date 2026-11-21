import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/custom_error_keys.dart';
import '../../../../core/error/error_codes.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/auth_service.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/profile_settings.dart';
import '../../domain/entities/user_stats.dart';
import '../../domain/usecases/delete_account.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/get_user_stats.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/update_settings.dart';

/// Estados del perfil
enum ProfileState {
  initial,
  loading,
  loaded,
  error,
  signingOut,
  deletingAccount,
}

/// Controlador para la pantalla de perfil
@injectable
class ProfileController extends ChangeNotifier {
  final GetUserStats _getUserStats;
  final GetSettings _getSettings;
  final UpdateSettings _updateSettings;
  final SignOut _signOut;
  final DeleteAccount _deleteAccount;
  final AuthService _authService;
  final AppLogger _logger;

  ProfileController(
    this._getUserStats,
    this._getSettings,
    this._updateSettings,
    this._signOut,
    this._deleteAccount,
    this._authService,
    this._logger,
  );

  ProfileState _state = ProfileState.initial;
  ProfileState get state => _state;

  User? get currentUser => _authService.currentUser;

  UserStats? _userStats;
  UserStats? get userStats => _userStats;

  ProfileSettings? _settings;
  ProfileSettings? get settings => _settings;

  ErrorCode? _errorCode;
  CustomErrorKey? _customErrorKey;

  /// Obtiene el mensaje de error traducido
  ///
  /// Debe llamarse desde la UI que tiene BuildContext.
  String? getErrorMessage(BuildContext context) {
    if (_customErrorKey != null) {
      return _customErrorKey!.getMessage(context);
    }

    if (_errorCode != null) {
      return ErrorMessages.getMessage(context, _errorCode!);
    }

    return null;
  }

  /// Carga los datos del perfil
  Future<void> loadProfile() async {
    if (_state == ProfileState.loading) return;

    _state = ProfileState.loading;
    _errorCode = null;
    _customErrorKey = null;
    notifyListeners();

    try {
      final userId = _authService.userId;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      _logger.d('Loading profile for userId: $userId');

      // Cargar estadísticas y configuraciones en paralelo
      final statsResult = await _getUserStats(userId);
      final settingsResult = await _getSettings(userId);

      // Manejar resultado de estadísticas
      statsResult.when(
        onFailure: (failure) {
          _logger.w('Failed to load stats: ${ErrorMessages.getMessageEnglish(failure.code)}');
          _userStats = const UserStats(
            gossipsCount: 0,
            commentsCount: 0,
            followersCount: 0,
            followingCount: 0,
          );
        },
        onSuccess: (stats) {
          _userStats = stats;
        },
      );

      // Manejar resultado de configuraciones
      settingsResult.when(
        onFailure: (failure) {
          _logger.w('Failed to load settings: ${ErrorMessages.getMessageEnglish(failure.code)}');
          _settings = ProfileSettings.defaultSettings();
        },
        onSuccess: (settings) {
          _settings = settings;
        },
      );

      _state = ProfileState.loaded;
      _logger.i('Profile loaded successfully');
    } catch (error, stackTrace) {
      _logger.e(
        'Error loading profile',
        error: error,
        stackTrace: stackTrace,
      );
      _customErrorKey = CustomErrorKey.profileScreenErrorLoading;
      _state = ProfileState.error;
    }

    notifyListeners();
  }

  /// Actualiza una configuración
  Future<bool> updateSetting(ProfileSettings newSettings) async {
    if (_state == ProfileState.loading) return false;

    try {
      final userId = _authService.userId;
      if (userId == null) {
        throw Exception('No authenticated user');
      }

      _logger.d('Updating settings');

      final result = await _updateSettings(userId, newSettings);

      return result.when(
        onFailure: (failure) {
          _logger.e('Failed to update settings: ${ErrorMessages.getMessageEnglish(failure.code)}');
          _errorCode = failure.code;
          _customErrorKey = null;
          notifyListeners();
          return false;
        },
        onSuccess: (_) {
          _settings = newSettings;
          _logger.i('Settings updated successfully');
          notifyListeners();
          return true;
        },
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Error updating settings',
        error: error,
        stackTrace: stackTrace,
      );
      _customErrorKey = CustomErrorKey.profileSettingsUpdateError;
      _errorCode = null;
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión del usuario
  Future<bool> signOut() async {
    if (_state == ProfileState.signingOut ||
        _state == ProfileState.deletingAccount) {
      return false;
    }

    _state = ProfileState.signingOut;
    _errorCode = null;
    _customErrorKey = null;
    notifyListeners();

    try {
      _logger.i('Signing out user');

      final result = await _signOut();

      return result.when(
        onFailure: (failure) {
          _logger.e('Failed to sign out: ${ErrorMessages.getMessageEnglish(failure.code)}');
          _errorCode = failure.code;
          _customErrorKey = null;
          _state = ProfileState.loaded;
          notifyListeners();
          return false;
        },
        onSuccess: (_) {
          _logger.i('User signed out successfully');
          // No cambiamos el estado aquí, el AuthService notificará el cambio
          return true;
        },
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Error signing out',
        error: error,
        stackTrace: stackTrace,
      );
      _customErrorKey = CustomErrorKey.profileSignOutError;
      _errorCode = null;
      _state = ProfileState.loaded;
      notifyListeners();
      return false;
    }
  }

  /// Elimina la cuenta del usuario (irreversible)
  ///
  /// La UI ya pidió doble confirmación. Si tiene éxito la sesión se cierra y
  /// AuthGate navega al login; si falla la cuenta sigue intacta y el estado
  /// vuelve a [ProfileState.loaded].
  Future<bool> deleteAccount() async {
    if (_state == ProfileState.deletingAccount ||
        _state == ProfileState.signingOut) {
      return false;
    }

    _state = ProfileState.deletingAccount;
    _errorCode = null;
    _customErrorKey = null;
    notifyListeners();

    final result = await _deleteAccount();

    return result.when(
      onFailure: (failure) {
        _logger.w('Failed to delete account: ${ErrorMessages.getMessageEnglish(failure.code)}');
        _errorCode = failure.code;
        _state = ProfileState.loaded;
        notifyListeners();
        return false;
      },
      onSuccess: (_) {
        _logger.i('Account deleted');
        // Igual que en signOut: AuthService notifica el cambio de sesión
        return true;
      },
    );
  }

  /// Refresca los datos del perfil
  Future<void> refresh() async {
    await loadProfile();
  }
}
