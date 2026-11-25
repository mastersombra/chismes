import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/social/domain/entities/follow_result.dart';
import 'package:chismes/features/social/domain/entities/user_profile.dart';
import 'package:chismes/features/social/domain/usecases/block_user.dart';
import 'package:chismes/features/social/domain/usecases/follow_user.dart';
import 'package:chismes/features/social/domain/usecases/get_user_gossips.dart';
import 'package:chismes/features/social/domain/usecases/get_user_profile.dart';
import 'package:chismes/features/social/domain/usecases/unblock_user.dart';
import 'package:chismes/features/social/domain/usecases/unfollow_user.dart';
import 'package:chismes/features/social/presentation/controllers/user_profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../social_fixtures.dart';
import '../../social_test_mocks.mocks.dart';

void main() {
  late MockSocialRepository repository;
  late UserProfileController controller;

  setUpAll(provideSocialDummies);

  setUp(() {
    repository = MockSocialRepository();
    controller = UserProfileController(
      GetUserProfile(repository),
      GetUserGossips(repository),
      FollowUser(repository),
      UnfollowUser(repository),
      BlockUser(repository),
      UnblockUser(repository),
      MockAppLogger(),
    );
  });

  void stubProfile(UserProfile profile) {
    when(repository.getUserProfile(kOtherUserId))
        .thenAnswer((_) async => Result.success(profile));
  }

  void stubGossips({List<String> ids = const ['g1', 'g2'], bool hasMore = false}) {
    when(repository.getUserGossips(kOtherUserId,
            pageSize: anyNamed('pageSize'), cursor: null))
        .thenAnswer((_) async =>
            Result.success(page(ids.map(tProfileGossip).toList(), hasMore: hasMore)));
  }

  group('load', () {
    test('perfil público: loaded y carga sus chismes', () async {
      stubProfile(tProfile());
      stubGossips(hasMore: true);
      final statuses = <UserProfileStatus>[];
      controller.addListener(() => statuses.add(controller.status));

      await controller.load(kOtherUserId);

      expect(statuses.first, UserProfileStatus.loading);
      expect(controller.status, UserProfileStatus.loaded);
      expect(controller.profile, tProfile());
      expect(controller.gossips.map((g) => g.id), ['g1', 'g2']);
      expect(controller.hasMoreGossips, isTrue);
      expect(controller.isLoadingGossips, isFalse);
    });

    test('privada que no sigo: no pide chismes', () async {
      stubProfile(tProfile(isPrivate: true, canViewContent: false, gossipsCount: null));

      await controller.load(kOtherUserId);

      expect(controller.status, UserProfileStatus.loaded);
      expect(controller.gossips, isEmpty);
      verifyNever(repository.getUserGossips(any,
          pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')));
    });

    test('bloqueado por mí: no pide chismes', () async {
      stubProfile(tProfile(hasBlocked: true));

      await controller.load(kOtherUserId);

      expect(controller.profile!.hasBlocked, isTrue);
      verifyNever(repository.getUserGossips(any,
          pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')));
    });

    test('userNotAvailable (no existe o me bloqueó) → notAvailable', () async {
      when(repository.getUserProfile(kOtherUserId)).thenAnswer(
          (_) async => Result.failure(const DataFailure(code: ErrorCode.userNotAvailable)));

      await controller.load(kOtherUserId);

      expect(controller.status, UserProfileStatus.notAvailable);
      expect(controller.profile, isNull);
    });

    test('otro error → error con el Failure', () async {
      const failure = NetworkFailure(code: ErrorCode.noInternetConnection);
      when(repository.getUserProfile(kOtherUserId))
          .thenAnswer((_) async => Result.failure(failure));

      await controller.load(kOtherUserId);

      expect(controller.status, UserProfileStatus.error);
      expect(controller.failure, failure);
    });

    test('si fallan los chismes, el perfil queda y se puede reintentar', () async {
      stubProfile(tProfile());
      when(repository.getUserGossips(kOtherUserId,
              pageSize: anyNamed('pageSize'), cursor: null))
          .thenAnswer((_) async =>
              Result.failure(const ServerFailure(code: ErrorCode.serverError)));

      await controller.load(kOtherUserId);

      expect(controller.status, UserProfileStatus.loaded);
      expect(controller.gossipsFailed, isTrue);

      stubGossips(ids: ['g9']);
      await controller.retryGossips();

      expect(controller.gossipsFailed, isFalse);
      expect(controller.gossips.single.id, 'g9');
    });
  });

  group('paginación de chismes', () {
    test('loadMoreGossips agrega la página siguiente con el cursor', () async {
      stubProfile(tProfile());
      stubGossips(hasMore: true);
      when(repository.getUserGossips(kOtherUserId,
              pageSize: anyNamed('pageSize'), cursor: tCursor))
          .thenAnswer((_) async => Result.success(page([tProfileGossip('g3')])));
      await controller.load(kOtherUserId);

      await controller.loadMoreGossips();

      expect(controller.gossips.map((g) => g.id), ['g1', 'g2', 'g3']);
      expect(controller.hasMoreGossips, isFalse);
      expect(controller.isLoadingMore, isFalse);
    });

    test('sin más páginas no llama al servidor', () async {
      stubProfile(tProfile());
      stubGossips();
      await controller.load(kOtherUserId);
      clearInteractions(repository);

      await controller.loadMoreGossips();

      verifyNever(repository.getUserGossips(any,
          pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')));
    });

    test('si falla la página siguiente conserva lo cargado', () async {
      stubProfile(tProfile());
      stubGossips(hasMore: true);
      when(repository.getUserGossips(kOtherUserId,
              pageSize: anyNamed('pageSize'), cursor: tCursor))
          .thenAnswer((_) async =>
              Result.failure(const ServerFailure(code: ErrorCode.serverError)));
      await controller.load(kOtherUserId);

      await controller.loadMoreGossips();

      expect(controller.gossips, hasLength(2));
      expect(controller.hasMoreGossips, isTrue);
    });
  });

  group('seguir', () {
    test('cuenta privada: follow → requested (relee el perfil)', () async {
      var profile = tProfile(isPrivate: true, canViewContent: false);
      when(repository.getUserProfile(kOtherUserId))
          .thenAnswer((_) async => Result.success(profile));
      when(repository.followUser(kOtherUserId)).thenAnswer((_) async {
        profile = tProfile(isPrivate: true, canViewContent: false, isRequested: true);
        return Result.success(FollowResult.requested);
      });
      await controller.load(kOtherUserId);

      final failure = await controller.follow();

      expect(failure, isNull);
      expect(controller.profile!.followStatus, FollowStatus.requested);
      expect(controller.isActionInProgress, isFalse);
      verify(repository.getUserProfile(kOtherUserId)).called(2);
    });

    test('cuenta pública: follow → following con contador actualizado', () async {
      var profile = tProfile(followersCount: 10);
      when(repository.getUserProfile(kOtherUserId))
          .thenAnswer((_) async => Result.success(profile));
      stubGossips();
      when(repository.followUser(kOtherUserId)).thenAnswer((_) async {
        profile = tProfile(isFollowing: true, followersCount: 11);
        return Result.success(FollowResult.following);
      });
      await controller.load(kOtherUserId);

      await controller.follow();

      expect(controller.profile!.followStatus, FollowStatus.following);
      expect(controller.profile!.followersCount, 11);
    });

    test('unfollow de privada: pierde acceso y se borran sus chismes', () async {
      var profile = tProfile(isPrivate: true, isFollowing: true);
      when(repository.getUserProfile(kOtherUserId))
          .thenAnswer((_) async => Result.success(profile));
      stubGossips();
      when(repository.unfollowUser(kOtherUserId)).thenAnswer((_) async {
        profile = tProfile(isPrivate: true, canViewContent: false);
        return Result.success(null);
      });
      await controller.load(kOtherUserId);
      expect(controller.gossips, hasLength(2));

      await controller.unfollow();

      expect(controller.profile!.followStatus, FollowStatus.none);
      expect(controller.gossips, isEmpty);
    });

    test('al aceptar mi solicitud y volver a entrar puedo ver sus chismes', () async {
      var profile = tProfile(isPrivate: true, canViewContent: false, isRequested: true);
      when(repository.getUserProfile(kOtherUserId))
          .thenAnswer((_) async => Result.success(profile));
      stubGossips();
      await controller.load(kOtherUserId);
      expect(controller.gossips, isEmpty);

      profile = tProfile(isPrivate: true, isFollowing: true);
      await controller.refresh();

      expect(controller.gossips, hasLength(2));
    });

    test('error en follow: devuelve el Failure y conserva el perfil', () async {
      stubProfile(tProfile());
      stubGossips();
      const failure = RateLimitFailure(code: ErrorCode.followRateLimited);
      when(repository.followUser(kOtherUserId)).thenAnswer((_) async => Result.failure(failure));
      await controller.load(kOtherUserId);

      final result = await controller.follow();

      expect(result, failure);
      expect(controller.status, UserProfileStatus.loaded);
      expect(controller.profile!.followStatus, FollowStatus.none);
      expect(controller.isActionInProgress, isFalse);
    });

    test('follow con userNotAvailable (me bloqueó) → notAvailable', () async {
      stubProfile(tProfile());
      stubGossips();
      when(repository.followUser(kOtherUserId)).thenAnswer(
          (_) async => Result.failure(const DataFailure(code: ErrorCode.userNotAvailable)));
      await controller.load(kOtherUserId);

      await controller.follow();

      expect(controller.status, UserProfileStatus.notAvailable);
      expect(controller.gossips, isEmpty);
    });

    test('en mi propio perfil las acciones no hacen nada', () async {
      when(repository.getUserProfile(kMyUserId))
          .thenAnswer((_) async => Result.success(tProfile(id: kMyUserId, isMe: true)));
      when(repository.getUserGossips(kMyUserId,
              pageSize: anyNamed('pageSize'), cursor: null))
          .thenAnswer((_) async => Result.success(page([tProfileGossip('g1')])));
      await controller.load(kMyUserId);

      expect(await controller.follow(), isNull);
      expect(await controller.block(), isNull);
      verifyNever(repository.followUser(any));
      verifyNever(repository.blockUser(any));
    });
  });

  group('bloquear', () {
    test('block → perfil bloqueado y sin chismes', () async {
      var profile = tProfile(isFollowing: true);
      when(repository.getUserProfile(kOtherUserId))
          .thenAnswer((_) async => Result.success(profile));
      stubGossips();
      when(repository.blockUser(kOtherUserId)).thenAnswer((_) async {
        profile = tProfile(hasBlocked: true);
        return Result.success(null);
      });
      await controller.load(kOtherUserId);

      final failure = await controller.block();

      expect(failure, isNull);
      expect(controller.profile!.hasBlocked, isTrue);
      expect(controller.gossips, isEmpty);
    });

    test('unblock → vuelve a ver el perfil y sus chismes', () async {
      var profile = tProfile(hasBlocked: true);
      when(repository.getUserProfile(kOtherUserId))
          .thenAnswer((_) async => Result.success(profile));
      stubGossips();
      when(repository.unblockUser(kOtherUserId)).thenAnswer((_) async {
        profile = tProfile();
        return Result.success(null);
      });
      await controller.load(kOtherUserId);

      await controller.unblock();

      expect(controller.profile!.hasBlocked, isFalse);
      expect(controller.gossips, hasLength(2));
    });

    test('si falla releer tras la acción, conserva el perfil anterior', () async {
      var fail = false;
      when(repository.getUserProfile(kOtherUserId)).thenAnswer((_) async => fail
          ? Result.failure(const NetworkFailure(code: ErrorCode.networkError))
          : Result.success(tProfile()));
      stubGossips();
      when(repository.blockUser(kOtherUserId)).thenAnswer((_) async {
        fail = true;
        return Result.success(null);
      });
      await controller.load(kOtherUserId);

      await controller.block();

      expect(controller.status, UserProfileStatus.loaded);
      expect(controller.profile, tProfile());
    });
  });

  test('dispose: no notifica después de cerrar la pantalla', () async {
    stubProfile(tProfile());
    stubGossips();
    final future = controller.load(kOtherUserId);

    controller.dispose();

    await expectLater(future, completes);
  });
}
