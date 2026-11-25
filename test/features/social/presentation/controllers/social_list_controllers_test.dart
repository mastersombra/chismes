import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/social/domain/entities/follow_request.dart';
import 'package:chismes/features/social/domain/entities/social_user.dart';
import 'package:chismes/features/social/domain/usecases/get_blocked_users.dart';
import 'package:chismes/features/social/domain/usecases/get_follow_list.dart';
import 'package:chismes/features/social/domain/usecases/get_follow_requests.dart';
import 'package:chismes/features/social/domain/usecases/remove_follower.dart';
import 'package:chismes/features/social/domain/usecases/respond_follow_request.dart';
import 'package:chismes/features/social/domain/usecases/unblock_user.dart';
import 'package:chismes/features/social/presentation/controllers/blocked_users_controller.dart';
import 'package:chismes/features/social/presentation/controllers/follow_list_controller.dart';
import 'package:chismes/features/social/presentation/controllers/follow_requests_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../social_fixtures.dart';
import '../../social_test_mocks.mocks.dart';

void main() {
  late MockSocialRepository repository;

  setUpAll(provideSocialDummies);
  setUp(() => repository = MockSocialRepository());

  group('FollowListController', () {
    late MockAuthService auth;
    late FollowListController controller;

    setUp(() {
      auth = MockAuthService();
      when(auth.userId).thenReturn(kMyUserId);
      controller = FollowListController(
        GetFollowList(repository),
        RemoveFollower(repository),
        auth,
        MockAppLogger(),
      );
    });

    void stubFirst(String userId, FollowListKind kind, {bool hasMore = false}) {
      when(repository.getFollowList(userId, kind, pageSize: anyNamed('pageSize'), cursor: null))
          .thenAnswer((_) async => Result.success(page([tUser, tUser2], hasMore: hasMore)));
    }

    test('load: primera página de seguidores', () async {
      stubFirst(kOtherUserId, FollowListKind.followers);

      await controller.load(kOtherUserId, FollowListKind.followers);

      expect(controller.status, FollowListStatus.loaded);
      expect(controller.users, [tUser, tUser2]);
      expect(controller.kind, FollowListKind.followers);
    });

    test('loadMore pide la página siguiente con el cursor', () async {
      stubFirst(kOtherUserId, FollowListKind.following, hasMore: true);
      when(repository.getFollowList(kOtherUserId, FollowListKind.following,
              pageSize: anyNamed('pageSize'), cursor: tCursor))
          .thenAnswer((_) async => Result.success(page([const SocialUser(id: 'u3', username: 'carla')])));
      await controller.load(kOtherUserId, FollowListKind.following);

      await controller.loadMore();

      expect(controller.users, hasLength(3));
      expect(controller.hasMore, isFalse);
      expect(controller.isLoadingMore, isFalse);
    });

    test('loadMore sin más páginas no llama al servidor', () async {
      stubFirst(kOtherUserId, FollowListKind.following);
      await controller.load(kOtherUserId, FollowListKind.following);
      clearInteractions(repository);

      await controller.loadMore();

      verifyZeroInteractions(repository);
    });

    test('loadMore que falla conserva la lista', () async {
      stubFirst(kOtherUserId, FollowListKind.following, hasMore: true);
      when(repository.getFollowList(kOtherUserId, FollowListKind.following,
              pageSize: anyNamed('pageSize'), cursor: tCursor))
          .thenAnswer((_) async => Result.failure(const ServerFailure(code: ErrorCode.serverError)));
      await controller.load(kOtherUserId, FollowListKind.following);

      await controller.loadMore();

      expect(controller.users, hasLength(2));
      expect(controller.hasMore, isTrue);
    });

    test('CS404 (privada que no sigo) → notAvailable', () async {
      when(repository.getFollowList(any, any, pageSize: anyNamed('pageSize'), cursor: null))
          .thenAnswer((_) async =>
              Result.failure(const DataFailure(code: ErrorCode.userNotAvailable)));

      await controller.load(kOtherUserId, FollowListKind.followers);

      expect(controller.status, FollowListStatus.notAvailable);
    });

    test('otro error → error', () async {
      when(repository.getFollowList(any, any, pageSize: anyNamed('pageSize'), cursor: null))
          .thenAnswer((_) async =>
              Result.failure(const NetworkFailure(code: ErrorCode.networkError)));

      await controller.load(kOtherUserId, FollowListKind.followers);

      expect(controller.status, FollowListStatus.error);
      expect(controller.failure!.code, ErrorCode.networkError);
    });

    test('solo en MIS seguidores se puede quitar', () async {
      stubFirst(kMyUserId, FollowListKind.followers);
      stubFirst(kMyUserId, FollowListKind.following);
      stubFirst(kOtherUserId, FollowListKind.followers);

      await controller.load(kMyUserId, FollowListKind.followers);
      expect(controller.canRemoveFollowers, isTrue);

      await controller.load(kMyUserId, FollowListKind.following);
      expect(controller.canRemoveFollowers, isFalse);

      await controller.load(kOtherUserId, FollowListKind.followers);
      expect(controller.canRemoveFollowers, isFalse);
    });

    test('removeFollower lo quita de la lista', () async {
      stubFirst(kMyUserId, FollowListKind.followers);
      when(repository.removeFollower(tUser.id)).thenAnswer((_) async => Result.success(null));
      await controller.load(kMyUserId, FollowListKind.followers);

      final failure = await controller.removeFollower(tUser.id);

      expect(failure, isNull);
      expect(controller.users, [tUser2]);
      expect(controller.isRemoving(tUser.id), isFalse);
    });

    test('removeFollower que falla devuelve el error y no lo quita', () async {
      stubFirst(kMyUserId, FollowListKind.followers);
      const error = NetworkFailure(code: ErrorCode.networkError);
      when(repository.removeFollower(tUser.id)).thenAnswer((_) async => Result.failure(error));
      await controller.load(kMyUserId, FollowListKind.followers);

      expect(await controller.removeFollower(tUser.id), error);
      expect(controller.users, [tUser, tUser2]);
    });

    test('removeFollower en la lista de otro no llama al servidor', () async {
      stubFirst(kOtherUserId, FollowListKind.followers);
      await controller.load(kOtherUserId, FollowListKind.followers);

      expect(await controller.removeFollower(tUser.id), isNull);
      verifyNever(repository.removeFollower(any));
    });
  });

  group('FollowRequestsController', () {
    late FollowRequestsController controller;
    final request2 = FollowRequest(user: tUser2, createdAt: DateTime.utc(2026, 11, 20));

    setUp(() {
      controller = FollowRequestsController(
        GetFollowRequests(repository),
        RespondFollowRequest(repository),
      );
      when(repository.getFollowRequests())
          .thenAnswer((_) async => Result.success([tRequest, request2]));
    });

    test('load: solicitudes pendientes', () async {
      await controller.load();

      expect(controller.status, SocialListStatus.loaded);
      expect(controller.requests, [tRequest, request2]);
    });

    test('load con error → error', () async {
      when(repository.getFollowRequests()).thenAnswer(
          (_) async => Result.failure(const NetworkFailure(code: ErrorCode.networkError)));

      await controller.load();

      expect(controller.status, SocialListStatus.error);
      expect(controller.failure, isNotNull);
    });

    test('accept responde accept=true y la quita de la lista', () async {
      when(repository.respondFollowRequest(any, accept: anyNamed('accept')))
          .thenAnswer((_) async => Result.success(null));
      await controller.load();

      final failure = await controller.accept(tUser.id);

      expect(failure, isNull);
      verify(repository.respondFollowRequest(tUser.id, accept: true)).called(1);
      expect(controller.requests, [request2]);
    });

    test('reject responde accept=false', () async {
      when(repository.respondFollowRequest(any, accept: anyNamed('accept')))
          .thenAnswer((_) async => Result.success(null));
      await controller.load();

      await controller.reject(tUser2.id);

      verify(repository.respondFollowRequest(tUser2.id, accept: false)).called(1);
      expect(controller.requests, [tRequest]);
    });

    test('si la solicitud ya no existe (CS404) igual se quita', () async {
      when(repository.respondFollowRequest(any, accept: anyNamed('accept'))).thenAnswer(
          (_) async => Result.failure(const DataFailure(code: ErrorCode.userNotAvailable)));
      await controller.load();

      final failure = await controller.accept(tUser.id);

      expect(failure!.code, ErrorCode.userNotAvailable);
      expect(controller.requests, [request2]);
    });

    test('error de red: la solicitud se conserva', () async {
      when(repository.respondFollowRequest(any, accept: anyNamed('accept'))).thenAnswer(
          (_) async => Result.failure(const NetworkFailure(code: ErrorCode.networkError)));
      await controller.load();

      await controller.accept(tUser.id);

      expect(controller.requests, hasLength(2));
      expect(controller.isProcessing(tUser.id), isFalse);
    });
  });

  group('BlockedUsersController', () {
    late BlockedUsersController controller;

    setUp(() {
      controller = BlockedUsersController(GetBlockedUsers(repository), UnblockUser(repository));
      when(repository.getBlockedUsers()).thenAnswer((_) async => Result.success([tUser, tUser2]));
    });

    test('load: bloqueados', () async {
      await controller.load();

      expect(controller.status, SocialListStatus.loaded);
      expect(controller.users, [tUser, tUser2]);
    });

    test('load con error → error', () async {
      when(repository.getBlockedUsers()).thenAnswer(
          (_) async => Result.failure(const NetworkFailure(code: ErrorCode.networkError)));

      await controller.load();

      expect(controller.status, SocialListStatus.error);
    });

    test('unblock lo quita de la lista', () async {
      when(repository.unblockUser(tUser.id)).thenAnswer((_) async => Result.success(null));
      await controller.load();

      expect(await controller.unblock(tUser.id), isNull);
      expect(controller.users, [tUser2]);
    });

    test('unblock que falla lo conserva', () async {
      when(repository.unblockUser(tUser.id)).thenAnswer(
          (_) async => Result.failure(const NetworkFailure(code: ErrorCode.networkError)));
      await controller.load();

      expect(await controller.unblock(tUser.id), isNotNull);
      expect(controller.users, hasLength(2));
    });
  });
}
