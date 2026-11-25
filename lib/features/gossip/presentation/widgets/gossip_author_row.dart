import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/navigation/social_navigator.dart';
import '../../../../core/social/gossip_author.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/user_avatar.dart';

/// Autor de un chisme publicado con perfil: foto + nombre (y @usuario).
/// Al tocarlo abre su perfil (vía [SocialNavigator]).
///
/// Solo se usa con un [GossipAuthor]: los chismes anónimos no tienen autor
/// y NO muestran esta fila (nada que tocar ni que revele al autor).
class GossipAuthorRow extends StatelessWidget {
  final GossipAuthor author;

  /// Una sola línea (nombre) y foto chica: tarjetas y grillas
  final bool compact;

  const GossipAuthorRow({
    super.key,
    required this.author,
    this.compact = false,
  });

  /// Alto mínimo del área táctil (accesibilidad)
  static const double minTouchTarget = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final handle = author.handle;
    final showHandle = !compact && handle != null && author.displayName != null;

    return Semantics(
      button: true,
      label: context.l10n.gossipAuthorSemanticLabel(author.displayLabel),
      excludeSemantics: true,
      child: InkWell(
        key: const Key('gossipAuthorRow'),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () =>
            getIt<SocialNavigator>().openUserProfile(context, author.userId),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: minTouchTarget),
          // En celdas muy angostas (grilla en pantallas chicas) solo el nombre
          child: LayoutBuilder(
            builder: (context, constraints) {
              final avatarRadius = compact ? 12.0 : 18.0;
              final showAvatar =
                  constraints.maxWidth >=
                  avatarRadius * 2 + AppSpacing.sm + AppSpacing.xxl;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showAvatar) ...[
                    UserAvatar(
                      avatarUrl: author.avatarUrl,
                      name: author.displayLabel,
                      radius: avatarRadius,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          author.displayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (compact
                                      ? theme.textTheme.labelMedium
                                      : theme.textTheme.titleSmall)
                                  ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (showHandle)
                          Text(
                            handle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
