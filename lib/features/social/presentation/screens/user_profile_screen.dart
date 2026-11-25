import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/navigation/social_navigator.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../gossip/presentation/widgets/gossip_card.dart';
import '../../domain/entities/user_profile.dart';
import '../controllers/user_profile_controller.dart';
import '../widgets/social_message.dart';
import 'follow_list_screen.dart';

/// Perfil de un usuario: foto, nombre, bio, contadores, botón de seguir y
/// sus chismes con perfil. Menú con Bloquear / Desbloquear.
///
/// En el perfil propio (`isMe`) no hay botón de seguir ni menú.
class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final UserProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<UserProfileController>();
    _controller.load(widget.userId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _nameOf(UserProfile profile) =>
      profile.name.isEmpty ? context.l10n.socialUnknownUser : profile.name;

  void _showSnack(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  void _showFailure(Failure? failure) {
    if (failure != null) {
      _showSnack(ErrorMessages.forFailure(context, failure), isError: true);
    }
  }

  Future<void> _confirmBlock(UserProfile profile) async {
    final name = _nameOf(profile);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.socialBlockDialogTitle(name)),
        content: Text(context.l10n.socialBlockDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('confirmBlockButton'),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.socialBlock),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final failure = await _controller.block();
    if (!mounted) return;
    if (failure == null) {
      _showSnack(context.l10n.socialBlockedSnack(name));
    } else {
      _showFailure(failure);
    }
  }

  Future<void> _unblock(UserProfile profile) async {
    final name = _nameOf(profile);
    final failure = await _controller.unblock();
    if (!mounted) return;
    if (failure == null) {
      _showSnack(context.l10n.socialUnblockedSnack(name));
    } else {
      _showFailure(failure);
    }
  }

  Future<void> _openList(FollowListKind kind) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FollowListScreen(userId: widget.userId, initialKind: kind),
      ),
    );
    // Pudo quitar seguidores o seguir/dejar de seguir desde la lista
    if (mounted) await _controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final profile = _controller.profile;
        return Scaffold(
          appBar: AppBar(
            title: Text(profile?.handle ?? context.l10n.socialProfileTitle),
            actions: [
              if (profile != null && profile.canInteract) _buildMenu(profile),
            ],
          ),
          body: _buildBody(context),
        );
      },
    );
  }

  Widget _buildMenu(UserProfile profile) {
    return PopupMenuButton<String>(
      key: const Key('userProfileMenu'),
      tooltip: context.l10n.socialMoreOptions,
      enabled: !_controller.isActionInProgress,
      onSelected: (value) {
        if (value == 'block') _confirmBlock(profile);
        if (value == 'unblock') _unblock(profile);
      },
      itemBuilder: (context) => [
        if (profile.hasBlocked)
          PopupMenuItem(
            value: 'unblock',
            child: Text(context.l10n.socialUnblock),
          )
        else
          PopupMenuItem(
            value: 'block',
            child: Text(
              context.l10n.socialBlock,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_controller.status) {
      case UserProfileStatus.initial:
      case UserProfileStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case UserProfileStatus.notAvailable:
        return Center(
          child: SocialMessage(
            icon: Icons.person_off_outlined,
            title: context.l10n.socialUserNotAvailableTitle,
            message: context.l10n.socialUserNotAvailableMessage,
          ),
        );
      case UserProfileStatus.error:
        return Center(
          child: SocialMessage(
            icon: Icons.error_outline,
            title: _controller.failure != null
                ? ErrorMessages.forFailure(context, _controller.failure!)
                : context.l10n.socialLoadError,
            onRetry: () => _controller.load(widget.userId),
          ),
        );
      case UserProfileStatus.loaded:
        return _buildProfile(context, _controller.profile!);
    }
  }

  Widget _buildProfile(BuildContext context, UserProfile profile) {
    return RefreshIndicator(
      onRefresh: _controller.refresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 400) {
            _controller.loadMoreGossips();
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, profile)),
            ..._buildContent(context, profile),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserProfile profile) {
    final theme = Theme.of(context);
    final name = _nameOf(profile);
    final showHandle = profile.displayName != null && profile.handle != null;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          UserAvatar(avatarUrl: profile.avatarUrl, name: name, radius: 44),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (showHandle) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              profile.handle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (profile.isFollowedBy && !profile.isMe && !profile.hasBlocked) ...[
            const SizedBox(height: AppSpacing.sm),
            Chip(
              key: const Key('followsYouChip'),
              label: Text(context.l10n.socialFollowsYou),
              visualDensity: VisualDensity.compact,
            ),
          ],
          if (profile.hasBio && !profile.hasBlocked) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              profile.bio!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (!profile.hasBlocked) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildCounts(context, profile),
          ],
          if (profile.canInteract) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(context, profile),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCounts(BuildContext context, UserProfile profile) {
    final canOpenLists = profile.canViewContent;
    return Row(
      children: [
        Expanded(
          child: _CountItem(
            key: const Key('gossipsCount'),
            value: profile.gossipsCount,
            label: context.l10n.profileStatsGossips,
          ),
        ),
        Expanded(
          child: _CountItem(
            key: const Key('followersCount'),
            value: profile.followersCount,
            label: context.l10n.profileStatsFollowers,
            onTap: canOpenLists ? () => _openList(FollowListKind.followers) : null,
          ),
        ),
        Expanded(
          child: _CountItem(
            key: const Key('followingCount'),
            value: profile.followingCount,
            label: context.l10n.profileStatsFollowing,
            onTap: canOpenLists ? () => _openList(FollowListKind.following) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, UserProfile profile) {
    final busy = _controller.isActionInProgress;
    const minSize = Size.fromHeight(48);

    if (profile.hasBlocked) {
      return OutlinedButton(
        key: const Key('unblockButton'),
        style: OutlinedButton.styleFrom(minimumSize: minSize),
        onPressed: busy ? null : () => _unblock(profile),
        child: Text(context.l10n.socialUnblock),
      );
    }

    switch (profile.followStatus) {
      case FollowStatus.following:
        return OutlinedButton(
          key: const Key('followingButton'),
          style: OutlinedButton.styleFrom(minimumSize: minSize),
          onPressed: busy ? null : () async => _showFailure(await _controller.unfollow()),
          child: Text(context.l10n.socialFollowing),
        );
      case FollowStatus.requested:
        return OutlinedButton(
          key: const Key('requestedButton'),
          style: OutlinedButton.styleFrom(minimumSize: minSize),
          onPressed: busy ? null : () async => _showFailure(await _controller.unfollow()),
          child: Text(context.l10n.socialRequested),
        );
      case FollowStatus.none:
        return FilledButton(
          key: const Key('followButton'),
          style: FilledButton.styleFrom(minimumSize: minSize),
          onPressed: busy ? null : () async => _showFailure(await _controller.follow()),
          child: Text(context.l10n.socialFollow),
        );
    }
  }

  List<Widget> _buildContent(BuildContext context, UserProfile profile) {
    Widget message(SocialMessage child) =>
        SliverFillRemaining(hasScrollBody: false, child: Center(child: child));

    if (profile.hasBlocked) {
      return [
        message(SocialMessage(
          icon: Icons.block,
          title: context.l10n.socialBlockedProfileTitle,
          message: context.l10n.socialBlockedProfileMessage,
        )),
      ];
    }
    if (!profile.canViewContent) {
      return [
        message(SocialMessage(
          key: const Key('privateAccountMessage'),
          icon: Icons.lock_outline,
          title: context.l10n.socialPrivateAccountTitle,
          message: context.l10n.socialPrivateAccountMessage,
        )),
      ];
    }

    final gossips = _controller.gossips;
    if (gossips.isEmpty) {
      if (_controller.isLoadingGossips) {
        return [
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        ];
      }
      if (_controller.gossipsFailed) {
        return [
          message(SocialMessage(
            icon: Icons.error_outline,
            title: context.l10n.socialGossipsError,
            onRetry: _controller.retryGossips,
          )),
        ];
      }
      return [
        message(SocialMessage(
          icon: Icons.chat_bubble_outline,
          title: context.l10n.socialNoGossips,
        )),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        sliver: SliverList.separated(
          itemCount: gossips.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          // En su propio perfil el autor ya se sabe: sin fila de autor
          itemBuilder: (context, index) =>
              GossipCard(gossip: gossips[index], showAuthor: false),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _controller.isLoadingMore
              ? const Center(child: CircularProgressIndicator())
              : const SizedBox.shrink(),
        ),
      ),
    ];
  }
}

/// Contador (chismes / seguidores / seguidos); tocable si [onTap]
class _CountItem extends StatelessWidget {
  final int? value;
  final String label;
  final VoidCallback? onTap;

  const _CountItem({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value == null ? '–' : _format(value!);
    return Semantics(
      button: onTap != null,
      label: '$text $label',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _format(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)}M';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(1)}K';
    return number.toString();
  }
}
