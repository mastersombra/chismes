import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/logging/logging.dart';
import '../models/profile_settings_model.dart';
import '../models/user_stats_model.dart';

/// DataSource remoto para perfil usando Supabase
@singleton
class ProfileRemoteDataSource {
  final AppLogger _logger;
  final SupabaseClient _supabase;

  ProfileRemoteDataSource(
    this._logger,
  ) : _supabase = SupabaseConfig.client;

  /// Obtiene estadísticas del usuario desde Supabase
  Future<UserStatsModel> getUserStats(String userId) async {
    try {
      _logger.d('Fetching user stats for userId: $userId');

      // Por ahora, vamos a calcular las estadísticas con queries
      // En el futuro, esto podría venir de una vista materializada

      // Contar gossips del usuario
      final response = await _supabase
          .from('gossips')
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

  /// Obtiene configuraciones del usuario desde Supabase
  Future<ProfileSettingsModel> getSettings(String userId) async {
    try {
      _logger.d('Fetching settings for userId: $userId');

      // Por ahora retornamos configuración por defecto
      // TODO: Implementar tabla de configuraciones en Supabase
      return ProfileSettingsModel.fromJson({
        'notifications_enabled': true,
        'email_notifications': true,
        'push_notifications': true,
        'comments_notifications': true,
        'likes_notifications': true,
        'follow_notifications': true,
        'language': 'es',
        'dark_mode': false,
        'privacy_level': 'public',
        'show_email': false,
        'show_activity': true,
      });
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

  /// Actualiza configuraciones del usuario en Supabase
  Future<void> updateSettings(
    String userId,
    ProfileSettingsModel settings,
  ) async {
    try {
      _logger.d('Updating settings for userId: $userId');

      // TODO: Implementar actualización en tabla de configuraciones
      // Por ahora solo logueamos
      _logger.i(
        'Settings would be updated',
        context: {
          'userId': userId,
          'settings': settings.toJson(),
        },
      );

      await Future.delayed(const Duration(milliseconds: 500)); // Simular latencia
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
}
