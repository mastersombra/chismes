import 'package:flutter/material.dart';
import '../states/add_gossip_state.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import 'package:chismes/core/l10n/l10n.dart';

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
        _buildCountryDropdown(context),
        const SizedBox(height: AppSpacing.lg),
        _buildRegionDropdown(context),
        const SizedBox(height: AppSpacing.lg),
        _buildCityDropdown(context),
      ],
    );
  }

  Widget _buildCountryDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('country_${state.selectedCountryId}'),
      initialValue: state.selectedCountryId,
      decoration: InputDecoration(
        labelText: context.l10n.locationCountryLabel,
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
      validator: (value) => value == null || value.isEmpty ? context.l10n.locationCountryRequired : null,
    );
  }

  Widget _buildRegionDropdown(BuildContext context) {
    if (state.selectedCountryId == null) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('region_${state.selectedRegionId}'),
      initialValue: state.selectedRegionId,
      decoration: InputDecoration(
        labelText: context.l10n.locationRegionLabel,
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
      validator: (value) => value == null || value.isEmpty ? context.l10n.locationRegionRequired : null,
    );
  }

  Widget _buildCityDropdown(BuildContext context) {
    if (state.selectedRegionId == null) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String>(
      key: ValueKey('city_${state.selectedCityId}'),
      initialValue: state.selectedCityId,
      decoration: InputDecoration(
        labelText: context.l10n.locationCityLabel,
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
      validator: (value) => value == null || value.isEmpty ? context.l10n.locationCityRequired : null,
    );
  }
}
