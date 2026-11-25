import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/error_messages.dart';
import '../controllers/blocked_users_controller.dart';
import '../controllers/follow_requests_controller.dart' show SocialListStatus;
import '../widgets/social_message.dart';
import '../widgets/user_list_tile.dart';

/// Usuarios que bloqueé: Desbloquear.
///
/// Las filas no abren el perfil: bloqueado solo se ve su nombre y foto, y
/// desbloquear se hace aquí mismo.
class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  late final BlockedUsersController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<BlockedUsersController>();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unblock(String userId, String name) async {
    final failure = await _controller.unblock(userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failure == null
            ? context.l10n.socialUnblockedSnack(name)
            : ErrorMessages.forFailure(context, failure)),
        backgroundColor: failure == null ? null : Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.socialBlockedUsersTitle)),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          switch (_controller.status) {
            case SocialListStatus.initial:
            case SocialListStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case SocialListStatus.error:
              return ScrollableSocialMessage(
                child: SocialMessage(
                  icon: Icons.error_outline,
                  title: ErrorMessages.forFailure(context, _controller.failure!),
                  onRetry: _controller.load,
                ),
              );
            case SocialListStatus.loaded:
              return RefreshIndicator(
                onRefresh: _controller.load,
                child: _buildList(context),
              );
          }
        },
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final users = _controller.users;
    if (users.isEmpty) {
      return ScrollableSocialMessage(
        child: SocialMessage(
          icon: Icons.block,
          title: context.l10n.socialNoBlockedUsers,
        ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final name = user.name.isEmpty ? context.l10n.socialUnknownUser : user.name;
        return UserListTile(
          user: user,
          trailing: OutlinedButton(
            key: Key('unblock_${user.id}'),
            onPressed: _controller.isProcessing(user.id)
                ? null
                : () => _unblock(user.id, name),
            child: Text(context.l10n.socialUnblock),
          ),
        );
      },
    );
  }
}
