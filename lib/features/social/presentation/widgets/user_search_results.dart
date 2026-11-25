import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/error_messages.dart';
import '../controllers/user_search_controller.dart';
import '../screens/user_profile_screen.dart';
import 'social_message.dart';
import 'user_list_tile.dart';

/// Resultados de búsqueda de usuarios para [query] (pestaña Usuarios de
/// Buscar). Busca con debounce cada vez que cambia [query].
class UserSearchResults extends StatefulWidget {
  final String query;

  const UserSearchResults({super.key, required this.query});

  @override
  State<UserSearchResults> createState() => _UserSearchResultsState();
}

class _UserSearchResultsState extends State<UserSearchResults> {
  late final UserSearchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<UserSearchController>();
    _controller.search(widget.query);
  }

  @override
  void didUpdateWidget(covariant UserSearchResults oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) _controller.search(widget.query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        switch (_controller.status) {
          case UserSearchStatus.idle:
            return ScrollableSocialMessage(
              child: SocialMessage(
                icon: Icons.person_search_outlined,
                title: context.l10n.socialSearchUsersPrompt,
              ),
            );
          case UserSearchStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case UserSearchStatus.error:
            return ScrollableSocialMessage(
              child: SocialMessage(
                icon: Icons.error_outline,
                title: ErrorMessages.forFailure(context, _controller.failure!),
                onRetry: () => _controller.searchNow(widget.query),
              ),
            );
          case UserSearchStatus.loaded:
            if (_controller.users.isEmpty) {
              return ScrollableSocialMessage(
                child: SocialMessage(
                  icon: Icons.search_off,
                  title: context.l10n.socialSearchUsersNoResults,
                ),
              );
            }
            return ListView.builder(
              itemCount: _controller.users.length,
              itemBuilder: (context, index) {
                final user = _controller.users[index];
                return UserListTile(
                  user: user,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserProfileScreen(userId: user.id),
                    ),
                  ),
                );
              },
            );
        }
      },
    );
  }
}
