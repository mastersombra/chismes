import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

/// Widget para seleccionar y previsualizar imagen
///
/// **Estados:**
/// - Sin imagen: Muestra botones para cámara/galería
/// - Con imagen: Muestra preview + botón para remover
/// - Subiendo: Muestra loading indicator
class ImagePickerWidget extends StatelessWidget {
  final String? imageUrl; // URL local para preview
  final bool isUploading;
  final VoidCallback onPickFromCamera;
  final VoidCallback onPickFromGallery;
  final VoidCallback? onRemove;

  const ImagePickerWidget({
    super.key,
    this.imageUrl,
    required this.isUploading,
    required this.onPickFromCamera,
    required this.onPickFromGallery,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Estado 1: Con imagen seleccionada
    if (imageUrl != null) {
      return _buildImagePreview(context);
    }

    // Estado 2: Subiendo imagen
    if (isUploading) {
      return _buildLoadingState();
    }

    // Estado 3: Sin imagen (botones para seleccionar)
    return _buildSelectionButtons();
  }

  /// Preview de imagen seleccionada
  Widget _buildImagePreview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagen seleccionada',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Stack(
          children: [
            // ✅ Accesibilidad: Semantics para imagen
            Semantics(
              label: 'Imagen del chisme seleccionada',
              image: true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Image.file(
                  File(imageUrl!),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // ✅ Botón para remover con touch target accesible
            if (onRemove != null)
              Positioned(
                top: 8,
                right: 8,
                child: Semantics(
                  label: 'Eliminar imagen',
                  hint: 'Remueve la imagen seleccionada',
                  button: true,
                  child: Builder(
                    builder: (context) => IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: onRemove,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                        minimumSize: const Size(48, 48), // ✅ Touch target
                      ),
                      tooltip: 'Eliminar imagen',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Estado de carga
  Widget _buildLoadingState() {
    return Builder(
      builder: (context) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        // ✅ Accesibilidad: Live region para cambios de estado
        child: Semantics(
          label: 'Seleccionando imagen, por favor espera',
          liveRegion: true, // Anuncia cambios de estado
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  semanticsLabel: 'Cargando imagen', // ✅ Label para progress
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Seleccionando imagen...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Botones para seleccionar imagen
  Widget _buildSelectionButtons() {
    return Builder(
      builder: (context) => Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Agrega una foto (opcional)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

          // ✅ Botones con Semantics y touch targets accesibles
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón cámara
              Semantics(
                label: 'Tomar foto con la cámara',
                hint: 'Abre la cámara para tomar una foto',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: onPickFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(AppLocalizations.gossipMediaCamera),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 48), // ✅ Touch target
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Botón galería
              Semantics(
                label: 'Seleccionar foto de la galería',
                hint: 'Abre la galería de fotos',
                button: true,
                child: OutlinedButton.icon(
                  onPressed: onPickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(AppLocalizations.gossipMediaGallery),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 48), // ✅ Touch target
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}
