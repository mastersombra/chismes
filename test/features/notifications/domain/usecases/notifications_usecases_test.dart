import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/notifications/domain/usecases/get_notifications.dart';
import 'package:chismes/features/notifications/domain/usecases/get_unread_notifications_count.dart';
import 'package:chismes/features/notifications/domain/usecases/mark_notifications_read.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../notifications_fixtures.dart';
import '../../notifications_test_mocks.mocks.dart';

void main() {
  late MockNotificationsRepository repository;

  setUpAll(provideNotificationsDummies);

  setUp(() => repository = MockNotificationsRepository());

  test('GetNotifications delega con pageSize y cursor', () async {
    final page = notificationPage([tNotification()]);
    when(repository.getNotifications(pageSize: 10, cursor: tCursor))
        .thenAnswer((_) async => Result.success(page));

    final result = await GetNotifications(repository)(pageSize: 10, cursor: tCursor);

    expect(result.successValue, page);
  });

  test('GetNotifications usa 30 por defecto', () async {
    when(repository.getNotifications(pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
        .thenAnswer((_) async => Result.success(notificationPage(const [])));

    await GetNotifications(repository)();

    verify(repository.getNotifications(pageSize: 30, cursor: null)).called(1);
  });

  test('GetUnreadNotificationsCount delega', () async {
    when(repository.getUnreadCount()).thenAnswer((_) async => Result.success(5));

    expect((await GetUnreadNotificationsCount(repository)()).successValue, 5);
  });

  test('MarkNotificationsRead delega (todas o ids)', () async {
    when(repository.markRead(ids: anyNamed('ids'))).thenAnswer((_) async => Result.success(2));

    await MarkNotificationsRead(repository)();
    await MarkNotificationsRead(repository)(ids: ['a']);

    verify(repository.markRead(ids: null)).called(1);
    verify(repository.markRead(ids: ['a'])).called(1);
  });
}
