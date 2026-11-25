import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../screens/gossip_detail_screen.dart';
import '../../domain/entities/gossip.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/usecases/report_gossip.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/error/failure.dart';
import 'gossip_author_row.dart';
import 'report_gossip_dialog.dart';

class GossipCard extends StatelessWidget {
  final Gossip gossip;

  /// Muestra el autor (solo chismes con perfil). Se apaga en el perfil del
  /// propio autor: ya se sabe de quién es y tocarlo abriría el mismo perfil.
  final bool showAuthor;

  const GossipCard({
    super.key,
    required this.gossip,
    this.showAuthor = true,
  });

  /// Comparte el chisme usando deep link
  Future<void> _shareGossip(BuildContext context, Gossip gossip) async {
    // Generar deep link
    final deepLink = DeepLinkService.generateGossipLink(gossip.id);

    // Texto para compartir
    final shareText =
        '''
🔥 Mira este chisme:

"${gossip.subject}"

${gossip.content.length > 100 ? '${gossip.content.substring(0, 100)}...' : gossip.content}

$deepLink

📱 Descarga Chismes para ver más
''';

    try {
      await SharePlus.instance.share(ShareParams(text: shareText));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.gossipCardShareError),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Muestra el diálogo de reporte y procesa el resultado
  Future<void> _reportGossip(BuildContext context, Gossip gossip) async {
    // Mostrar diálogo
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ReportGossipDialog(),
    );

    if (result == null || !context.mounted) return;

    // Obtener UseCase
    final reportGossip = getIt<ReportGossip>();

    // Mostrar loading
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    // Ejecutar reporte
    final reportResult = await reportGossip(
      gossipId: gossip.id,
      reason: result['reason'] as ReportReason,
      details: result['details'] as String?,
    );

    // Cerrar loading
    if (context.mounted) {
      Navigator.pop(context);
    }

    // Mostrar resultado
    if (context.mounted) {
      reportResult.when(
        onFailure: (failure) {
          // Obtener mensaje según tipo de Failure
          final message = switch (failure) {
            AccountRestrictedFailure() => ErrorMessages.forFailure(context, failure),
            ServerFailure(:final message) =>
              message ?? context.l10n.gossipCardReportError,
            RateLimitFailure(:final message) =>
              message ?? context.l10n.gossipCardRateLimitError,
            _ => failure.technicalMessage ?? context.l10n.gossipCardReportError,
          };

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        onSuccess: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.gossipCardReportSuccess),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Accesibilidad: Semantics para toda la card
    return Semantics(
      label: context.l10n.gossipCardSemanticLabel(
        gossip.subject,
        gossip.content,
      ),
      hint: context.l10n.gossipCardSemanticHint,
      button: true,
      excludeSemantics: true, // No leer hijos (evitar duplicación)
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GossipDetailScreen(
                gossip: gossip,
                showAuthor: showAuthor,
              ),
            ),
          );
        },

        child: Card(
          elevation: 6,
          shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.15),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),

          // El alto disponible depende del padre:
          // - Lista (alto sin límite, Home): imagen cuadrada con AspectRatio.
          // - Celda de grilla (alto fijo, Search): la imagen ocupa el espacio que
          //   sobra (Expanded) para que el texto y los botones siempre quepan.
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hasFixedHeight = constraints.hasBoundedHeight;
              final image = _buildImage(context);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize:
                    MainAxisSize.min, // ✅ Evita conflicto con unbounded height
                children: [
                  if (hasFixedHeight)
                    Expanded(child: image)
                  else
                    AspectRatio(
                      aspectRatio: 1.0, // Imagen cuadrada
                      child: image,
                    ),

                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          gossip.subject,
                          // En grilla el alto es fijo: una línea para no desbordar
                          maxLines: hasFixedHeight ? 1 : null,
                          overflow: hasFixedHeight
                              ? TextOverflow.ellipsis
                              : null,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        Text(
                          gossip.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        // Autor (solo con perfil) + botones de acción
                        // (compartir y reportar). El autor va en la misma
                        // fila para no sumar alto (grilla de alto fijo).
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (showAuthor && gossip.author != null)
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: GossipAuthorRow(
                                    author: gossip.author!,
                                    compact: true,
                                  ),
                                ),
                              ),

                            // Botón compartir
                            Semantics(
                              label: context.l10n.gossipCardShareSemanticLabel,
                              hint: context.l10n.gossipCardShareSemanticHint,
                              button: true,
                              child: IconButton(
                                icon: const Icon(Icons.share, size: 20),
                                onPressed: () => _shareGossip(context, gossip),
                                // ✅ Touch target mínimo 48×48dp
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                iconSize: 20,
                                tooltip: context.l10n.gossipCardShareTooltip,
                              ),
                            ),

                            // Botón reportar (menú)
                            Semantics(
                              label: context.l10n.gossipCardReportSemanticLabel,
                              hint: context.l10n.gossipCardReportSemanticHint,
                              button: true,
                              child: IconButton(
                                icon: const Icon(Icons.flag_outlined, size: 20),
                                onPressed: () => _reportGossip(context, gossip),
                                constraints: const BoxConstraints(
                                  minWidth: 48,
                                  minHeight: 48,
                                ),
                                iconSize: 20,
                                tooltip: context.l10n.gossipCardReportTooltip,
                              ),
                            ),
                          ],
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

  /// Imagen del chisme: thumbnail (30 KB) primero, fallback a imagen completa (150 KB)
  Widget _buildImage(BuildContext context) {
    return Image.network(
      gossip.thumbnailUrl ??
          gossip.imageUrl ??
          'https://via.placeholder.com/150',
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.image,
            size: 50,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }
}
