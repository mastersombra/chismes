import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/navigation/notifications_navigator.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/notifications/presentation/controllers/notifications_badge_controller.dart';
import 'package:chismes/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import '../../notifications_di_helper.dart';
import '../../notifications_fixtures.dart';
import '../../notifications_test_mocks.mocks.dart';

void main() {
  late MockNotificationsRepository repository;
  late NotificationsBadgeController badge;
  late DateTime now;

  setUpAll(provideNotificationsDummies);

  setUp(() {
    repository = MockNotificationsRepository();
    badge = registerNotificationsForWidgets(
      repository,
      socialNavigator: MockSocialNavigator(),
      accountNavigator: MockAccountNavigator(),
    );
    now = DateTime(2026, 11, 24, 12);
    badge.now = () => now;
    when(repository.getNotifications(pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
        .thenAnswer((_) async => Result.success(notificationPage(const [])));
    when(repository.markRead(ids: anyNamed('ids'))).thenAnswer((_) async => Result.success(0));
  });

  tearDown(unregisterNotificationsForWidgets);

  void stubCount(int count) =>
      when(repository.getUnreadCount()).thenAnswer((_) async => Result.success(count));

  Future<void> pumpBell(WidgetTester tester) async {
    await tester.pumpWidget(testableWidget(
      child: Scaffold(
        appBar: AppBar(actions: [getIt<NotificationsNavigator>().buildBellButton()]),
      ),
      useScaffold: false,
    ));
    await tester.pumpAndSettle();
  }

  Badge badgeWidget(WidgetTester tester) =>
      tester.widget<Badge>(find.byKey(const Key('notificationsBadge')));

  testWidgets('0: sin número y tooltip "Notificaciones"', (tester) async {
    stubCount(0);

    await pumpBell(tester);

    verify(repository.getUnreadCount()).called(1);
    expect(badgeWidget(tester).isLabelVisible, isFalse);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byTooltip('Notificaciones'), findsOneWidget);
  });

  testWidgets('5: muestra el número y el tooltip con la cantidad', (tester) async {
    stubCount(5);

    await pumpBell(tester);

    expect(badgeWidget(tester).isLabelVisible, isTrue);
    expect(find.text('5'), findsOneWidget);
    expect(find.byIcon(Icons.notifications), findsOneWidget);
    expect(find.byTooltip('Notificaciones: 5 sin leer'), findsOneWidget);
  });

  testWidgets('100 (tope del servidor): muestra 99+', (tester) async {
    stubCount(100);

    await pumpBell(tester);

    expect(find.text('99+'), findsOneWidget);
    expect(find.byTooltip('Notificaciones: 99+ sin leer'), findsOneWidget);
  });

  testWidgets('tocar abre la pantalla; al volver refresca sin throttle', (tester) async {
    stubCount(3);
    await pumpBell(tester);

    await tester.tap(find.byKey(const Key('notificationsBellButton')));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationsScreen), findsOneWidget);

    stubCount(1);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('volver a primer plano refresca (con throttle)', (tester) async {
    stubCount(2);
    await pumpBell(tester);
    verify(repository.getUnreadCount()).called(1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    verifyNever(repository.getUnreadCount()); // < 10 s

    now = now.add(const Duration(seconds: 11));
    stubCount(6);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    verify(repository.getUnreadCount()).called(1);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('tras desmontarse deja de escuchar el ciclo de vida', (tester) async {
    stubCount(0);
    await pumpBell(tester);
    await tester.pumpWidget(const SizedBox());
    clearInteractions(repository);

    now = now.add(const Duration(minutes: 1));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    verifyNever(repository.getUnreadCount());
  });
}
