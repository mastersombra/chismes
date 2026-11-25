import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/notifications/data/models/app_notification_model.dart';
import 'package:chismes/features/notifications/data/models/notification_page_model.dart';
import 'package:chismes/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../notifications_fixtures.dart';
import '../../notifications_test_mocks.mocks.dart';

void main() {
  late MockSupabaseNotificationsRemoteDataSource remote;
  late MockAppLogger logger;
  late NotificationsRepositoryImpl repository;

  setUp(() {
    remote = MockSupabaseNotificationsRemoteDataSource();
    logger = MockAppLogger();
    repository = NotificationsRepositoryImpl(remote, logger);
  });

  const cs401 = PostgrestException(message: 'not_authenticated', code: 'CS401');

  group('getNotifications', () {
    test('primera página: sin cursor, convierte a entidad', () async {
      when(remote.getNotifications(
        pageSize: anyNamed('pageSize'),
        cursorCreatedAt: anyNamed('cursorCreatedAt'),
        cursorId: anyNamed('cursorId'),
      )).thenAnswer((_) async => NotificationPageModel(
            data: [AppNotificationModel.fromJson(notificationJson(actor: actorJson()))],
            hasMore: true,
            nextCursorCreatedAt: kCreatedAt,
            nextCursorId: 'n1',
          ));

      final result = await repository.getNotifications();

      verify(remote.getNotifications(pageSize: 30, cursorCreatedAt: null, cursorId: null)).called(1);
      final page = result.successValue!;
      expect(page.items.single.actor, tActor);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor!.id, 'n1');
    });

    test('con cursor: lo manda en UTC ISO-8601', () async {
      when(remote.getNotifications(
        pageSize: anyNamed('pageSize'),
        cursorCreatedAt: anyNamed('cursorCreatedAt'),
        cursorId: anyNamed('cursorId'),
      )).thenAnswer((_) async => const NotificationPageModel(data: [], hasMore: false));

      await repository.getNotifications(pageSize: 5, cursor: tCursor);

      verify(remote.getNotifications(
        pageSize: 5,
        cursorCreatedAt: '2026-11-20T00:00:00.000Z',
        cursorId: 'last',
      )).called(1);
    });

    test('error → Result.failure (nunca lanza) y log warning', () async {
      when(remote.getNotifications(
        pageSize: anyNamed('pageSize'),
        cursorCreatedAt: anyNamed('cursorCreatedAt'),
        cursorId: anyNamed('cursorId'),
      )).thenThrow(cs401);

      final result = await repository.getNotifications();

      expect(result.failureValue, isA<Failure>());
      verify(logger.w(any, context: anyNamed('context'))).called(1);
    });
  });

  group('getUnreadCount', () {
    test('éxito → cantidad', () async {
      when(remote.getUnreadCount()).thenAnswer((_) async => 12);

      expect((await repository.getUnreadCount()).successValue, 12);
    });

    test('CS401 → AuthFailure', () async {
      when(remote.getUnreadCount()).thenThrow(cs401);

      final failure = (await repository.getUnreadCount()).failureValue;

      expect(failure, isA<AuthFailure>());
    });
  });

  group('markRead', () {
    test('sin ids → todas', () async {
      when(remote.markRead(null)).thenAnswer((_) async => 4);

      expect((await repository.markRead()).successValue, 4);
      verify(remote.markRead(null)).called(1);
    });

    test('con ids los pasa', () async {
      when(remote.markRead(['a'])).thenAnswer((_) async => 1);

      expect((await repository.markRead(ids: ['a'])).successValue, 1);
    });

    test('error genérico → failure', () async {
      when(remote.markRead(any)).thenThrow(Exception('boom'));

      final failure = (await repository.markRead()).failureValue;

      expect(failure, isNotNull);
      expect(failure!.code, isNot(ErrorCode.userNotAvailable));
    });
  });
}
