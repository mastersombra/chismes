import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/theme/app_spacing.dart';
import '../controllers/follow_requests_controller.dart';
import '../widgets/social_message.dart';
import '../widgets/user_list_tile.dart';
import 'user_profile_screen.dart';

/// Solicitudes para seguir mi cuenta privada: Aceptar / Rechazar
class FollowRequestsScreen extends StatefulWidget {
  const FollowRequestsScreen({super.key});

  @override
  State<FollowRequestsScreen> createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  late final FollowRequestsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<FollowRequestsController>();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showFailure(Failure? failure) {
    if (failure == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ErrorMessages.forFailure(context, failure)),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.socialFollowRequestsTitle)),
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
    final requests = _controller.requests;
    if (requests.isEmpty) {
      return ScrollableSocialMessage(
        child: SocialMessage(
          icon: Icons.person_add_disabled_outlined,
          title: context.l10n.socialNoFollowRequests,
        ),
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final user = requests[index].user;
        final busy = _controller.isProcessing(user.id);
        return UserListTile(
          user: user,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => UserProfileScreen(userId: user.id)),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                key: Key('rejectRequest_${user.id}'),
                onPressed: busy
                    ? null
                    : () async => _showFailure(await _controller.reject(user.id)),
                child: Text(context.l10n.socialReject),
              ),
              const SizedBox(width: AppSpacing.xs),
              FilledButton(
                key: Key('acceptRequest_${user.id}'),
                onPressed: busy
                    ? null
                    : () async => _showFailure(await _controller.accept(user.id)),
                child: Text(context.l10n.socialAccept),
              ),
            ],
          ),
        );
      },
    );
  }
}
