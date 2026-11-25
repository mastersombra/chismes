import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/social/domain/entities/follow_result.dart';
import 'package:chismes/features/social/domain/usecases/block_user.dart';
import 'package:chismes/features/social/domain/usecases/follow_user.dart';
import 'package:chismes/features/social/domain/usecases/get_blocked_users.dart';
import 'package:chismes/features/social/domain/usecases/get_follow_list.dart';
import 'package:chismes/features/social/domain/usecases/get_follow_requests.dart';
import 'package:chismes/features/social/domain/usecases/get_user_gossips.dart';
import 'package:chismes/features/social/domain/usecases/get_user_profile.dart';
import 'package:chismes/features/social/domain/usecases/remove_follower.dart';
import 'package:chismes/features/social/domain/usecases/respond_follow_request.dart';
import 'package:chismes/features/social/domain/usecases/search_users.dart';
import 'package:chismes/features/social/domain/usecases/unblock_user.dart';
import 'package:chismes/features/social/domain/usecases/unfollow_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../social_fixtures.dart';
import '../../social_test_mocks.mocks.dart';

void main() {
  setUpAll(provideSocialDummies);

  late MockSocialRepository repository;

  setUp(() => repository = MockSocialRepository());

  group('casos de uso que delegan al repositorio', () {
    test('FollowUser', () async {
      when(repository.followUser('u1'))
          .thenAnswer((_) async => Result.success(FollowResult.requested));

      final result = await FollowUser(repository)('u1');

      expect(result.successValue, FollowResult.requested);
    });

    test('UnfollowUser, RemoveFollower, BlockUser, UnblockUser', () async {
      when(repository.unfollowUser(any)).thenAnswer((_) async => Result.success(null));
      when(repository.removeFollower(any)).thenAnswer((_) async => Result.success(null));
      when(repository.blockUser(any)).thenAnswer((_) async => Result.success(null));
      when(repository.unblockUser(any)).thenAnswer((_) async => Result.success(null));

      await UnfollowUser(repository)('a');
      await RemoveFollower(repository)('b');
      await BlockUser(repository)('c');
      await UnblockUser(repository)('d');

      verify(repository.unfollowUser('a')).called(1);
      verify(repository.removeFollower('b')).called(1);
      verify(repository.blockUser('c')).called(1);
      verify(repository.unblockUser('d')).called(1);
    });

    test('RespondFollowRequest pasa accept', () async {
      when(repository.respondFollowRequest(any, accept: anyNamed('accept')))
          .thenAnswer((_) async => Result.success(null));

      await RespondFollowRequest(repository)('u1', accept: false);

      verify(repository.respondFollowRequest('u1', accept: false)).called(1);
    });

    test('GetUserProfile propaga el Failure', () async {
      const failure = DataFailure(code: ErrorCode.userNotAvailable);
      when(repository.getUserProfile('u1')).thenAnswer((_) async => Result.failure(failure));

      expect((await GetUserProfile(repository)('u1')).failureValue, failure);
    });

    test('GetFollowList y GetUserGossips pasan tamaño y cursor', () async {
      when(repository.getFollowList(any, any,
              pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
          .thenAnswer((_) async => Result.success(page([tUser])));
      when(repository.getUserGossips(any,
              pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
          .thenAnswer((_) async => Result.success(page([tProfileGossip('g1')])));

      await GetFollowList(repository)('u1', FollowListKind.following, pageSize: 5, cursor: tCursor);
      await GetUserGossips(repository)('u1', pageSize: 7, cursor: tCursor);

      verify(repository.getFollowList('u1', FollowListKind.following, pageSize: 5, cursor: tCursor))
          .called(1);
      verify(repository.getUserGossips('u1', pageSize: 7, cursor: tCursor)).called(1);
    });

    test('GetFollowRequests y GetBlockedUsers', () async {
      when(repository.getFollowRequests()).thenAnswer((_) async => Result.success([tRequest]));
      when(repository.getBlockedUsers()).thenAnswer((_) async => Result.success([tUser]));

      expect((await GetFollowRequests(repository)()).successValue, [tRequest]);
      expect((await GetBlockedUsers(repository)()).successValue, [tUser]);
    });
  });

  group('SearchUsers', () {
    test('quita espacios y la @ inicial antes de buscar', () async {
      when(repository.searchUsers(any, limit: anyNamed('limit')))
          .thenAnswer((_) async => Result.success([tUser]));

      final result = await SearchUsers(repository)('  @ana ');

      expect(result.successValue, [tUser]);
      verify(repository.searchUsers('ana', limit: 20)).called(1);
    });

    test('con menos de 2 caracteres no llama al servidor', () async {
      final useCase = SearchUsers(repository);

      expect((await useCase('a')).successValue, isEmpty);
      expect((await useCase('@@a')).successValue, isEmpty);
      expect((await useCase('   ')).successValue, isEmpty);
      verifyZeroInteractions(repository);
    });

    test('normalize', () {
      expect(SearchUsers.normalize(' @@beto '), 'beto');
      expect(SearchUsers.normalize('ana@x'), 'ana@x');
    });
  });
}
