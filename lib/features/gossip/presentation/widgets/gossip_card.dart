import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/app_localizations.dart';
import '../screens/gossip_detail_screen.dart';
import '../../domain/entities/gossip.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/usecases/report_gossip.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/services/deep_link_service.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import 'report_gossip_dialog.dart';

class GossipCard extends StatelessWidget {
  final Gossip gossip;

  const GossipCard({
    super.key,
    required this.gossip,
  });

  /// Comparte el chisme usando deep link
  Future<void> _shareGossip(BuildContext context, Gossip gossip) async {
    // Generar deep link
    final deepLink = DeepLinkService.generateGossipLink(gossip.id);

    // Texto para compartir
    final shareText = '''
🔥 Mira este chisme:

"${gossip.subject}"

${gossip.content.length > 100 ? '${gossip.content.substring(0, 100)}...' : gossip.content}

$deepLink

📱 Descarga Chismes para ver más
''';

    try {
      await SharePlus.instance.share(
        ShareParams(text: shareText),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('gossip.card.share_error'.tr()),
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
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
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
            ServerFailure(:final message) => message ?? AppLocalizations.gossipCardReportError,
            RateLimitFailure(:final message) => message ?? AppLocalizations.gossipCardRateLimitError,
            _ => failure.technicalMessage ?? AppLocalizations.gossipCardReportError,
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
              content: Text('gossip.card.report_success'.tr()),
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
      label: AppLocalizations.gossipCardSemanticLabel(gossip.subject, gossip.content),
      hint: AppLocalizations.gossipCardSemanticHint,
      button: true,
      excludeSemantics: true, // No leer hijos (evitar duplicación)
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GossipDetailScreen(
                gossip: gossip,
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

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Image.network(
                // ✅ P6-4: Usar thumbnail primero (30 KB), fallback a imagen completa (150 KB)
                gossip.thumbnailUrl ?? gossip.imageUrl ?? 'https://via.placeholder.com/150',
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
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    gossip.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  Text(
                    gossip.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // ✅ Botones de acción (compartir y reportar)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Botón compartir
                      Semantics(
                        label: AppLocalizations.gossipCardShareSemanticLabel,
                        hint: AppLocalizations.gossipCardShareSemanticHint,
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
                          tooltip: AppLocalizations.gossipCardShareTooltip,
                        ),
                      ),

                      // Botón reportar (menú)
                      Semantics(
                        label: AppLocalizations.gossipCardReportSemanticLabel,
                        hint: AppLocalizations.gossipCardReportSemanticHint,
                        button: true,
                        child: IconButton(
                          icon: const Icon(Icons.flag_outlined, size: 20),
                          onPressed: () => _reportGossip(context, gossip),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          iconSize: 20,
                          tooltip: AppLocalizations.gossipCardReportTooltip,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}