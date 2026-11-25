import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/navigation/social_navigator.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/social_user.dart';
import '../controllers/follow_list_controller.dart';
import '../widgets/social_message.dart';
import '../widgets/user_list_tile.dart';
import 'user_profile_screen.dart';

/// Seguidores y seguidos de un usuario (dos pestañas). En MIS seguidores
/// cada fila tiene "Quitar".
class FollowListScreen extends StatelessWidget {
  final String userId;
  final FollowListKind initialKind;

  const FollowListScreen({
    super.key,
    required this.userId,
    this.initialKind = FollowListKind.followers,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: FollowListKind.values.length,
      initialIndex: FollowListKind.values.indexOf(initialKind),
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.profileStatsFollowers),
              Tab(text: context.l10n.profileStatsFollowing),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            FollowListView(userId: userId, kind: FollowListKind.followers),
            FollowListView(userId: userId, kind: FollowListKind.following),
          ],
        ),
      ),
    );
  }
}

/// Lista paginada de [kind] de [userId]
class FollowListView extends StatefulWidget {
  final String userId;
  final FollowListKind kind;

  const FollowListView({super.key, required this.userId, required this.kind});

  @override
  State<FollowListView> createState() => _FollowListViewState();
}

class _FollowListViewState extends State<FollowListView>
    with AutomaticKeepAliveClientMixin {
  late final FollowListController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller = getIt<FollowListController>();
    _controller.load(widget.userId, widget.kind);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmRemove(SocialUser user) async {
    final name = user.name.isEmpty ? context.l10n.socialUnknownUser : user.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.socialRemoveFollowerDialogTitle(name)),
        content: Text(context.l10n.socialRemoveFollowerDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('confirmRemoveFollowerButton'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.socialRemoveFollower),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final failure = await _controller.removeFollower(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure == null
            ? context.l10n.socialFollowerRemoved(name)
            : ErrorMessages.forFailure(context, failure)),
        backgroundColor: failure == null ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _openProfile(SocialUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        switch (_controller.status) {
          case FollowListStatus.initial:
          case FollowListStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case FollowListStatus.notAvailable:
            return ScrollableSocialMessage(
              child: SocialMessage(
                icon: Icons.lock_outline,
                title: context.l10n.socialPrivateAccountTitle,
                message: context.l10n.socialPrivateAccountMessage,
              ),
            );
          case FollowListStatus.error:
            return ScrollableSocialMessage(
              child: SocialMessage(
                icon: Icons.error_outline,
                title: ErrorMessages.forFailure(context, _controller.failure!),
                onRetry: () => _controller.load(widget.userId, widget.kind),
              ),
            );
          case FollowListStatus.loaded:
            return RefreshIndicator(
              onRefresh: _controller.refresh,
              child: _buildList(context),
            );
        }
      },
    );
  }

  Widget _buildList(BuildContext context) {
    final users = _controller.users;
    if (users.isEmpty) {
      return ScrollableSocialMessage(
        child: SocialMessage(
          icon: Icons.people_outline,
          title: widget.kind == FollowListKind.followers
              ? context.l10n.socialEmptyFollowers
              : context.l10n.socialEmptyFollowing,
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 300) _controller.loadMore();
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: users.length + (_controller.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= users.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final user = users[index];
          return UserListTile(
            user: user,
            onTap: () => _openProfile(user),
            trailing: _controller.canRemoveFollowers
                ? OutlinedButton(
                    key: Key('removeFollower_${user.id}'),
                    onPressed: _controller.isRemoving(user.id)
                        ? null
                        : () => _confirmRemove(user),
                    child: Text(context.l10n.socialRemoveFollower),
                  )
                : null,
          );
        },
      ),
    );
  }
}
