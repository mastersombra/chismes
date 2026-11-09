import 'package:flutter/material.dart';
import '../states/add_gossip_state.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/localization/app_localizations.dart';

/// Widget para seleccionar ubicación (país, región, ciudad)
class LocationSelector extends StatelessWidget {
  final AddGossipState state;
  final ValueChanged<String?> onCountrySelected;
  final ValueChanged<String?> onRegionSelected;
  final ValueChanged<String?> onCitySelected;

  const LocationSelector({
    super.key,
    required this.state,
    required this.onCountrySelected,
    required this.onRegionSelected,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCountryDropdown(),
        const SizedBox(height: AppSpacing.lg),
        _buildRegionDropdown(),
        const SizedBox(height: AppSpacing.lg),
        _buildCityDropdown(),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey('country_${state.selectedCountryId}'),
      initialValue: state.selectedCountryId,
      decoration: InputDecoration(
        labelText: AppLocalizations.locationCountryLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        prefixIcon: const Icon(Icons.public),
        suffixIcon: state.isLoadingCountries
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      items: state.countries.map((country) {
        return DropdownMenuItem(
          value: country.id,
          child: Text(country.name),
        );
      }).toList(),
      onChanged: state.isLoadingCountries
          ? null
          : onCountrySelected,
      validator: (value) => value == null || value.isEmpty ? AppLocalizations.locationCountryRequired : null,
    );
  }

  Widget _buildRegionDropdown() {
    if (state.selectedCountryId == null) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('region_${state.selectedRegionId}'),
      initialValue: state.selectedRegionId,
      decoration: InputDecoration(
        labelText: AppLocalizations.locationRegionLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        prefixIcon: const Icon(Icons.location_city),
        suffixIcon: state.isLoadingRegions
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      items: state.regions.map((region) {
        return DropdownMenuItem(
          value: region.id,
          child: Text(region.name),
        );
      }).toList(),
      onChanged: state.isLoadingRegions
          ? null
          : onRegionSelected,
      validator: (value) => value == null || value.isEmpty ? AppLocalizations.locationRegionRequired : null,
    );
  }

  Widget _buildCityDropdown() {
    if (state.selectedRegionId == null) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('city_${state.selectedCityId}'),
      initialValue: state.selectedCityId,
      decoration: InputDecoration(
        labelText: AppLocalizations.locationCityLabel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        prefixIcon: const Icon(Icons.location_on),
        suffixIcon: state.isLoadingCities
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      items: state.cities.map((city) {
        return DropdownMenuItem(
          value: city.id,
          child: Text(city.name),
        );
      }).toList(),
      onChanged: state.isLoadingCities
          ? null
          : onCitySelected,
      validator: (value) => value == null || value.isEmpty ? AppLocalizations.locationCityRequired : null,
    );
  }
}
