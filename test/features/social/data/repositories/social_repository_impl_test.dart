import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/social/data/models/follow_request_model.dart';
import 'package:chismes/features/social/data/models/social_page_model.dart';
import 'package:chismes/features/social/data/models/social_user_model.dart';
import 'package:chismes/features/social/data/models/user_gossip_model.dart';
import 'package:chismes/features/social/data/models/user_profile_model.dart';
import 'package:chismes/features/social/data/repositories/social_repository_impl.dart';
import 'package:chismes/features/social/domain/entities/follow_result.dart';
import 'package:chismes/features/social/domain/entities/social_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../social_fixtures.dart';
import '../../social_test_mocks.mocks.dart';

void main() {
  late MockSupabaseSocialRemoteDataSource remote;
  late SocialRepositoryImpl repository;

  setUp(() {
    remote = MockSupabaseSocialRemoteDataSource();
    repository = SocialRepositoryImpl(remote, MockAppLogger());
  });

  const cs404 = PostgrestException(message: 'user_not_available', code: 'CS404');

  group('followUser', () {
    test("'following' → FollowResult.following", () async {
      when(remote.followUser(kOtherUserId)).thenAnswer((_) async => 'following');

      final result = await repository.followUser(kOtherUserId);

      expect(result.successValue, FollowResult.following);
    });

    test("'requested' → FollowResult.requested", () async {
      when(remote.followUser(kOtherUserId)).thenAnswer((_) async => 'requested');

      expect((await repository.followUser(kOtherUserId)).successValue, FollowResult.requested);
    });

    test('valor desconocido → Failure (nunca lanza)', () async {
      when(remote.followUser(kOtherUserId)).thenAnswer((_) async => 'other');

      final result = await repository.followUser(kOtherUserId);

      expect(result.isFailure, isTrue);
    });

    test('CS404 → DataFailure(userNotAvailable)', () async {
      when(remote.followUser(kOtherUserId)).thenThrow(cs404);

      final failure = (await repository.followUser(kOtherUserId)).failureValue;

      expect(failure, isA<DataFailure>());
      expect(failure!.code, ErrorCode.userNotAvailable);
    });

    test('CS400 (seguirse a sí mismo) → ValidationFailure(invalidInput)', () async {
      when(remote.followUser(kMyUserId)).thenThrow(
        const PostgrestException(message: 'cannot_follow_self', code: 'CS400'),
      );

      final failure = (await repository.followUser(kMyUserId)).failureValue;

      expect(failure, isA<ValidationFailure>());
      expect(failure!.code, ErrorCode.invalidInput);
    });
  });

  group('acciones sin valor', () {
    test('unfollow, respond, remove, block, unblock delegan y devuelven success', () async {
      when(remote.unfollowUser(any)).thenAnswer((_) async {});
      when(remote.respondFollowRequest(any, any)).thenAnswer((_) async {});
      when(remote.removeFollower(any)).thenAnswer((_) async {});
      when(remote.blockUser(any)).thenAnswer((_) async {});
      when(remote.unblockUser(any)).thenAnswer((_) async {});

      expect((await repository.unfollowUser('u1')).isSuccess, isTrue);
      expect((await repository.respondFollowRequest('u2', accept: true)).isSuccess, isTrue);
      expect((await repository.removeFollower('u3')).isSuccess, isTrue);
      expect((await repository.blockUser('u4')).isSuccess, isTrue);
      expect((await repository.unblockUser('u5')).isSuccess, isTrue);

      verify(remote.unfollowUser('u1')).called(1);
      verify(remote.respondFollowRequest('u2', true)).called(1);
      verify(remote.removeFollower('u3')).called(1);
      verify(remote.blockUser('u4')).called(1);
      verify(remote.unblockUser('u5')).called(1);
    });

    test('un error se devuelve como Failure', () async {
      when(remote.blockUser(any)).thenThrow(
        const PostgrestException(message: 'not_authenticated', code: 'CS401'),
      );

      final failure = (await repository.blockUser('u1')).failureValue;

      expect(failure, isA<AuthFailure>());
      expect(failure!.code, ErrorCode.userNotAuthenticated);
    });
  });

  group('getUserProfile', () {
    test('perfil → entidad', () async {
      when(remote.getUserProfile(kOtherUserId))
          .thenAnswer((_) async => UserProfileModel.fromJson(profileJson()));

      final profile = (await repository.getUserProfile(kOtherUserId)).successValue!;

      expect(profile.id, kOtherUserId);
      expect(profile.followersCount, 10);
    });

    test('NULL (no existe o me bloqueó) → DataFailure(userNotAvailable)', () async {
      when(remote.getUserProfile(kOtherUserId)).thenAnswer((_) async => null);

      final failure = (await repository.getUserProfile(kOtherUserId)).failureValue;

      expect(failure, isA<DataFailure>());
      expect(failure!.code, ErrorCode.userNotAvailable);
    });
  });

  group('getFollowList', () {
    test('manda el cursor en UTC ISO8601 y convierte la página', () async {
      when(remote.getFollowList(
        any,
        any,
        pageSize: anyNamed('pageSize'),
        cursorCreatedAt: anyNamed('cursorCreatedAt'),
        cursorId: anyNamed('cursorId'),
      )).thenAnswer((_) async => SocialPageModel(
            data: [SocialUserModel.fromJson(userJson())],
            hasMore: true,
            nextCursorCreatedAt: '2026-11-19T00:00:00Z',
            nextCursorId: 'u9',
          ));

      final result = await repository.getFollowList(
        kOtherUserId,
        FollowListKind.followers,
        cursor: tCursor,
      );

      verify(remote.getFollowList(
        kOtherUserId,
        FollowListKind.followers,
        pageSize: 30,
        cursorCreatedAt: '2026-11-20T10:00:00.000Z',
        cursorId: 'last',
      )).called(1);
      final page = result.successValue!;
      expect(page.items.single, tUser);
      expect(page.nextCursor, SocialCursor(createdAt: DateTime.utc(2026, 11, 19), id: 'u9'));
    });

    test('CS404 (privada que no sigo) → userNotAvailable', () async {
      when(remote.getFollowList(any, any,
              pageSize: anyNamed('pageSize'),
              cursorCreatedAt: anyNamed('cursorCreatedAt'),
              cursorId: anyNamed('cursorId')))
          .thenThrow(cs404);

      final failure =
          (await repository.getFollowList(kOtherUserId, FollowListKind.following)).failureValue;

      expect(failure!.code, ErrorCode.userNotAvailable);
    });
  });

  group('listas', () {
    test('getFollowRequests, getBlockedUsers y searchUsers convierten a entidades', () async {
      when(remote.getFollowRequests()).thenAnswer((_) async => [
            FollowRequestModel.fromJson({
              'user': userJson(),
              'created_at': '2026-11-21T00:00:00Z',
            }),
          ]);
      when(remote.getBlockedUsers())
          .thenAnswer((_) async => [SocialUserModel.fromJson(userJson())]);
      when(remote.searchUsers('ana', 20))
          .thenAnswer((_) async => [SocialUserModel.fromJson(userJson())]);

      expect((await repository.getFollowRequests()).successValue!.single.user, tUser);
      expect((await repository.getBlockedUsers()).successValue, [tUser]);
      expect((await repository.searchUsers('ana')).successValue, [tUser]);
    });

    test('getUserGossips convierte los chismes y pasa el cursor', () async {
      when(remote.getUserGossips(any,
              pageSize: anyNamed('pageSize'),
              cursorCreatedAt: anyNamed('cursorCreatedAt'),
              cursorId: anyNamed('cursorId')))
          .thenAnswer((_) async => SocialPageModel(
                data: [UserGossipModel.fromJson(userGossipJson('g1'))],
                hasMore: false,
              ));

      final result = await repository.getUserGossips(kOtherUserId, pageSize: 10, cursor: tCursor);

      verify(remote.getUserGossips(kOtherUserId,
              pageSize: 10, cursorCreatedAt: '2026-11-20T10:00:00.000Z', cursorId: 'last'))
          .called(1);
      expect(result.successValue!.items.single.author?.username, 'ana');
    });
  });
}
