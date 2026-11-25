import 'package:chismes/core/error/app_exception.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/features/social/data/datasources/supabase_social_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../../../helpers/fake_supabase_http.dart';
import '../../social_fixtures.dart';
import '../../social_test_mocks.mocks.dart';

void main() {
  late FakeSupabaseHttp fake;
  late MockAppLogger logger;
  late SupabaseSocialRemoteDataSource dataSource;

  setUp(() {
    fake = FakeSupabaseHttp();
    logger = MockAppLogger();
    dataSource = SupabaseSocialRemoteDataSource(fake.client, logger);
  });

  String rpcPath(String fn) => '/rest/v1/rpc/$fn';

  group('acciones (solo mandan el otro usuario, nunca el propio)', () {
    test('followUser llama follow_user con p_target y devuelve el estado', () async {
      fake.respondJson('requested');

      final result = await dataSource.followUser(kOtherUserId);

      expect(fake.lastRequest.url.path, rpcPath('follow_user'));
      expect(fake.lastBody, {'p_target': kOtherUserId});
      expect(result, 'requested');
    });

    test('unfollowUser llama unfollow_user con p_target', () async {
      fake.respondRaw('null');

      await dataSource.unfollowUser(kOtherUserId);

      expect(fake.lastRequest.url.path, rpcPath('unfollow_user'));
      expect(fake.lastBody, {'p_target': kOtherUserId});
    });

    test('respondFollowRequest manda p_requester y p_accept', () async {
      fake.respondRaw('null');

      await dataSource.respondFollowRequest(kOtherUserId, false);

      expect(fake.lastRequest.url.path, rpcPath('respond_follow_request'));
      expect(fake.lastBody, {'p_requester': kOtherUserId, 'p_accept': false});
    });

    test('removeFollower manda p_follower', () async {
      fake.respondRaw('null');

      await dataSource.removeFollower(kOtherUserId);

      expect(fake.lastRequest.url.path, rpcPath('remove_follower'));
      expect(fake.lastBody, {'p_follower': kOtherUserId});
    });

    test('blockUser y unblockUser mandan p_target', () async {
      fake.respondRaw('null');

      await dataSource.blockUser(kOtherUserId);
      expect(fake.lastRequest.url.path, rpcPath('block_user'));
      expect(fake.lastBody, {'p_target': kOtherUserId});

      await dataSource.unblockUser(kOtherUserId);
      expect(fake.lastRequest.url.path, rpcPath('unblock_user'));
      expect(fake.lastBody, {'p_target': kOtherUserId});
    });
  });

  group('getUserProfile', () {
    test('deserializa el perfil', () async {
      fake.respondJson(profileJson(isFollowing: true));

      final model = await dataSource.getUserProfile(kOtherUserId);

      expect(fake.lastRequest.url.path, rpcPath('get_user_profile'));
      expect(fake.lastBody, {'p_user': kOtherUserId});
      expect(model!.isFollowing, isTrue);
    });

    test('NULL (no existe o me bloqueó) → null', () async {
      fake.respondRaw('null');

      expect(await dataSource.getUserProfile(kOtherUserId), isNull);
    });

    test('perfil bloqueado por mí: has_blocked', () async {
      fake.respondJson(blockedProfileJson());

      final model = await dataSource.getUserProfile(kOtherUserId);

      expect(model!.hasBlocked, isTrue);
    });
  });

  group('getFollowList', () {
    test('manda usuario, tipo, tamaño y cursor; deserializa la página', () async {
      fake.respondJson({
        'data': [userJson()],
        'has_more': true,
        'next_cursor': {'created_at': '2026-11-20T10:00:00Z', 'id': 'u9'},
      });

      final page = await dataSource.getFollowList(
        kOtherUserId,
        FollowListKind.following,
        pageSize: 30,
        cursorCreatedAt: '2026-11-21T00:00:00.000Z',
        cursorId: 'u5',
      );

      expect(fake.lastRequest.url.path, rpcPath('get_follow_list'));
      expect(fake.lastBody, {
        'p_user': kOtherUserId,
        'p_kind': 'following',
        'page_size': 30,
        'cursor_created_at': '2026-11-21T00:00:00.000Z',
        'cursor_id': 'u5',
      });
      expect(page.data.single.id, kOtherUserId);
      expect(page.hasMore, isTrue);
      expect(page.nextCursorId, 'u9');
    });

    test('CS404 (privada que no sigo) se propaga como PostgrestException', () async {
      fake.respondError(400, message: 'user_not_available', code: 'CS404');

      await expectLater(
        dataSource.getFollowList(kOtherUserId, FollowListKind.followers, pageSize: 30),
        throwsA(isA<PostgrestException>().having((e) => e.code, 'code', 'CS404')),
      );
      // Flujo esperado: aviso, no error persistido
      verify(logger.w('get_follow_list rejected', context: {'code': 'CS404'})).called(1);
      verifyNever(logger.e(any,
          error: anyNamed('error'),
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context')));
    });
  });

  group('listas', () {
    test('getFollowRequests llama get_follow_requests sin params', () async {
      fake.respondJson([
        {'user': userJson(), 'created_at': '2026-11-21T08:00:00Z'},
      ]);

      final requests = await dataSource.getFollowRequests();

      expect(fake.lastRequest.url.path, rpcPath('get_follow_requests'));
      expect(requests.single.user.id, kOtherUserId);
    });

    test('getBlockedUsers llama get_blocked_users', () async {
      fake.respondJson([userJson(), userJson(id: 'u2')]);

      final users = await dataSource.getBlockedUsers();

      expect(fake.lastRequest.url.path, rpcPath('get_blocked_users'));
      expect(users, hasLength(2));
    });

    test('searchUsers manda search_query y result_limit', () async {
      fake.respondJson([userJson()]);

      final users = await dataSource.searchUsers('ana', 20);

      expect(fake.lastRequest.url.path, rpcPath('search_users'));
      expect(fake.lastBody, {'search_query': 'ana', 'result_limit': 20});
      expect(users.single.username, 'ana');
    });

    test('getUserGossips manda usuario, tamaño y cursor', () async {
      fake.respondJson({
        'data': [userGossipJson('g1')],
        'has_more': false,
        'next_cursor': null,
      });

      final page = await dataSource.getUserGossips(kOtherUserId, pageSize: 20);

      expect(fake.lastRequest.url.path, rpcPath('get_user_gossips'));
      expect(fake.lastBody, {
        'p_user': kOtherUserId,
        'page_size': 20,
        'cursor_created_at': null,
        'cursor_id': null,
      });
      expect(page.data.single.id, 'g1');
    });
  });

  group('errores', () {
    test('error inesperado del servidor: loguea error y propaga', () async {
      fake.respondError(500, message: 'boom', code: 'XX000');

      await expectLater(dataSource.getBlockedUsers(), throwsA(isA<PostgrestException>()));
      verify(logger.e('Supabase error in get_blocked_users',
              error: anyNamed('error'),
              stackTrace: anyNamed('stackTrace'),
              context: {'code': 'XX000'}))
          .called(1);
    });

    test('respuesta con forma inesperada → ServerException(serverError)', () async {
      fake.respondJson({'not': 'a list'});

      await expectLater(
        dataSource.getBlockedUsers(),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', ErrorCode.serverError)),
      );
    });

    test('follow_user con un tipo inesperado → ServerException', () async {
      fake.respondJson(42);

      await expectLater(dataSource.followUser(kOtherUserId), throwsA(isA<ServerException>()));
    });
  });
}
