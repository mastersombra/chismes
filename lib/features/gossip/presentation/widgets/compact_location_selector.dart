import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

/// Widget compacto para mostrar ubicación seleccionada con opción de cambiar
///
/// **UI:**
/// ```
/// ┌─────────────────────────────────────────┐
/// │ 📍 Medellín, Antioquia    [Cambiar]    │
/// └─────────────────────────────────────────┘
/// ```
///
/// **Comportamiento:**
/// - Muestra la ubicación actual en formato "Ciudad, Región"
/// - Botón "Cambiar" abre dialog de selección
/// - Mucho más compacto que 3 dropdowns separados
/// - UX tipo Uber/Mercado Libre
class CompactLocationSelector extends StatelessWidget {
  final String? locationText;
  final VoidCallback onChangePressed;
  final bool isLoading;

  const CompactLocationSelector({
    super.key,
    required this.locationText,
    required this.onChangePressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Accesibilidad: Descripción semántica del componente
    final semanticLabel = isLoading
        ? 'gossip.location_selector.semantic_label_detecting'.tr()
        : locationText != null
            ? 'gossip.location_selector.semantic_label_selected'.tr(namedArgs: {'location': locationText!})
            : 'gossip.location_selector.semantic_label_empty'.tr();

    return Semantics(
      label: semanticLabel,
      hint: 'gossip.location_selector.semantic_hint'.tr(),
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calcular si hay suficiente espacio para el botón con texto
            // Con font scale alto (>= 1.5x), usar solo ícono para evitar overflow
            final textScaler = MediaQuery.textScalerOf(context);
            final textScaleFactor = textScaler.scale(1.0);
            final hasSpaceForButtonText = textScaleFactor < 1.5 && constraints.maxWidth > 300;

            return Row(
              children: [
                // ✅ Ícono de ubicación con semantics
                Semantics(
                  label: 'gossip.location_selector.icon_semantic_label'.tr(),
                  excludeSemantics: true,
                  child: Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

              // Texto de ubicación o placeholder
              Expanded(
                child: isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: Text(
                              'gossip.location_selector.detecting_text'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    : locationText != null
                        ? Text(
                            locationText!,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                            overflow: TextOverflow.ellipsis,
                          )
                        : Text(
                            'gossip.location_selector.placeholder_text'.tr(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
              ),

              const SizedBox(width: AppSpacing.sm),

              // ✅ Botón "Cambiar" con touch target accesible (adaptativo)
              Semantics(
                label: 'gossip.location_selector.change_button_semantic_label'.tr(),
                hint: 'gossip.location_selector.change_button_semantic_hint'.tr(),
                button: true,
                enabled: !isLoading,
                child: hasSpaceForButtonText
                    ? TextButton.icon(
                        onPressed: isLoading ? null : onChangePressed,
                        icon: const Icon(Icons.edit_location_alt, size: 18),
                        label: Text('gossip.location_selector.change_button_label'.tr()),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44), // ✅ Touch target
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.sm,
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: isLoading ? null : onChangePressed,
                        icon: const Icon(Icons.edit_location_alt, size: 20),
                        iconSize: 20,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        padding: const EdgeInsets.all(AppSpacing.sm),
                      ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}
