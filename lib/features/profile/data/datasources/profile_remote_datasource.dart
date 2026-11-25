import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/error_codes.dart' as error_codes;
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../models/profile_settings_model.dart';
import '../models/user_stats_model.dart';

/// DataSource remoto para perfil usando Supabase
@singleton
class ProfileRemoteDataSource {
  final SupabaseClient _supabase;
  final AppLogger _logger;

  ProfileRemoteDataSource(
    this._supabase,
    this._logger,
  );

  /// Obtiene estadísticas del usuario desde Supabase
  Future<UserStatsModel> getUserStats(String userId) async {
    try {
      _logger.d('Fetching user stats for userId: $userId');

      // Por ahora, vamos a calcular las estadísticas con queries
      // En el futuro, esto podría venir de una vista materializada

      // Contar gossips del usuario
      final response = await _supabase
          .from('public_gossips') // Incluye los propios (anónimos y drafts)
          .select('id')
          .eq('created_by', userId)
          .neq('status', 'deleted');

      final gossipsCount = (response as List).length;

      _logger.d('User has $gossipsCount gossips');

      // Por ahora retornamos stats básicas (followers/comments vendrán en futuras features)
      return UserStatsModel(
        gossipsCount: gossipsCount,
        commentsCount: 0, // TODO: Implementar cuando exista feature de comments
        followersCount: 0, // TODO: Implementar cuando exista feature de follows
        followingCount: 0, // TODO: Implementar cuando exista feature de follows
        lastActivityAt: DateTime.now().toIso8601String(),
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Error fetching user stats',
        error: error,
        stackTrace: stackTrace,
        context: {'userId': userId},
      );
      rethrow;
    }
  }

  /// Lee la configuración del usuario (`user_settings`, 017). La fila la crea
  /// el servidor al registrarse; si faltara, se usan los valores por defecto
  /// (los mismos de la tabla).
  Future<ProfileSettingsModel> getSettings(String userId) async {
    try {
      final row = await _supabase
          .from('user_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) {
        _logger.w('user_settings row missing, using defaults', context: {'userId': userId});
      }
      return ProfileSettingsModel.fromJson(row ?? const {});
    } catch (error, stackTrace) {
      _logger.e(
        'Error fetching settings',
        error: error,
        stackTrace: stackTrace,
        context: {'userId': userId},
      );
      rethrow;
    }
  }

  /// Guarda la configuración (RLS: el dueño solo cambia la suya). Si no se
  /// actualizó ninguna fila, falla: así la UI no muestra un cambio que no se
  /// guardó.
  Future<void> updateSettings(
    String userId,
    ProfileSettingsModel settings,
  ) async {
    try {
      final updated = await _supabase
          .from('user_settings')
          .update(settings.toJson())
          .eq('user_id', userId)
          .select('user_id');
      if ((updated as List).isEmpty) {
        throw const DataFailure(
          code: error_codes.ErrorCode.notFound,
          technicalMessage: 'user_settings row not found',
        );
      }
      _logger.i('Settings updated', context: {'userId': userId});
    } catch (error, stackTrace) {
      _logger.e(
        'Error updating settings',
        error: error,
        stackTrace: stackTrace,
        context: {'userId': userId},
      );
      rethrow;
    }
  }

  /// Cierra sesión del usuario
  Future<void> signOut() async {
    try {
      _logger.i('Signing out user');
      await _supabase.auth.signOut();
      _logger.i('User signed out successfully');
    } catch (error, stackTrace) {
      _logger.e(
        'Error signing out',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Elimina la cuenta del usuario y todos sus datos (Edge Function
  /// `delete-account`) y cierra la sesión local.
  ///
  /// Irreversible: la UI debe pedir doble confirmación antes de llamar.
  /// Lanza [Failure] si el servidor no confirmó el borrado (la cuenta sigue).
  Future<void> deleteAccount() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw const AuthFailure(
        code: error_codes.ErrorCode.unauthorized,
        technicalMessage: 'No active session',
      );
    }

    _logger.i('Deleting account');
    try {
      final response = await _supabase.functions.invoke(
        deleteAccountFunction,
        body: const {'confirmation': deleteAccountConfirmation},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.status < 200 || response.status >= 300) {
        throw _deleteFailure(response.status, response.data);
      }
    } on FunctionException catch (error) {
      _logger.w('delete-account failed', context: {'status': error.status});
      throw _deleteFailure(error.status, error.details);
    }
    _logger.i('Account deleted');

    // La cuenta ya no existe en el servidor: basta con limpiar la sesión
    // local (AuthGate navega al login). Si falla, la validación de sesión
    // de AuthGate la cierra igual (user_not_found).
    try {
      await _supabase.auth.signOut(scope: SignOutScope.local);
    } catch (error, stackTrace) {
      _logger.w(
        'Local sign out after account deletion failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static const deleteAccountFunction = 'delete-account';
  static const deleteAccountConfirmation = 'DELETE_MY_ACCOUNT';

  static Failure _deleteFailure(int status, dynamic details) {
    final message = 'delete-account $status: $details';
    switch (status) {
      case 401:
        return AuthFailure(code: error_codes.ErrorCode.unauthorized, technicalMessage: message);
      case 400:
        return ValidationFailure(code: error_codes.ErrorCode.validationError, technicalMessage: message);
      default:
        return ServerFailure(code: error_codes.ErrorCode.serverError, technicalMessage: message);
    }
  }
}
