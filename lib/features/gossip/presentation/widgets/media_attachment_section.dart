import 'package:flutter/material.dart';
import '../states/add_gossip_state.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

/// Widget para adjuntar media (imagen y audio)
///
/// ⚠️ FLUJO COMPLETO PARA PRODUCCIÓN:
///
/// El flujo completo de media es:
///
/// 1. Usuario selecciona imagen/audio
/// 2. Archivo local (File)
/// 3. Validar tamaño/formato:
///    - Imagen: tamaño máximo, tipo MIME, dimensiones máximas
///    - Audio: tamaño máximo, tipo MIME, duración máxima
/// 4. Preview en UI
/// 5. Upload a Supabase Storage
/// 6. Obtener media reference (URL)
/// 7. Crear Gossip con imageUrl/audioUrl
/// 8. Guardar en Supabase (PostgreSQL)
///
/// LÍMITES RECOMENDADOS (configurables):
/// - Imagen: max 5MB, tipos: JPEG, PNG, WEBP, max 4096x4096px
/// - Audio: max 10MB, tipos: MP3, M4A, AAC, max 5 minutos
///
/// IMPORTANTE: No confiar únicamente en la extensión del archivo.
/// Validar tipo MIME real del archivo.
class MediaAttachmentSection extends StatelessWidget {
  final AddGossipState state;
  final VoidCallback onPickImage;
  final VoidCallback onPickAudio;
  final VoidCallback onRemoveImage;
  final VoidCallback onRemoveAudio;

  const MediaAttachmentSection({
    super.key,
    required this.state,
    required this.onPickImage,
    required this.onPickAudio,
    required this.onRemoveImage,
    required this.onRemoveAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildImageAttachment(context),
        const SizedBox(height: AppSpacing.lg),
        _buildAudioAttachment(),
      ],
    );
  }

  Widget _buildImageAttachment(BuildContext context) {
    if (state.imageUrl != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.network(
              state.imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
              ),
              onPressed: onRemoveImage,
            ),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: onPickImage,
      icon: const Icon(Icons.image),
      label: Text(AppLocalizations.gossipMediaAddImage),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }

  Widget _buildAudioAttachment() {
    if (state.audioUrl != null) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.audiotrack),
          title: Text(AppLocalizations.gossipMediaAudioAttached),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: onRemoveAudio,
          ),
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPickAudio,
      icon: const Icon(Icons.mic),
      label: Text(AppLocalizations.gossipMediaAddAudio),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
