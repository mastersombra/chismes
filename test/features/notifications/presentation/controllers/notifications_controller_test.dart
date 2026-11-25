import 'dart:async';

import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/notifications/domain/entities/notification_page.dart';
import 'package:chismes/features/notifications/domain/usecases/get_notifications.dart';
import 'package:chismes/features/notifications/domain/usecases/get_unread_notifications_count.dart';
import 'package:chismes/features/notifications/domain/usecases/mark_notifications_read.dart';
import 'package:chismes/features/notifications/presentation/controllers/notifications_badge_controller.dart';
import 'package:chismes/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../notifications_fixtures.dart';
import '../../notifications_test_mocks.mocks.dart';

void main() {
  late MockNotificationsRepository repository;
  late MockAppLogger logger;
  late NotificationsBadgeController badge;
  late NotificationsController controller;

  setUpAll(provideNotificationsDummies);

  setUp(() {
    repository = MockNotificationsRepository();
    logger = MockAppLogger();
    final auth = MockAuthService();
    when(auth.userStream).thenAnswer((_) => const Stream.empty());
    badge = NotificationsBadgeController(GetUnreadNotificationsCount(repository), auth, logger);
    controller = NotificationsController(
      GetNotifications(repository),
      MarkNotificationsRead(repository),
      badge,
      logger,
    );
    when(repository.markRead(ids: anyNamed('ids'))).thenAnswer((_) async => Result.success(1));
    when(repository.getUnreadCount()).thenAnswer((_) async => Result.success(4));
  });

  tearDown(() {
    controller.dispose();
    badge.dispose();
  });

  void stubFirst(Result<Failure, NotificationPage> result) {
    when(repository.getNotifications(pageSize: anyNamed('pageSize'), cursor: null))
        .thenAnswer((_) async => result);
  }

  void stubNext(Result<Failure, NotificationPage> result) {
    when(repository.getNotifications(pageSize: anyNamed('pageSize'), cursor: tCursor))
        .thenAnswer((_) async => result);
  }

  test('estado inicial', () {
    expect(controller.status, NotificationsStatus.initial);
    expect(controller.items, isEmpty);
    expect(controller.hasMore, isFalse);
    expect(controller.isLoadingMore, isFalse);
    expect(controller.failure, isNull);
  });

  test('load: loading → loaded, marca todas leídas una vez y limpia la campana', () async {
    await badge.refresh();
    expect(badge.value, 4);
    stubFirst(Result.success(notificationPage([tNotification()], hasMore: true, cursor: tCursor)));
    final statuses = <NotificationsStatus>[];
    controller.addListener(() => statuses.add(controller.status));

    await controller.load();

    expect(statuses.first, NotificationsStatus.loading);
    expect(controller.status, NotificationsStatus.loaded);
    expect(controller.items, [tNotification()]);
    expect(controller.hasMore, isTrue);
    verify(repository.getNotifications(pageSize: 30, cursor: null)).called(1);
    verify(repository.markRead(ids: ['n1'])).called(1);
    expect(badge.value, 0);
  });

  test('load con error → error con failure; no marca leídas', () async {
    stubFirst(Result.failure(tServerFailure));

    await controller.load();

    expect(controller.status, NotificationsStatus.error);
    expect(controller.failure, tServerFailure);
    verifyNever(repository.markRead(ids: anyNamed('ids')));
  });

  test('marcar leídas falla → warning; la campana conserva su valor', () async {
    await badge.refresh();
    stubFirst(Result.success(notificationPage([tNotification()])));
    when(repository.markRead(ids: anyNamed('ids')))
        .thenAnswer((_) async => Result.failure(tServerFailure));

    await controller.load();

    expect(controller.status, NotificationsStatus.loaded);
    expect(badge.value, 4);
    verify(logger.w('Failed to mark notifications read', context: anyNamed('context'))).called(1);
  });

  test('refresh sin nuevas no leídas no vuelve a marcar', () async {
    stubFirst(Result.success(notificationPage([tNotification()])));
    await controller.load();

    stubFirst(Result.success(notificationPage([tNotification(isRead: true)])));
    await controller.refresh();

    verify(repository.markRead(ids: ['n1'])).called(1);
    expect(controller.items.single.isRead, isTrue);
  });

  test('sin no leídas en pantalla no marca nada', () async {
    stubFirst(Result.success(notificationPage([tNotification(isRead: true)])));
    await controller.load();

    verifyNever(repository.markRead(ids: anyNamed('ids')));
  });

  test('refresh con nuevas no leídas marca solo esas', () async {
    stubFirst(Result.success(notificationPage([tNotification()])));
    await controller.load();

    stubFirst(Result.success(notificationPage([tNotification(id: 'new'), tNotification()])));
    await controller.refresh();

    verify(repository.markRead(ids: ['n1'])).called(1);
    verify(repository.markRead(ids: ['new'])).called(1);
  });

  test('loadMore marca las no leídas de la página nueva', () async {
    stubFirst(Result.success(notificationPage([tNotification()], hasMore: true, cursor: tCursor)));
    stubNext(Result.success(notificationPage([
      tNotification(id: 'n2'),
      tNotification(id: 'n3', isRead: true),
    ])));
    await controller.load();

    await controller.loadMore();

    verify(repository.markRead(ids: ['n1'])).called(1);
    verify(repository.markRead(ids: ['n2'])).called(1);
    expect(controller.isLoadingMore, isFalse);
  });

  test('refresh con error conserva la lista', () async {
    stubFirst(Result.success(notificationPage([tNotification()])));
    await controller.load();

    stubFirst(Result.failure(tServerFailure));
    await controller.refresh();

    expect(controller.status, NotificationsStatus.loaded);
    expect(controller.items, hasLength(1));
  });

  test('loadMore agrega la siguiente página con el cursor', () async {
    stubFirst(Result.success(notificationPage([tNotification()], hasMore: true, cursor: tCursor)));
    stubNext(Result.success(notificationPage([tNotification(id: 'n2')])));
    await controller.load();

    await controller.loadMore();

    expect(controller.items.map((n) => n.id), ['n1', 'n2']);
    expect(controller.hasMore, isFalse);
    expect(controller.isLoadingMore, isFalse);

    // Sin más páginas no vuelve a pedir
    await controller.loadMore();
    verify(repository.getNotifications(pageSize: 30, cursor: tCursor)).called(1);
  });

  test('loadMore ignora llamadas mientras carga', () async {
    stubFirst(Result.success(notificationPage([tNotification()], hasMore: true, cursor: tCursor)));
    await controller.load();
    final gate = Completer<void>();
    when(repository.getNotifications(pageSize: anyNamed('pageSize'), cursor: tCursor))
        .thenAnswer((_) async {
      await gate.future;
      return Result.success(notificationPage(const []));
    });

    final first = controller.loadMore();
    expect(controller.isLoadingMore, isTrue);
    await controller.loadMore();
    gate.complete();
    await first;

    verify(repository.getNotifications(pageSize: 30, cursor: tCursor)).called(1);
  });

  test('loadMore con error conserva la lista y avisa', () async {
    stubFirst(Result.success(notificationPage([tNotification()], hasMore: true, cursor: tCursor)));
    stubNext(Result.failure(tServerFailure));
    await controller.load();

    await controller.loadMore();

    expect(controller.items, hasLength(1));
    expect(controller.hasMore, isTrue);
    verify(logger.w('Failed to load more notifications', context: anyNamed('context'))).called(1);
  });

  test('loadMore antes de cargar no hace nada', () async {
    await controller.loadMore();

    verifyNever(repository.getNotifications(pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')));
  });

  test('no notifica después de dispose', () async {
    final gate = Completer<void>();
    when(repository.getNotifications(pageSize: anyNamed('pageSize'), cursor: null))
        .thenAnswer((_) async {
      await gate.future;
      return Result.success(notificationPage(const []));
    });
    final other = NotificationsController(
      GetNotifications(repository),
      MarkNotificationsRead(repository),
      badge,
      logger,
    );

    final pending = other.load();
    other.dispose();
    gate.complete();

    await expectLater(pending, completes);
  });
}
