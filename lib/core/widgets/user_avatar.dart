import 'package:flutter/material.dart';

/// Foto de perfil circular; sin foto (o si falla la carga) muestra la
/// inicial del nombre. La usan el autor de los chismes y las listas sociales.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;

  /// Nombre para la inicial cuando no hay foto
  final String name;
  final double radius;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty;
    final initial = _initial(name);

    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      foregroundImage: hasAvatar ? NetworkImage(avatarUrl!) : null,
      // Si la foto no carga, queda la inicial de fondo
      onForegroundImageError: hasAvatar ? (_, _) {} : null,
      child: Text(
        initial,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }

  static String _initial(String name) {
    final clean = name.replaceFirst(RegExp(r'^@'), '').trim();
    return clean.isEmpty ? '?' : clean.characters.first.toUpperCase();
  }
}
