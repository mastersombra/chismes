import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../features/auth/domain/entities/user.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../error/failure.dart';
import '../logging/logging.dart';
import '../result/result.dart';

/// Servicio global de autenticación
///
/// Proporciona acceso al estado de autenticación desde cualquier parte de la app.
/// Este servicio vive en core/ porque es transversal a todas las features.
///
/// Uso desde features:
/// ```dart
/// @injectable
/// class MyService {
///   final AuthService _authService;
///
///   MyService(this._authService);
///
///   void doSomething() {
///     final user = _authService.currentUser;
///     if (user != null) {
///       // Usuario autenticado
///     }
///   }
/// }
/// ```
///
/// O para reaccionar a cambios:
/// ```dart
/// _authService.userStream.listen((user) {
///   if (user == null) {
///     // Usuario cerró sesión
///   } else {
///     // Usuario inició sesión
///   }
/// });
/// ```
@singleton
class AuthService {
  final AuthRepository _authRepository;
  final SupabaseClient _supabase;
  final AppLogger _logger;

  AuthService(
    this._authRepository,
    this._supabase,
    this._logger,
  );

  /// Último usuario cargado CON su perfil (username, nombre, bio, foto).
  /// El getter síncrono del repositorio no trae el perfil (no puede leer la
  /// tabla sin esperar): se completa con [loadCurrentUser] y [updateProfile].
  User? _profileUser;

  /// Usuario actualmente autenticado
  ///
  /// Retorna null si no hay sesión activa. Incluye el perfil si ya se cargó
  /// ([loadCurrentUser]) y la sesión sigue siendo del mismo usuario.
  User? get currentUser {
    final sessionUser = _authRepository.currentUser;
    if (sessionUser == null) {
      _profileUser = null;
      return null;
    }
    final cached = _profileUser;
    return cached != null && cached.id == sessionUser.id ? cached : sessionUser;
  }

  /// Lee el usuario con su perfil desde el servidor y lo deja en [currentUser]
  Future<Result<Failure, User?>> loadCurrentUser() async {
    final result = await _authRepository.getCurrentUser();
    result.when(
      onFailure: (failure) =>
          _logger.w('Failed to load current user', context: {'code': failure.code.name}),
      onSuccess: (user) => _profileUser = user,
    );
    return result;
  }

  /// Actualiza el perfil (vía update-profile: el servidor valida y modera) y
  /// deja el resultado en [currentUser]. Ver [AuthRepository.updateProfile].
  Future<Result<Failure, User>> updateProfile({
    String? username,
    String? displayName,
    String? bio,
    Uint8List? avatar,
    bool removeAvatar = false,
  }) async {
    final result = await _authRepository.updateProfile(
      username: username,
      displayName: displayName,
      bio: bio,
      avatar: avatar,
      removeAvatar: removeAvatar,
    );
    result.when(
      onFailure: (_) {},
      onSuccess: (user) => _profileUser = user,
    );
    return result;
  }

  /// Stream de cambios en el estado de autenticación
  ///
  /// Emite el usuario cuando hay cambios en la autenticación:
  /// - Usuario inicia sesión → emite User
  /// - Usuario cierra sesión → emite null
  /// - Usuario actualiza perfil → emite User actualizado
  ///
  /// Útil para:
  /// - Redirigir a login cuando sesión expira
  /// - Actualizar UI cuando perfil cambia
  /// - Sincronizar estado entre pantallas
  Stream<User?> get userStream => _authRepository.authStateChanges;

  /// Verifica si hay un usuario autenticado
  bool get isAuthenticated => currentUser != null;

  /// Verifica si el usuario tiene perfil completo
  ///
  /// Útil para saber si debe mostrar pantalla de completar perfil.
  bool get hasCompleteProfile =>
      currentUser?.profileCompleted ?? false;

  /// Verifica si el usuario tiene username configurado
  ///
  /// Útil para bloquear acciones que requieren username (ej: publicar chisme).
  bool get hasUsername => currentUser?.hasUsername ?? false;

  /// Obtiene el nombre a mostrar del usuario actual
  ///
  /// Prioridad: displayName > username > email
  String? get displayName => currentUser?.displayNameOrFallback;

  /// ID del usuario actual
  String? get userId => currentUser?.id;

  /// Email del usuario actual
  String? get userEmail => currentUser?.email;

  /// 🔍 DEBUG: Verifica el estado detallado de la sesión
  ///
  /// Útil para debugging de problemas de expiración de token.
  /// Retorna información sobre el token y su expiración.
  Map<String, dynamic> debugSessionStatus() {
    final session = _supabase.auth.currentSession;
    final user = _supabase.auth.currentUser;

    if (session == null || user == null) {
      _logger.w('debugSessionStatus: No active session or user');
      return {
        'hasSession': false,
        'hasUser': user != null,
        'isAuthenticated': false,
      };
    }

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    final now = DateTime.now();
    final timeUntilExpiry = expiresAt.difference(now);
    final isExpired = expiresAt.isBefore(now);

    final status = {
      'hasSession': true,
      'hasUser': true,
      'userId': user.id,
      'email': user.email,
      'expiresAt': expiresAt.toIso8601String(),
      'currentTime': now.toIso8601String(),
      'timeUntilExpiryMinutes': timeUntilExpiry.inMinutes,
      'timeUntilExpirySeconds': timeUntilExpiry.inSeconds,
      'isExpired': isExpired,
      'tokenType': session.tokenType,
    };

    if (isExpired) {
      _logger.w('Session is EXPIRED', context: status);
    } else {
      _logger.i('Session is VALID', context: status);
    }

    return status;
  }

  /// 🔍 DEBUG: Verifica si la sesión está expirada manualmente
  bool isSessionExpired() {
    final session = _supabase.auth.currentSession;

    if (session == null) {
      _logger.w('isSessionExpired: No session found');
      return true;
    }

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    final now = DateTime.now();
    final isExpired = expiresAt.isBefore(now);

    if (isExpired) {
      _logger.w('isSessionExpired: YES - Session expired', context: {
        'expiresAt': expiresAt.toIso8601String(),
        'currentTime': now.toIso8601String(),
        'expiredSince': '${now.difference(expiresAt).inMinutes} minutes ago',
      });
    }

    return isExpired;
  }
}
