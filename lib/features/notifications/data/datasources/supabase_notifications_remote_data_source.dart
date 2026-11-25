import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_codes.dart' as app_errors;
import '../../../../core/logging/logging.dart';
import '../models/notification_page_model.dart';

/// DataSource remoto de notificaciones: RPCs de la migración 019.
///
/// Todas usan `auth.uid()` en el servidor: NUNCA se manda el ID del usuario.
///
/// **Errores:** propaga [PostgrestException] (el repositorio mapea CS401 con
/// ErrorHandler). Un JSON con forma inesperada se convierte en
/// [ServerException].
@singleton
class SupabaseNotificationsRemoteDataSource {
  final SupabaseClient _supabase;
  final AppLogger _logger;

  SupabaseNotificationsRemoteDataSource(this._supabase, this._logger);

  /// `get_notifications` (más recientes primero, keyset)
  Future<NotificationPageModel> getNotifications({
    required int pageSize,
    String? cursorCreatedAt,
    String? cursorId,
  }) =>
      _call(
        'get_notifications',
        {
          'page_size': pageSize,
          'cursor_created_at': cursorCreatedAt,
          'cursor_id': cursorId,
        },
        (r) => NotificationPageModel.fromJson(r as Map<String, dynamic>?),
      );

  /// `get_unread_notifications_count` (máx. 100)
  Future<int> getUnreadCount() => _call(
        'get_unread_notifications_count',
        null,
        (r) => (r as num).toInt(),
      );

  /// `mark_notifications_read`: [ids] null → todas. Devuelve cuántas marcó.
  Future<int> markRead(List<String>? ids) => _call(
        'mark_notifications_read',
        {'p_ids': ids},
        (r) => (r as num?)?.toInt() ?? 0,
      );

  /// Llama al RPC [fn] y convierte la respuesta con [parse]
  Future<T> _call<T>(
    String fn,
    Map<String, dynamic>? params,
    T Function(dynamic response) parse,
  ) async {
    _logger.d('Calling $fn RPC');
    try {
      final response = await _supabase.rpc(fn, params: params);
      return parse(response);
    } on PostgrestException catch (error, stackTrace) {
      // Sin sesión (CS401): flujo normal al cerrar sesión, no error del sistema
      if (error.code == 'CS401') {
        _logger.w('$fn rejected', context: {'code': error.code});
      } else {
        _logger.e(
          'Supabase error in $fn',
          error: error,
          stackTrace: stackTrace,
          context: {'code': error.code},
        );
      }
      rethrow;
    } on TypeError catch (error, stackTrace) {
      throw _formatError(fn, error, stackTrace);
    } on FormatException catch (error, stackTrace) {
      throw _formatError(fn, error, stackTrace);
    }
  }

  ServerException _formatError(String fn, Object error, StackTrace stackTrace) {
    _logger.e(
      'Unexpected response format in $fn',
      error: error,
      stackTrace: stackTrace,
    );
    return ServerException(
      code: app_errors.ErrorCode.serverError,
      technicalMessage: 'Respuesta inesperada de $fn: $error',
    );
  }
}
