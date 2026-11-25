import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/navigation/notifications_navigator.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/notifications/presentation/controllers/notifications_badge_controller.dart';
import 'package:chismes/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:chismes/features/notifications/presentation/widgets/notifications_bell_button.dart';
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

  setUpAll(provideNotificationsDummies);

  setUp(() {
    repository = MockNotificationsRepository();
    badge = registerNotificationsForWidgets(
      repository,
      socialNavigator: MockSocialNavigator(),
      accountNavigator: MockAccountNavigator(),
    );
    when(repository.getUnreadCount()).thenAnswer((_) async => Result.success(3));
    when(repository.getNotifications(pageSize: anyNamed('pageSize'), cursor: anyNamed('cursor')))
        .thenAnswer((_) async => Result.success(notificationPage(const [])));
    when(repository.markRead(ids: anyNamed('ids'))).thenAnswer((_) async => Result.success(0));
  });

  tearDown(unregisterNotificationsForWidgets);

  test('buildBellButton arma la campana', () {
    expect(getIt<NotificationsNavigator>().buildBellButton(), isA<NotificationsBellButton>());
  });

  test('refreshUnreadCount refresca el badge (con throttle)', () async {
    final navigator = getIt<NotificationsNavigator>();

    navigator.refreshUnreadCount();
    await Future<void>.delayed(Duration.zero);
    navigator.refreshUnreadCount();
    await Future<void>.delayed(Duration.zero);

    expect(badge.value, 3);
    verify(repository.getUnreadCount()).called(1);
  });

  testWidgets('openNotifications abre NotificationsScreen', (tester) async {
    await tester.pumpWidget(testableWidget(
      child: Builder(
        builder: (context) => TextButton(
          onPressed: () => getIt<NotificationsNavigator>().openNotifications(context),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsScreen), findsOneWidget);
  });
}
