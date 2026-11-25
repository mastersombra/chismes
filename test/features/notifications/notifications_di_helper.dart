import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/navigation/account_navigator.dart';
import 'package:chismes/core/navigation/notifications_navigator.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/features/notifications/domain/usecases/get_notifications.dart';
import 'package:chismes/features/notifications/domain/usecases/get_unread_notifications_count.dart';
import 'package:chismes/features/notifications/domain/usecases/mark_notifications_read.dart';
import 'package:chismes/features/notifications/presentation/controllers/notifications_badge_controller.dart';
import 'package:chismes/features/notifications/presentation/controllers/notifications_controller.dart';
import 'package:chismes/features/notifications/presentation/navigation/notifications_navigator_impl.dart';
import 'package:flutter/widgets.dart';
import 'package:mockito/mockito.dart';

import 'notifications_test_mocks.mocks.dart';

/// Key del widget que devuelve el [NotificationsNavigator] stub
const kBellStubKey = Key('notificationsBellStub');

/// Registra un [NotificationsNavigator] mockeado (campana = caja vacía) para
/// los tests de otras pantallas (home) que muestran la campana.
MockNotificationsNavigator registerNotificationsNavigatorStub() {
  _unregister<NotificationsNavigator>();
  final navigator = MockNotificationsNavigator();
  when(navigator.buildBellButton()).thenReturn(const SizedBox(key: kBellStubKey));
  getIt.registerSingleton<NotificationsNavigator>(navigator);
  return navigator;
}

void unregisterNotificationsNavigatorStub() => _unregister<NotificationsNavigator>();

/// Dependencias reales del feature (controllers, navigator) sobre un
/// [repository] mockeado, con [SocialNavigator] y [AccountNavigator]
/// mockeados. Devuelve el badge (singleton) para verificarlo.
NotificationsBadgeController registerNotificationsForWidgets(
  MockNotificationsRepository repository, {
  required MockSocialNavigator socialNavigator,
  required MockAccountNavigator accountNavigator,
  Stream<Never>? userStream,
}) {
  unregisterNotificationsForWidgets();
  final logger = MockAppLogger();
  final auth = MockAuthService();
  when(auth.userStream).thenAnswer((_) => userStream ?? const Stream.empty());

  final badge = NotificationsBadgeController(
    GetUnreadNotificationsCount(repository),
    auth,
    logger,
  );
  getIt.registerSingleton<NotificationsBadgeController>(badge);
  getIt.registerFactory<NotificationsController>(() => NotificationsController(
        GetNotifications(repository),
        MarkNotificationsRead(repository),
        badge,
        logger,
      ));
  getIt.registerSingleton<NotificationsNavigator>(NotificationsNavigatorImpl());
  getIt.registerSingleton<SocialNavigator>(socialNavigator);
  getIt.registerSingleton<AccountNavigator>(accountNavigator);
  return badge;
}

void unregisterNotificationsForWidgets() {
  if (getIt.isRegistered<NotificationsBadgeController>()) {
    getIt<NotificationsBadgeController>().dispose();
  }
  _unregister<NotificationsBadgeController>();
  _unregister<NotificationsController>();
  _unregister<NotificationsNavigator>();
  _unregister<SocialNavigator>();
  _unregister<AccountNavigator>();
}

void _unregister<T extends Object>() {
  if (getIt.isRegistered<T>()) getIt.unregister<T>();
}
