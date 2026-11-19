import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

/// Keys para errores de ubicación localizados
enum LocationErrorKey {
  failedToLoadCountries,
  failedToLoadRegions,
  failedToLoadCities,
  unexpectedError,
  gpsPositionFailed,
  geocodingFailed,
  countryNotAvailable,
  regionNotAvailable,
  cityNotAvailable,
  detectionFailed,
}

/// Extension para obtener mensaje localizado
extension LocationErrorKeyExtension on LocationErrorKey {
  String getMessage(BuildContext context, {String? entityName}) {
    final l10n = AppLocalizations.of(context)!;

    switch (this) {
      case LocationErrorKey.failedToLoadCountries:
        return l10n.locationErrorLoadCountries;
      case LocationErrorKey.failedToLoadRegions:
        return l10n.locationErrorLoadRegions;
      case LocationErrorKey.failedToLoadCities:
        return l10n.locationErrorLoadCities;
      case LocationErrorKey.unexpectedError:
        return l10n.locationErrorUnexpected;
      case LocationErrorKey.gpsPositionFailed:
        return l10n.locationErrorGpsPosition;
      case LocationErrorKey.geocodingFailed:
        return l10n.locationErrorGeocoding;
      case LocationErrorKey.countryNotAvailable:
        return l10n.locationErrorCountryNotAvailable(entityName ?? '');
      case LocationErrorKey.regionNotAvailable:
        return l10n.locationErrorRegionNotAvailable(entityName ?? '');
      case LocationErrorKey.cityNotAvailable:
        return l10n.locationErrorCityNotAvailable(entityName ?? '');
      case LocationErrorKey.detectionFailed:
        return l10n.locationErrorDetection;
    }
  }
}
