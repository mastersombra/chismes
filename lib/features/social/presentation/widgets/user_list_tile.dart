import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/social_user.dart';

/// Fila de usuario para las listas sociales: foto, nombre y @usuario.
/// [trailing] para la acción (Quitar, Aceptar, Desbloquear...).
class UserListTile extends StatelessWidget {
  final SocialUser user;
  final VoidCallback? onTap;
  final Widget? trailing;

  const UserListTile({
    super.key,
    required this.user,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final name = user.name.isEmpty ? context.l10n.socialUnknownUser : user.name;
    final handle = user.displayName != null ? user.handle : null;

    return ListTile(
      key: Key('userTile_${user.id}'),
      minTileHeight: 56,
      leading: UserAvatar(avatarUrl: user.avatarUrl, name: name),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: handle != null
          ? Text(handle, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
