import 'package:chismes/core/error/app_exception.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/notifications/data/datasources/supabase_notifications_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../../../helpers/fake_supabase_http.dart';
import '../../notifications_fixtures.dart';
import '../../notifications_test_mocks.mocks.dart';

void main() {
  late FakeSupabaseHttp fake;
  late MockAppLogger logger;
  late SupabaseNotificationsRemoteDataSource dataSource;

  setUp(() {
    fake = FakeSupabaseHttp();
    logger = MockAppLogger();
    dataSource = SupabaseNotificationsRemoteDataSource(fake.client, logger);
  });

  String rpcPath(String fn) => '/rest/v1/rpc/$fn';

  group('getNotifications', () {
    test('primera página: manda page_size y cursor null, deserializa', () async {
      fake.respondJson(pageJson([notificationJson(actor: actorJson())]));

      final page = await dataSource.getNotifications(pageSize: 30);

      expect(fake.lastRequest.url.path, rpcPath('get_notifications'));
      expect(fake.lastBody, {'page_size': 30, 'cursor_created_at': null, 'cursor_id': null});
      expect(page.data, hasLength(1));
      expect(page.data.single.actor!.username, 'beto');
    });

    test('con cursor: lo manda tal cual', () async {
      fake.respondJson(pageJson([]));

      await dataSource.getNotifications(pageSize: 10, cursorCreatedAt: kCreatedAt, cursorId: 'c');

      expect(fake.lastBody, {'page_size': 10, 'cursor_created_at': kCreatedAt, 'cursor_id': 'c'});
    });

    test('respuesta null → página vacía', () async {
      fake.respondRaw('null');

      final page = await dataSource.getNotifications(pageSize: 30);

      expect(page.data, isEmpty);
    });

    test('forma inesperada → ServerException(serverError)', () async {
      fake.respondJson([1, 2]);

      await expectLater(
        dataSource.getNotifications(pageSize: 30),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', ErrorCode.serverError)),
      );
      verify(logger.e(any, error: anyNamed('error'), stackTrace: anyNamed('stackTrace'))).called(1);
    });

    test('item inválido (FormatException) → ServerException', () async {
      fake.respondJson(pageJson([{'id': 1}]));

      await expectLater(
        dataSource.getNotifications(pageSize: 30),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('getUnreadCount', () {
    test('llama get_unread_notifications_count sin parámetros y devuelve int', () async {
      fake.respondRaw('7');

      final count = await dataSource.getUnreadCount();

      expect(fake.lastRequest.url.path, rpcPath('get_unread_notifications_count'));
      expect(count, 7);
    });
  });

  group('markRead', () {
    test('null → p_ids null (todas) y devuelve cuántas', () async {
      fake.respondRaw('3');

      final count = await dataSource.markRead(null);

      expect(fake.lastRequest.url.path, rpcPath('mark_notifications_read'));
      expect(fake.lastBody, {'p_ids': null});
      expect(count, 3);
    });

    test('con ids los manda; respuesta null → 0', () async {
      fake.respondRaw('null');

      final count = await dataSource.markRead(['a', 'b']);

      expect(fake.lastBody, {'p_ids': ['a', 'b']});
      expect(count, 0);
    });
  });

  group('errores de Supabase (se propagan)', () {
    test('CS401 → warning (flujo normal) y rethrow', () async {
      fake.respondError(401, code: 'CS401', message: 'not_authenticated');

      await expectLater(dataSource.getUnreadCount(), throwsA(isA<PostgrestException>()));
      verify(logger.w(any, context: anyNamed('context'))).called(1);
      verifyNever(logger.e(any,
          error: anyNamed('error'), stackTrace: anyNamed('stackTrace'), context: anyNamed('context')));
    });

    test('otro código → error y rethrow', () async {
      fake.respondError(500, code: 'XX000');

      await expectLater(dataSource.markRead(null), throwsA(isA<PostgrestException>()));
      verify(logger.e(any,
              error: anyNamed('error'), stackTrace: anyNamed('stackTrace'), context: anyNamed('context')))
          .called(1);
    });
  });
}
