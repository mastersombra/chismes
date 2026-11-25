import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/navigation/social_navigator.dart';
import '../../../../core/result/result.dart';
import '../../../gossip/domain/entities/gossip.dart';
import '../../domain/entities/follow_request.dart';
import '../../domain/entities/follow_result.dart';
import '../../domain/entities/social_page.dart';
import '../../domain/entities/social_user.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/social_repository.dart';
import '../datasources/supabase_social_remote_data_source.dart';

/// Implementación de [SocialRepository] sobre los RPC de la migración 018.
/// Nunca lanza: todo error vuelve como `Result.failure` (ErrorHandler mapea
/// CS401/CS400/CS404).
@Singleton(as: SocialRepository)
class SocialRepositoryImpl implements SocialRepository {
  final SupabaseSocialRemoteDataSource _remote;
  final AppLogger _logger;

  SocialRepositoryImpl(this._remote, this._logger);

  @override
  Future<Result<Failure, FollowResult>> followUser(String userId) =>
      _guard('followUser', () async {
        final value = await _remote.followUser(userId);
        switch (value) {
          case 'following':
            return FollowResult.following;
          case 'requested':
            return FollowResult.requested;
          default:
            throw FormatException('Unexpected follow_user result: $value');
        }
      });

  @override
  Future<Result<Failure, void>> unfollowUser(String userId) =>
      _guard('unfollowUser', () => _remote.unfollowUser(userId));

  @override
  Future<Result<Failure, void>> respondFollowRequest(
    String requesterId, {
    required bool accept,
  }) =>
      _guard('respondFollowRequest',
          () => _remote.respondFollowRequest(requesterId, accept));

  @override
  Future<Result<Failure, void>> removeFollower(String followerId) =>
      _guard('removeFollower', () => _remote.removeFollower(followerId));

  @override
  Future<Result<Failure, void>> blockUser(String userId) =>
      _guard('blockUser', () => _remote.blockUser(userId));

  @override
  Future<Result<Failure, void>> unblockUser(String userId) =>
      _guard('unblockUser', () => _remote.unblockUser(userId));

  @override
  Future<Result<Failure, UserProfile>> getUserProfile(String userId) =>
      _guard('getUserProfile', () async {
        final model = await _remote.getUserProfile(userId);
        if (model == null) {
          // No existe o me bloqueó: no se distingue a propósito
          throw const DataFailure(
            code: ErrorCode.userNotAvailable,
            technicalMessage: 'get_user_profile returned null',
          );
        }
        return model.toEntity();
      });

  @override
  Future<Result<Failure, SocialPage<SocialUser>>> getFollowList(
    String userId,
    FollowListKind kind, {
    int pageSize = 30,
    SocialCursor? cursor,
  }) =>
      _guard('getFollowList', () async {
        final page = await _remote.getFollowList(
          userId,
          kind,
          pageSize: pageSize,
          cursorCreatedAt: cursor?.createdAt.toUtc().toIso8601String(),
          cursorId: cursor?.id,
        );
        return page.toEntity((m) => m.toEntity());
      });

  @override
  Future<Result<Failure, List<FollowRequest>>> getFollowRequests() =>
      _guard('getFollowRequests', () async {
        final models = await _remote.getFollowRequests();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<Failure, List<SocialUser>>> getBlockedUsers() =>
      _guard('getBlockedUsers', () async {
        final models = await _remote.getBlockedUsers();
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<Failure, List<SocialUser>>> searchUsers(
    String query, {
    int limit = 20,
  }) =>
      _guard('searchUsers', () async {
        final models = await _remote.searchUsers(query, limit);
        return models.map((m) => m.toEntity()).toList();
      });

  @override
  Future<Result<Failure, SocialPage<Gossip>>> getUserGossips(
    String userId, {
    int pageSize = 20,
    SocialCursor? cursor,
  }) =>
      _guard('getUserGossips', () async {
        final page = await _remote.getUserGossips(
          userId,
          pageSize: pageSize,
          cursorCreatedAt: cursor?.createdAt.toUtc().toIso8601String(),
          cursorId: cursor?.id,
        );
        return page.toEntity((m) => m.toEntity());
      });

  /// Ejecuta [action] y convierte cualquier error en `Result.failure`
  Future<Result<Failure, T>> _guard<T>(
    String operation,
    Future<T> Function() action,
  ) async {
    try {
      return Result.success(await action());
    } catch (error, stackTrace) {
      final failure = ErrorHandler.handleError(error, stackTrace);
      _logger.w('Social $operation failed', context: {
        'code': failure.code.name,
      });
      return Result.failure(failure);
    }
  }
}
