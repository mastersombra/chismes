import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/navigation/notifications_navigator.dart';
import '../controllers/notifications_badge_controller.dart';
import '../screens/notifications_screen.dart';
import '../widgets/notifications_bell_button.dart';

/// [NotificationsNavigator] del feature notifications
@Singleton(as: NotificationsNavigator)
class NotificationsNavigatorImpl implements NotificationsNavigator {
  @override
  Widget buildBellButton() => const NotificationsBellButton();

  @override
  void refreshUnreadCount() => getIt<NotificationsBadgeController>().refresh();

  @override
  Future<void> openNotifications(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }
}
