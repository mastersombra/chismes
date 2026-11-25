import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/error/error_codes.dart' as app_errors;
import '../../../../core/logging/logging.dart';
import '../../../../core/navigation/social_navigator.dart';
import '../models/follow_request_model.dart';
import '../models/social_page_model.dart';
import '../models/social_user_model.dart';
import '../models/user_gossip_model.dart';
import '../models/user_profile_model.dart';

/// DataSource remoto del feature social: RPCs de la migración 018.
///
/// Todas las funciones usan `auth.uid()` en el servidor: NUNCA se manda el ID
/// del usuario actual.
///
/// **Errores:** propaga [PostgrestException] (el repositorio mapea los
/// SQLSTATE propios CS401/CS400/CS404/CS429 con ErrorHandler). Un JSON con forma
/// inesperada se convierte en [ServerException].
@singleton
class SupabaseSocialRemoteDataSource {
  final SupabaseClient _supabase;
  final AppLogger _logger;

  SupabaseSocialRemoteDataSource(this._supabase, this._logger);

  /// `follow_user`: 'following' | 'requested'
  Future<String> followUser(String targetId) =>
      _call('follow_user', {'p_target': targetId}, (r) => r as String);

  /// `unfollow_user` (también cancela una solicitud pendiente)
  Future<void> unfollowUser(String targetId) =>
      _call('unfollow_user', {'p_target': targetId}, (_) {});

  Future<void> respondFollowRequest(String requesterId, bool accept) => _call(
        'respond_follow_request',
        {'p_requester': requesterId, 'p_accept': accept},
        (_) {},
      );

  Future<void> removeFollower(String followerId) =>
      _call('remove_follower', {'p_follower': followerId}, (_) {});

  Future<void> blockUser(String targetId) =>
      _call('block_user', {'p_target': targetId}, (_) {});

  Future<void> unblockUser(String targetId) =>
      _call('unblock_user', {'p_target': targetId}, (_) {});

  /// `get_user_profile`: null si no existe o si ÉL me bloqueó
  Future<UserProfileModel?> getUserProfile(String userId) => _call(
        'get_user_profile',
        {'p_user': userId},
        (r) => r == null
            ? null
            : UserProfileModel.fromJson(r as Map<String, dynamic>),
      );

  /// `get_follow_list` (CS404 si no puedo ver sus listas)
  Future<SocialPageModel<SocialUserModel>> getFollowList(
    String userId,
    FollowListKind kind, {
    required int pageSize,
    String? cursorCreatedAt,
    String? cursorId,
  }) =>
      _call(
        'get_follow_list',
        {
          'p_user': userId,
          'p_kind': kind.value,
          'page_size': pageSize,
          'cursor_created_at': cursorCreatedAt,
          'cursor_id': cursorId,
        },
        (r) => SocialPageModel.fromJson(
          r as Map<String, dynamic>?,
          SocialUserModel.fromJson,
        ),
      );

  Future<List<FollowRequestModel>> getFollowRequests() =>
      _call('get_follow_requests', null, FollowRequestModel.listFromJson);

  Future<List<SocialUserModel>> getBlockedUsers() =>
      _call('get_blocked_users', null, SocialUserModel.listFromJson);

  Future<List<SocialUserModel>> searchUsers(String query, int limit) => _call(
        'search_users',
        {'search_query': query, 'result_limit': limit},
        SocialUserModel.listFromJson,
      );

  /// `get_user_gossips`: chismes con perfil (mismo JSON que los feeds)
  Future<SocialPageModel<UserGossipModel>> getUserGossips(
    String userId, {
    required int pageSize,
    String? cursorCreatedAt,
    String? cursorId,
  }) =>
      _call(
        'get_user_gossips',
        {
          'p_user': userId,
          'page_size': pageSize,
          'cursor_created_at': cursorCreatedAt,
          'cursor_id': cursorId,
        },
        (r) => SocialPageModel.fromJson(
          r as Map<String, dynamic>?,
          UserGossipModel.fromJson,
        ),
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
      // Flujo normal, no errores del sistema: usuario no disponible (CS404),
      // consigo mismo (CS400), límite anti-spam de seguir (CS429)
      const expectedCodes = {'CS404', 'CS400', 'CS429'};
      final expected = expectedCodes.contains(error.code);
      if (expected) {
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
