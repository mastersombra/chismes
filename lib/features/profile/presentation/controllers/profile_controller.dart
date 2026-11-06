import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_messages.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/auth_service.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/profile_settings.dart';
import '../../domain/entities/user_stats.dart';
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
}

/// Controlador para la pantalla de perfil
@injectable
class ProfileController extends ChangeNotifier {
  final GetUserStats _getUserStats;
  final GetSettings _getSettings;
  final UpdateSettings _updateSettings;
  final SignOut _signOut;
  final AuthService _authService;
  final AppLogger _logger;

  ProfileController(
    this._getUserStats,
    this._getSettings,
    this._updateSettings,
    this._signOut,
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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Carga los datos del perfil
  Future<void> loadProfile() async {
    if (_state == ProfileState.loading) return;

    _state = ProfileState.loading;
    _errorMessage = null;
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
          _logger.w('Failed to load stats: ${ErrorMessages.getMessage(failure.code)}');
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
          _logger.w('Failed to load settings: ${ErrorMessages.getMessage(failure.code)}');
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
      _errorMessage = 'Error al cargar el perfil';
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
          final message = ErrorMessages.getMessage(failure.code);
          _logger.e('Failed to update settings: $message');
          _errorMessage = message;
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
      _errorMessage = 'Error al actualizar configuración';
      notifyListeners();
      return false;
    }
  }

  /// Cierra la sesión del usuario
  Future<bool> signOut() async {
    if (_state == ProfileState.signingOut) return false;

    _state = ProfileState.signingOut;
    _errorMessage = null;
    notifyListeners();

    try {
      _logger.i('Signing out user');

      final result = await _signOut();

      return result.when(
        onFailure: (failure) {
          final message = ErrorMessages.getMessage(failure.code);
          _logger.e('Failed to sign out: $message');
          _errorMessage = message;
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
      _errorMessage = 'Error al cerrar sesión';
      _state = ProfileState.loaded;
      notifyListeners();
      return false;
    }
  }

  /// Refresca los datos del perfil
  Future<void> refresh() async {
    await loadProfile();
  }
}
