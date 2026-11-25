import 'dart:async';

import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/notifications/domain/entities/app_notification.dart';
import 'package:chismes/features/notifications/domain/entities/notification_page.dart';
import 'package:chismes/features/notifications/presentation/controllers/notifications_badge_controller.dart';
import 'package:chismes/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:chismes/features/notifications/presentation/widgets/notification_tile.dart';
import 'package:chismes/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import '../../notifications_di_helper.dart';
import '../../notifications_fixtures.dart';
import '../../notifications_test_mocks.mocks.dart';

void main() {
  late MockNotificationsRepository repository;
  late MockSocialNavigator social;
  late MockAccountNavigator account;
  late NotificationsBadgeController badge;

  setUpAll(provideNotificationsDummies);

  setUp(() {
    repository = MockNotificationsRepository();
    social = MockSocialNavigator();
    account = MockAccountNavigator();
    badge = registerNotificationsForWidgets(
      repository,
      socialNavigator: social,
      accountNavigator: account,
    );
    when(repository.markRead(ids: anyNamed('ids'))).thenAnswer((_) async => Result.success(2));
    when(repository.getUnreadCount()).thenAnswer((_) async => Result.success(2));
    when(social.openUserProfile(any, any)).thenAnswer((_) async {});
    when(social.openFollowRequests(any)).thenAnswer((_) async {});
    when(account.openAccountStatus(any)).thenAnswer((_) async {});
  });

  tearDown(unregisterNotificationsForWidgets);

  void stubFirst(Result<Failure, NotificationPage> result) {
    when(repository.getNotifications(pageSize: anyNamed('pageSize'), cursor: null))
        .thenAnswer((_) async => result);
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      testableWidget(child: const NotificationsScreen(), useScaffold: false),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('cargando: spinner y título', (tester) async {
    final gate = Completer<void>();
    when(repository.getNotifications(pageSize: anyNamed('pageSize'), cursor: null))
        .thenAnswer((_) async {
      await gate.future;
      return Result.success(notificationPage(const []));
    });

    await tester.pumpWidget(
      testableWidget(child: const NotificationsScreen(), useScaffold: false),
    );
    await tester.pump();

    expect(find.text('Notificaciones'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('vacío: mensaje', (tester) async {
    stubFirst(Result.success(notificationPage(const [])));

    await pumpScreen(tester);

    expect(find.text('No tienes notificaciones'), findsOneWidget);
    expect(
      find.text('Aquí verás tus nuevos seguidores y las novedades de tus chismes.'),
      findsOneWidget,
    );
  });

  testWidgets('error: mensaje y Reintentar vuelve a cargar', (tester) async {
    stubFirst(Result.failure(tServerFailure));
    await pumpScreen(tester);

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
    verifyNever(repository.markRead(ids: anyNamed('ids')));

    stubFirst(Result.success(notificationPage([tNotification()])));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('@beto empezó a seguirte'), findsOneWidget);
    verify(repository.markRead(ids: ['n1'])).called(1);
  });

  testWidgets('lista: frases, resalta no leídas, avatar o ícono; marca leídas una vez', (tester) async {
    await badge.refresh();
    expect(badge.value, 2);
    stubFirst(Result.success(notificationPage([
      tNotification(id: 'a', createdAt: DateTime.now().subtract(const Duration(minutes: 5))),
      tNotification(id: 'b', type: NotificationType.gossipApproved, isRead: true),
      tNotification(id: 'c', type: NotificationType.gossipRejected, reason: 'hate'),
      tNotification(id: 'd', type: NotificationType.appealRejected, isRead: true),
    ])));

    await pumpScreen(tester);

    expect(find.text('@beto empezó a seguirte'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.text('Tu chisme "La fiesta de Ana" fue aprobado'), findsOneWidget);
    expect(find.text('Tu chisme "La fiesta de Ana" fue rechazado: Odio o discriminación'),
        findsOneWidget);
    expect(find.text('Tu apelación de "La fiesta de Ana" fue rechazada'), findsOneWidget);

    expect(find.byKey(const Key('unreadDot_a')), findsOneWidget);
    expect(find.byKey(const Key('unreadDot_b')), findsNothing);
    expect(find.byKey(const Key('unreadDot_c')), findsOneWidget);
    expect(find.byType(UserAvatar), findsOneWidget);
    expect(find.byKey(const Key('notificationIcon_b')), findsOneWidget);
    expect(find.byKey(const Key('notificationIcon_c')), findsOneWidget);
    expect(find.byKey(const Key('notificationIcon_d')), findsOneWidget);

    verify(repository.markRead(ids: ['a', 'c'])).called(1);
    expect(badge.value, 0);
    // Siguen resaltadas en esta vista
    expect(find.byKey(const Key('unreadDot_a')), findsOneWidget);
  });

  testWidgets('pull-to-refresh vuelve a pedir la primera página', (tester) async {
    stubFirst(Result.success(notificationPage([tNotification()])));
    await pumpScreen(tester);

    stubFirst(Result.success(notificationPage([tNotification(isRead: true)])));
    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    verify(repository.getNotifications(pageSize: 30, cursor: null)).called(2);
    expect(find.byKey(const Key('unreadDot_n1')), findsNothing);
    verify(repository.markRead(ids: ['n1'])).called(1);
  });

  testWidgets('scroll infinito: pide la siguiente página con el cursor', (tester) async {
    final first = List.generate(
      30,
      (i) => tNotification(id: 'p1_$i', isRead: true),
    );
    stubFirst(Result.success(notificationPage(first, hasMore: true, cursor: tCursor)));
    final gate = Completer<void>();
    when(repository.getNotifications(pageSize: anyNamed('pageSize'), cursor: tCursor))
        .thenAnswer((_) async {
      await gate.future;
      return Result.success(notificationPage([
        tNotification(id: 'p2', type: NotificationType.appealAccepted, isRead: true),
      ]));
    });

    await pumpScreen(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    verify(repository.getNotifications(pageSize: 30, cursor: tCursor)).called(1);
    expect(
      find.text('Tu apelación de "La fiesta de Ana" fue aceptada: el chisme volvió a publicarse'),
      findsOneWidget,
    );
  });

  group('al tocar', () {
    Future<void> tapOnly(WidgetTester tester, AppNotification notification) async {
      stubFirst(Result.success(notificationPage([notification])));
      await pumpScreen(tester);
      await tester.tap(find.byKey(Key('notificationTile_${notification.id}')));
      await tester.pumpAndSettle();
    }

    testWidgets('new_follower abre el perfil del actor', (tester) async {
      await tapOnly(tester, tNotification());

      verify(social.openUserProfile(any, kActorId)).called(1);
    });

    testWidgets('follow_accepted abre el perfil del actor', (tester) async {
      await tapOnly(tester, tNotification(type: NotificationType.followAccepted));

      verify(social.openUserProfile(any, kActorId)).called(1);
    });

    testWidgets('follow_request abre las solicitudes', (tester) async {
      await tapOnly(tester, tNotification(type: NotificationType.followRequest));

      verify(social.openFollowRequests(any)).called(1);
      verifyNever(social.openUserProfile(any, any));
    });

    for (final type in [
      NotificationType.gossipRejected,
      NotificationType.appealAccepted,
      NotificationType.appealRejected,
    ]) {
      testWidgets('${type.value} abre Estado de la cuenta', (tester) async {
        await tapOnly(tester, tNotification(type: type));

        verify(account.openAccountStatus(any)).called(1);
      });
    }

    testWidgets('gossip_approved no navega', (tester) async {
      await tapOnly(tester, tNotification(type: NotificationType.gossipApproved));

      final tile = tester.widget<ListTile>(find.byKey(const Key('notificationTile_n1')));
      expect(tile.onTap, isNull);
      verifyZeroInteractions(account);
      verifyZeroInteractions(social);
    });

    testWidgets('social sin actor no navega', (tester) async {
      stubFirst(Result.success(notificationPage([tNotification(actor: null)])));
      await pumpScreen(tester);

      final tile = tester.widget<ListTile>(find.byKey(const Key('notificationTile_n1')));
      expect(tile.onTap, isNull);
      expect(find.text('Usuario empezó a seguirte'), findsOneWidget);
      expect(find.byType(NotificationTile), findsOneWidget);
    });
  });
}
