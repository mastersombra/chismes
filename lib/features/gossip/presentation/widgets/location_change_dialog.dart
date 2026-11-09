import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../location/presentation/states/location_state.dart';
import '../../../location/domain/entities/city.dart';
import 'city_autocomplete_optimized.dart';
import '../../../location/domain/usecases/search_cities.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

/// Dialog para cambiar la ubicación del chisme
///
/// **Opciones:**
/// 1. Usar ubicación actual (GPS) - botón destacado
/// 2. Selección manual: País ▼ → Región ▼ → Ciudad 🔍 (autocomplete)
///
/// **UX:**
/// - Botón GPS arriba para casos comunes (90%)
/// - Selección manual abajo para casos específicos (10%)
class LocationChangeDialog extends StatefulWidget {
  final LocationState state;
  final VoidCallback onUseCurrentLocation;
  final ValueChanged<String?> onCountryChanged;
  final ValueChanged<String?> onRegionChanged;
  final ValueChanged<City?> onCityChanged;
  final VoidCallback onConfirm;
  final bool isLoadingGPS;
  final SearchCities searchCities;

  const LocationChangeDialog({
    super.key,
    required this.state,
    required this.onUseCurrentLocation,
    required this.onCountryChanged,
    required this.onRegionChanged,
    required this.onCityChanged,
    required this.onConfirm,
    required this.searchCities,
    this.isLoadingGPS = false,
  });

  @override
  State<LocationChangeDialog> createState() => _LocationChangeDialogState();
}

class _LocationChangeDialogState extends State<LocationChangeDialog> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(Icons.edit_location_alt),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        AppLocalizations.locationChangeDialogTitle,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Mostrar error si hay
                if (widget.state.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            widget.state.error!,
                            style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Opción 1: Usar ubicación actual (destacado)
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: InkWell(
                    onTap: widget.isLoadingGPS ? null : widget.onUseCurrentLocation,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            Icons.my_location,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: widget.isLoadingGPS
                                ? Text('gossip.location_selector.detecting_text'.tr())
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppLocalizations.locationUseCurrentLocation,
                                        style: textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        AppLocalizations.locationGpsDetectSubtitle,
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                          ),
                          if (widget.isLoadingGPS)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Divider con texto
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      child: Text(
                        AppLocalizations.locationOrSelectManually,
                        style: textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                            ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Opción 2: Selección manual
                _buildCountryDropdown(),
                const SizedBox(height: AppSpacing.md),

                if (widget.state.selectedCountry != null) ...[
                  _buildRegionDropdown(),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (widget.state.selectedRegion != null) ...[
                  CityAutocompleteOptimized(
                    regionId: widget.state.selectedRegion!.id,
                    searchCities: widget.searchCities,
                    selectedCity: widget.state.selectedCity,
                    onCitySelected: widget.onCityChanged,
                    validator: (value) => value == null || value.isEmpty ? AppLocalizations.locationCityRequired : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Botones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(AppLocalizations.cancel),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: FilledButton(
                        onPressed: widget.state.selectedCity != null
                            ? () {
                                if (_formKey.currentState!.validate()) {
                                  widget.onConfirm();
                                  Navigator.of(context).pop();
                                }
                              }
                            : null,
                        child: Text(AppLocalizations.confirm),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: widget.state.selectedCountry?.id,
      decoration: InputDecoration(
        labelText: AppLocalizations.locationCountryLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        prefixIcon: const Icon(Icons.public),
        suffixIcon: widget.state.isLoadingCountries
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      items: widget.state.countries.map((country) {
        return DropdownMenuItem(
          value: country.id,
          child: Text(country.name),
        );
      }).toList(),
      onChanged: widget.state.isLoadingCountries ? null : widget.onCountryChanged,
      validator: (value) => value == null || value.isEmpty ? AppLocalizations.locationCountryRequired : null,
    );
  }

  Widget _buildRegionDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: widget.state.selectedRegion?.id,
      decoration: InputDecoration(
        labelText: AppLocalizations.locationRegionLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        prefixIcon: const Icon(Icons.location_city),
        suffixIcon: widget.state.isLoadingRegions
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      items: widget.state.regions.map((region) {
        return DropdownMenuItem(
          value: region.id,
          child: Text(region.name),
        );
      }).toList(),
      onChanged: widget.state.isLoadingRegions ? null : widget.onRegionChanged,
      validator: (value) => value == null || value.isEmpty ? AppLocalizations.locationRegionRequired : null,
    );
  }
}
