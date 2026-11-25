import 'package:flutter/material.dart';
import '../../../gossip/domain/entities/gossip.dart';
import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../gossip/presentation/widgets/gossip_author_row.dart';

class GossipDetailScreen extends StatelessWidget {
  final Gossip gossip;

  /// Muestra el autor (solo chismes con perfil; los anónimos nunca)
  final bool showAuthor;

  const GossipDetailScreen({
    super.key,
    required this.gossip,
    this.showAuthor = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.gossipDetailTitle),
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Image.network(
              gossip.imageUrl ?? 'https://via.placeholder.com/150',
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.image,
                    size: 50,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.lg),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  if (showAuthor && gossip.author != null) ...[
                    GossipAuthorRow(author: gossip.author!),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Text(
                    gossip.subject,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  Text(
                    gossip.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}