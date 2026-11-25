import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/app_notification.dart';
import 'notification_texts.dart';

/// Fila de una notificación: foto del actor (sociales) o ícono (de la
/// cuenta), frase y tiempo relativo. Las que llegaron sin leer se resaltan.
class NotificationTile extends StatelessWidget {
  final AppNotification notification;

  /// Hora de referencia para el tiempo relativo
  final DateTime now;

  /// null → la fila no navega
  final VoidCallback? onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.now,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unread = !notification.isRead;

    return Material(
      color: unread
          ? colors.primaryContainer.withValues(alpha: 0.35)
          : Colors.transparent,
      child: ListTile(
        key: Key('notificationTile_${notification.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        leading: _leading(context),
        title: Text(
          NotificationTexts.sentence(context, notification),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: unread
              ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)
              : theme.textTheme.bodyLarge,
        ),
        subtitle: Text(
          NotificationTexts.relativeTime(context, notification.createdAt, now),
        ),
        trailing: unread
            ? Container(
                key: Key('unreadDot_${notification.id}'),
                width: AppSpacing.sm,
                height: AppSpacing.sm,
                decoration: BoxDecoration(
                  color: colors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  Widget _leading(BuildContext context) {
    if (notification.type.isSocial) {
      final actor = notification.actor;
      return UserAvatar(
        avatarUrl: actor?.avatarUrl,
        name: NotificationTexts.actorName(context, actor),
      );
    }
    final colors = Theme.of(context).colorScheme;
    final (icon, background, foreground) = switch (notification.type) {
      NotificationType.gossipApproved ||
      NotificationType.appealAccepted =>
        (Icons.check_circle_outline, colors.primaryContainer, colors.onPrimaryContainer),
      NotificationType.gossipRejected =>
        (Icons.block, colors.errorContainer, colors.onErrorContainer),
      _ => (Icons.gavel, colors.errorContainer, colors.onErrorContainer),
    };
    return CircleAvatar(
      key: Key('notificationIcon_${notification.id}'),
      radius: 20,
      backgroundColor: background,
      child: Icon(icon, color: foreground),
    );
  }
}
