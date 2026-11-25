import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../controllers/notifications_badge_controller.dart';
import '../screens/notifications_screen.dart';

/// Campana del AppBar con el contador de no leídas (oculto en 0, "99+" desde
/// 100). Refresca el contador al crearse, al volver la app a primer plano y
/// al cerrar la pantalla de notificaciones.
class NotificationsBellButton extends StatefulWidget {
  const NotificationsBellButton({super.key});

  @override
  State<NotificationsBellButton> createState() => _NotificationsBellButtonState();
}

class _NotificationsBellButtonState extends State<NotificationsBellButton>
    with WidgetsBindingObserver {
  late final NotificationsBadgeController _badge;

  @override
  void initState() {
    super.initState();
    _badge = getIt<NotificationsBadgeController>();
    WidgetsBinding.instance.addObserver(this);
    _badge.refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _badge.refresh();
  }

  Future<void> _open() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    if (!mounted) return;
    _badge.refresh(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _badge,
      builder: (context, count, _) {
        final label = NotificationsBadgeController.label(count);
        return IconButton(
          key: const Key('notificationsBellButton'),
          tooltip: label.isEmpty
              ? context.l10n.notificationsTitle
              : context.l10n.notificationsBellUnreadLabel(label),
          onPressed: _open,
          icon: ExcludeSemantics(
            child: Badge(
              key: const Key('notificationsBadge'),
              isLabelVisible: label.isNotEmpty,
              label: Text(label),
              child: Icon(
                label.isEmpty ? Icons.notifications_outlined : Icons.notifications,
              ),
            ),
          ),
        );
      },
    );
  }
}
