import 'package:flutter/widgets.dart';

/// Notificaciones in-app (campana con contador y pantalla) sin que otros
/// features importen `notifications`.
///
/// La implementa el feature notifications (`@Singleton(as: NotificationsNavigator)`);
/// home la usa con `getIt<NotificationsNavigator>()`.
abstract class NotificationsNavigator {
  /// Campana con el contador de no leídas para un AppBar. Al tocarla abre las
  /// notificaciones. Refresca el contador al crearse, al volver la app a
  /// primer plano y al cerrar la pantalla de notificaciones.
  Widget buildBellButton();

  /// Pide refrescar el contador de no leídas (con throttle: ignora llamadas
  /// muy seguidas)
  void refreshUnreadCount();

  /// Abre la pantalla de notificaciones
  Future<void> openNotifications(BuildContext context);
}
