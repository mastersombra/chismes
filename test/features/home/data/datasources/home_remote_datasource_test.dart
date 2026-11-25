import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/error/app_exception.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/home/data/datasources/home_remote_datasource.dart';
import 'package:chismes/features/home/domain/entities/feed_cursor.dart';

import '../../../../helpers/fake_supabase_http.dart';
import '../../../../helpers/mock_app_logger_helper.dart';

Map<String, dynamic> _feedGossipJson(String id) => {
      'id': id,
      'subject': 'Subject $id',
      'content': 'Content $id',
      'city_id': 'MED',
      'created_at': '2024-01-15T10:30:00.000Z',
      'likes': 3,
      'comments': 1,
      'shares': 0,
      'published_as': 'anonymous',
      'created_by': null,
      'image_url': null,
      'score': 12.5,
      'is_from_my_city': true,
      'is_trending': false,
    };

TypeMatcher<ServerException> _serverException(ErrorCode code) =>
    isA<ServerException>().having((e) => e.code, 'code', code);

void main() {
  late FakeSupabaseHttp fake;
  late HomeRemoteDataSource dataSource;

  setUp(() {
    fake = FakeSupabaseHttp();
    dataSource = HomeRemoteDataSource(fake.client, MockAppLogger());
  });

  group('getPopularFeed', () {
    test('llama al RPC get_popular_feed y deserializa la página', () async {
      fake.respondJson({
        'data': [_feedGossipJson('g1'), _feedGossipJson('g2')],
        'has_more': true,
        'next_cursor': {'score': 12.5, 'id': 'g2'},
      });

      final result = await dataSource.getPopularFeed(userCityId: 'MED');

      expect(fake.lastRequest.method, 'POST');
      expect(fake.lastRequest.url.path, '/rest/v1/rpc/get_popular_feed');
      expect(result.data.map((g) => g.id), ['g1', 'g2']);
      expect(result.hasMore, isTrue);
      expect(result.nextCursor, {'score': 12.5, 'id': 'g2'});
    });

    test('envía ciudad, pageSize y cursor como params del RPC', () async {
      fake.respondJson({'data': [], 'has_more': false});

      await dataSource.getPopularFeed(
        userCityId: 'MED',
        userRegionId: 'co-antioquia',
        userCountryId: 'CO',
        pageSize: 50,
        cursor: const FeedCursor.popular(score: 99.5, id: 'g9'),
      );

      expect(fake.lastBody, {
        'user_city_id': 'MED',
        'user_region_id': 'co-antioquia',
        'user_country_id': 'CO',
        'page_size': 50,
        'cursor_score': 99.5,
        'cursor_id': 'g9',
      });
    });

    test('envía nulls cuando no hay ciudad ni cursor y usa pageSize 20', () async {
      fake.respondJson({'data': [], 'has_more': false});

      await dataSource.getPopularFeed(userCityId: null);

      expect(fake.lastBody, {
        'user_city_id': null,
        'user_region_id': null,
        'user_country_id': null,
        'page_size': 20,
        'cursor_score': null,
        'cursor_id': null,
      });
    });

    test('retorna página vacía cuando el RPC responde null', () async {
      fake.respondRaw('null');

      final result = await dataSource.getPopularFeed(userCityId: 'MED');

      expect(result.data, isEmpty);
      expect(result.hasMore, isFalse);
      expect(result.nextCursor, isNull);
    });

    test('convierte PostgrestException en ServerException(serverError)', () async {
      fake.respondError(400, message: 'function does not exist');

      expect(
        () => dataSource.getPopularFeed(userCityId: 'MED'),
        throwsA(_serverException(ErrorCode.serverError).having(
          (e) => e.technicalMessage,
          'technicalMessage',
          contains('function does not exist'),
        )),
      );
    });

    test('convierte JSON malformado en ServerException(serverError)', () async {
      fake.respondJson({'has_more': false});

      expect(
        () => dataSource.getPopularFeed(userCityId: 'MED'),
        throwsA(_serverException(ErrorCode.serverError).having(
          (e) => e.technicalMessage,
          'technicalMessage',
          contains('formato'),
        )),
      );
    });

    test('convierte respuesta de tipo inesperado en ServerException(unknownError)',
        () async {
      fake.respondJson([1, 2, 3]);

      expect(
        () => dataSource.getPopularFeed(userCityId: 'MED'),
        throwsA(_serverException(ErrorCode.unknownError)),
      );
    });
  });

  group('getFollowingFeed', () {
    test('llama al RPC get_following_feed y deserializa la página', () async {
      fake.respondJson({
        'data': [_feedGossipJson('g1')],
        'has_more': false,
        'next_cursor': null,
      });

      final result = await dataSource.getFollowingFeed();

      expect(fake.lastRequest.url.path, '/rest/v1/rpc/get_following_feed');
      expect(result.data.single.id, 'g1');
      expect(result.hasMore, isFalse);
    });

    test('envía pageSize y cursor por created_at en ISO8601 (sin user id: el servidor usa auth.uid())', () async {
      fake.respondJson({'data': [], 'has_more': false});

      await dataSource.getFollowingFeed(
        pageSize: 30,
        cursor: FeedCursor.following(
          createdAt: DateTime.utc(2024, 1, 15, 10, 30),
          id: 'g7',
        ),
      );

      expect(fake.lastBody, {
        'page_size': 30,
        'cursor_created_at': '2024-01-15T10:30:00.000Z',
        'cursor_id': 'g7',
      });
    });

    test('retorna página vacía cuando el RPC responde null', () async {
      fake.respondRaw('null');

      final result = await dataSource.getFollowingFeed();

      expect(result.data, isEmpty);
      expect(result.hasMore, isFalse);
    });

    test('convierte PostgrestException en ServerException(serverError)', () async {
      fake.respondError(401, message: 'JWT expired');

      expect(
        () => dataSource.getFollowingFeed(),
        throwsA(_serverException(ErrorCode.serverError).having(
          (e) => e.technicalMessage,
          'technicalMessage',
          contains('JWT expired'),
        )),
      );
    });

    test('convierte JSON malformado en ServerException(unknownError)', () async {
      fake.respondJson({'data': 'not-a-list', 'has_more': false});

      expect(
        () => dataSource.getFollowingFeed(),
        throwsA(_serverException(ErrorCode.unknownError)),
      );
    });
  });

  group('checkNewGossips', () {
    test('retorna el conteo del RPC check_new_gossips', () async {
      fake.respondJson(5);

      final count = await dataSource.checkNewGossips(
        userCityId: 'MED',
        userRegionId: 'co-antioquia',
        userCountryId: 'CO',
        since: DateTime.utc(2024, 1, 15, 10),
      );

      expect(count, 5);
      expect(fake.lastRequest.url.path, '/rest/v1/rpc/check_new_gossips');
      expect(fake.lastBody, {
        'user_city_id': 'MED',
        'user_region_id': 'co-antioquia',
        'user_country_id': 'CO',
        'since_timestamp': '2024-01-15T10:00:00.000Z',
      });
    });

    test('convierte PostgrestException en ServerException(serverError)', () async {
      fake.respondError(400);

      expect(
        () => dataSource.checkNewGossips(
            userCityId: null, since: DateTime.utc(2024)),
        throwsA(_serverException(ErrorCode.serverError)),
      );
    });

    test('convierte respuesta no entera en ServerException(unknownError)', () async {
      fake.respondJson({'count': 5});

      expect(
        () => dataSource.checkNewGossips(
            userCityId: null, since: DateTime.utc(2024)),
        throwsA(_serverException(ErrorCode.unknownError)),
      );
    });
  });
}
