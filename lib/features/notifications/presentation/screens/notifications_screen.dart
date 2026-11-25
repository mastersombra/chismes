import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/navigation/account_navigator.dart';
import '../../../../core/navigation/social_navigator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/app_notification.dart';
import '../controllers/notifications_controller.dart';
import '../widgets/notification_tile.dart';
import '../widgets/notifications_message.dart';

/// Notificaciones del usuario (más recientes primero), con scroll infinito y
/// pull-to-refresh. Al abrirla se marcan todas como leídas.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<NotificationsController>();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Acción al tocar la notificación, o null si no navega
  VoidCallback? _onTap(AppNotification notification) {
    final actor = notification.actor;
    switch (notification.type) {
      case NotificationType.newFollower:
      case NotificationType.followAccepted:
        if (actor == null) return null;
        return () => getIt<SocialNavigator>().openUserProfile(context, actor.id);
      case NotificationType.followRequest:
        return () => getIt<SocialNavigator>().openFollowRequests(context);
      case NotificationType.gossipRejected:
      case NotificationType.appealAccepted:
      case NotificationType.appealRejected:
        return () => getIt<AccountNavigator>().openAccountStatus(context);
      case NotificationType.gossipApproved:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notificationsTitle)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          switch (_controller.status) {
            case NotificationsStatus.initial:
            case NotificationsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case NotificationsStatus.error:
              return NotificationsMessage(
                icon: Icons.error_outline,
                title: ErrorMessages.forFailure(context, _controller.failure!),
                onRetry: _controller.load,
              );
            case NotificationsStatus.loaded:
              return RefreshIndicator(
                onRefresh: _controller.refresh,
                child: _buildList(context),
              );
          }
        },
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final items = _controller.items;
    if (items.isEmpty) {
      return NotificationsMessage(
        icon: Icons.notifications_none,
        title: context.l10n.notificationsEmptyTitle,
        message: context.l10n.notificationsEmptyMessage,
      );
    }

    final now = DateTime.now();
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 300) _controller.loadMore();
        return false;
      },
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length + (_controller.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final notification = items[index];
          return NotificationTile(
            notification: notification,
            now: now,
            onTap: _onTap(notification),
          );
        },
      ),
    );
  }
}
