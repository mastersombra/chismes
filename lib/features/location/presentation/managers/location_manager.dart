import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/country.dart';
import '../../domain/entities/region.dart';
import '../../domain/usecases/get_cities_by_region.dart';
import '../../domain/usecases/get_countries.dart';
import '../../domain/usecases/get_regions_by_country.dart';
import '../states/location_state.dart';
import 'location_error_key.dart';

/// Manager para gestión de ubicación en formularios
///
/// **Responsabilidad:** Coordinar la selección de país/región/ciudad
/// **Uso:** Inyectar en controllers que necesiten ubicación
///
/// **Principios:**
/// - Single Responsibility: Solo gestiona ubicación
/// - Reutilizable: Puede usarse en múltiples pantallas
/// - Testeable: Todas las dependencias inyectadas
///
/// **Funcionalidades:**
/// - Cargar jerarquía de ubicaciones (país → región → ciudad)
/// - Detectar ubicación automática por GPS
/// - Guardar/cargar ubicación por defecto
/// - Validar jerarquía completa
///
/// **Ejemplo:**
/// ```dart
/// @injectable
/// class MyController {
///   final LocationManager locationManager;
///
///   MyController(this.locationManager);
///
///   Future<void> init() async {
///     await locationManager.loadCountries();
///     locationManager.addListener(_onLocationChanged);
///   }
///
///   void _onLocationChanged() {
///     if (locationManager.state.isValid) {
///       // Usar ubicación seleccionada
///     }
///   }
/// }
/// ```
///
/// **Singleton (lazy):** una sola instancia en toda la app para que Crea y
/// el feed vean la misma ubicación. Antes era factory: cada controller tenía
/// su propio estado (el feed nunca tenía ciudad) y dos instancias pedían
/// permisos de GPS en paralelo. No llamar `dispose()` desde un controller.
@lazySingleton
class LocationManager extends ChangeNotifier {
  final GetCountries _getCountries;
  final GetRegionsByCountry _getRegionsByCountry;
  final GetCitiesByRegion _getCitiesByRegion;
  final LocationService _locationService;
  final AppLogger _logger;

  LocationState _state = LocationState.initial();

  LocationManager(
    this._getCountries,
    this._getRegionsByCountry,
    this._getCitiesByRegion,
    this._locationService,
    this._logger,
  );

  /// Estado actual de ubicación (inmutable)
  LocationState get state => _state;

  /// Actualiza el estado y notifica listeners
  void _updateState(LocationState newState) {
    _state = newState;
    notifyListeners();
  }

  // ============================================
  // CARGAR JERARQUÍA
  // ============================================

  /// Carga la lista de países disponibles
  Future<void> loadCountries() async {
    _logger.d('Loading countries');

    _updateState(_state.copyWith(
      isLoadingCountries: true,
      clearError: true,
    ));

    try {
      final result = await _getCountries();

      result.when(
        onFailure: (failure) {
          _logger.e('Failed to load countries', context: {
            'error': failure.toString(),
          });
          _updateState(_state.copyWith(
            isLoadingCountries: false,
            errorKey: LocationErrorKey.failedToLoadCountries,
          ));
        },
        onSuccess: (countries) {
          _logger.i('Countries loaded', context: {'count': countries.length});
          _updateState(_state.copyWith(
            countries: countries,
            isLoadingCountries: false,
            clearError: true,
          ));
        },
      );
    } catch (error, stackTrace) {
      _logger.e('Unexpected error loading countries',
          error: error, stackTrace: stackTrace);
      _updateState(_state.copyWith(
        isLoadingCountries: false,
        errorKey: LocationErrorKey.unexpectedError,
      ));
    }
  }

  /// Carga las regiones del país seleccionado
  Future<void> loadRegions(Country country) async {
    _logger.d('Loading regions', context: {'countryId': country.id});

    _updateState(_state.copyWith(
      selectedCountry: country,
      isLoadingRegions: true,
      regions: [], // Limpiar regiones previas
      cities: [], // Limpiar ciudades previas
      clearSelectedRegion: true,
      clearSelectedCity: true,
      clearError: true,
    ));

    try {
      final result = await _getRegionsByCountry(country.id);

      result.when(
        onFailure: (failure) {
          _logger.e('Failed to load regions', context: {
            'countryId': country.id,
            'error': failure.toString(),
          });
          _updateState(_state.copyWith(
            isLoadingRegions: false,
            errorKey: LocationErrorKey.failedToLoadRegions,
          ));
        },
        onSuccess: (regions) {
          _logger.i('Regions loaded', context: {
            'countryId': country.id,
            'count': regions.length,
          });
          _updateState(_state.copyWith(
            regions: regions,
            isLoadingRegions: false,
            clearError: true,
          ));
        },
      );
    } catch (error, stackTrace) {
      _logger.e('Unexpected error loading regions',
          error: error, stackTrace: stackTrace);
      _updateState(_state.copyWith(
        isLoadingRegions: false,
        errorKey: LocationErrorKey.unexpectedError,
      ));
    }
  }

  /// Carga las ciudades de la región seleccionada
  Future<void> loadCities(Region region) async {
    _logger.d('Loading cities', context: {'regionId': region.id});

    _updateState(_state.copyWith(
      selectedRegion: region,
      isLoadingCities: true,
      cities: [], // Limpiar ciudades previas
      clearSelectedCity: true,
      clearError: true,
    ));

    try {
      final result = await _getCitiesByRegion(region.id);

      result.when(
        onFailure: (failure) {
          _logger.e('Failed to load cities', context: {
            'regionId': region.id,
            'error': failure.toString(),
          });
          _updateState(_state.copyWith(
            isLoadingCities: false,
            errorKey: LocationErrorKey.failedToLoadCities,
          ));
        },
        onSuccess: (cities) {
          _logger.i('Cities loaded', context: {
            'regionId': region.id,
            'count': cities.length,
          });
          _updateState(_state.copyWith(
            cities: cities,
            isLoadingCities: false,
            clearError: true,
          ));
        },
      );
    } catch (error, stackTrace) {
      _logger.e('Unexpected error loading cities',
          error: error, stackTrace: stackTrace);
      _updateState(_state.copyWith(
        isLoadingCities: false,
        errorKey: LocationErrorKey.unexpectedError,
      ));
    }
  }

  /// Selecciona una ciudad (sin recargar)
  void selectCity(City city) {
    _logger.d('City selected', context: {'cityId': city.id});

    _updateState(_state.copyWith(
      selectedCity: city,
      clearError: true,
    ));
  }

  // ============================================
  // DETECCIÓN GPS
  // ============================================

  /// Detecta ubicación automática usando GPS + Geocoding
  ///
  /// **Flujo:**
  /// 1. Obtener coordenadas GPS
  /// 2. Geocodificar a dirección
  /// 3. Buscar país/región/ciudad en BD
  /// 4. Seleccionar automáticamente
  Future<void> detectLocationFromGPS() async {
    _logger.i('Detecting location via GPS');

    _updateState(_state.copyWith(
      isDetectingLocation: true,
      clearError: true,
    ));

    try {
      // Paso 1: Obtener coordenadas GPS
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        _logger.w('Failed to get GPS position');
        _updateState(_state.copyWith(
          isDetectingLocation: false,
          errorKey: LocationErrorKey.gpsPositionFailed,
        ));
        return;
      }

      _logger.d('GPS position obtained', context: {
        'lat': position.latitude,
        'lon': position.longitude,
      });

      // Paso 2: Geocodificar
      final detectedLocation = await _locationService.getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (detectedLocation == null) {
        _logger.w('Failed to geocode location');
        _updateState(_state.copyWith(
          isDetectingLocation: false,
          errorKey: LocationErrorKey.geocodingFailed,
        ));
        return;
      }

      _logger.d('🗺️ Ubicación geocodificada', context: {
        'country': detectedLocation.countryName,
        'region': detectedLocation.regionName,
        'city': detectedLocation.cityName,
      });

      // Paso 3: Buscar en BD (primero cargar países si no están)
      if (_state.countries.isEmpty) {
        await loadCountries();
      }

      // Buscar país
      final country = _state.countries.cast<Country?>().firstWhere(
            (c) =>
                c!.name.toLowerCase() ==
                detectedLocation.countryName.toLowerCase().trim(),
            orElse: () => null,
          );

      if (country == null) {
        _logger.w('Country not found in DB', context: {
          'country': detectedLocation.countryName,
        });
        _updateState(_state.copyWith(
          isDetectingLocation: false,
          errorKey: LocationErrorKey.countryNotAvailable,
          errorEntityName: detectedLocation.countryName,
        ));
        return;
      }

      // Cargar regiones
      await loadRegions(country);

      // Buscar región
      final region = _state.regions.cast<Region?>().firstWhere(
            (r) =>
                r!.name.toLowerCase() ==
                detectedLocation.regionName.toLowerCase().trim(),
            orElse: () => null,
          );

      if (region == null) {
        _logger.w('Region not found in DB', context: {
          'region': detectedLocation.regionName,
        });
        _updateState(_state.copyWith(
          isDetectingLocation: false,
          errorKey: LocationErrorKey.regionNotAvailable,
          errorEntityName: detectedLocation.regionName,
        ));
        return;
      }

      // Cargar ciudades
      await loadCities(region);

      // Buscar ciudad
      final city = _state.cities.cast<City?>().firstWhere(
            (c) =>
                c!.name.toLowerCase() == detectedLocation.cityName.toLowerCase().trim(),
            orElse: () => null,
          );

      if (city == null) {
        _logger.w('City not found in DB', context: {
          'city': detectedLocation.cityName,
        });
        _updateState(_state.copyWith(
          isDetectingLocation: false,
          errorKey: LocationErrorKey.cityNotAvailable,
          errorEntityName: detectedLocation.cityName,
        ));
        return;
      }

      // Éxito: Seleccionar ciudad
      selectCity(city);

      _logger.i('Location detected automatically', context: {
        'country': country.name,
        'region': region.name,
        'city': city.name,
      });

      _updateState(_state.copyWith(
        isDetectingLocation: false,
        clearError: true,
      ));
    } catch (error, stackTrace) {
      _logger.e('Failed to detect location',
          error: error, stackTrace: stackTrace);
      _updateState(_state.copyWith(
        isDetectingLocation: false,
        errorKey: LocationErrorKey.detectionFailed,
      ));
    }
  }

  // ============================================
  // PERSISTENCIA (UBICACIÓN POR DEFECTO)
  // ============================================

  /// Guarda la ubicación seleccionada como por defecto
  Future<void> saveDefaultLocation() async {
    if (!_state.isValid) {
      _logger.w('Cannot save incomplete location');
      return;
    }

    try {
      await _locationService.saveDefaultLocation(
        countryId: _state.selectedCountry!.id,
        countryName: _state.selectedCountry!.name,
        regionId: _state.selectedRegion!.id,
        regionName: _state.selectedRegion!.name,
        cityId: _state.selectedCity!.id,
        cityName: _state.selectedCity!.name,
      );

      _logger.i('Default location saved', context: {
        'country': _state.selectedCountry!.name,
        'region': _state.selectedRegion!.name,
        'city': _state.selectedCity!.name,
      });
    } catch (error, stackTrace) {
      _logger.e('Failed to save default location',
          error: error, stackTrace: stackTrace);
    }
  }

  /// Carga la ubicación por defecto guardada
  Future<void> loadDefaultLocation() async {
    _logger.d('Loading default location');

    try {
      final defaultLocation = await _locationService.getDefaultLocation();

      if (defaultLocation == null) {
        _logger.d('No default location saved');
        // Intentar auto-detectar
        await detectLocationFromGPS();
        return;
      }

      _logger.i('Default location found', context: {
        'location': defaultLocation.compactText,
      });

      // Cargar países si no están
      if (_state.countries.isEmpty) {
        await loadCountries();
      }

      // Buscar país
      final country = _state.countries.cast<Country?>().firstWhere(
            (c) => c!.id == defaultLocation.countryId,
            orElse: () => null,
          );

      if (country == null) {
        _logger.w('Saved country not found in DB - clearing invalid data');
        // Limpiar ubicación inválida guardada
        await _locationService.clearDefaultLocation();
        clearLocation();
        return;
      }

      // Cargar regiones
      await loadRegions(country);

      // Buscar región
      final region = _state.regions.cast<Region?>().firstWhere(
            (r) => r!.id == defaultLocation.regionId,
            orElse: () => null,
          );

      if (region == null) {
        _logger.w('Saved region not found in DB - early return');
        // Early return: mantener país seleccionado pero sin región/ciudad
        await _locationService.clearDefaultLocation();
        // Solo actualizar país, dejar región y ciudad en null
        _updateState(_state.copyWith(
          selectedCountry: country,
          clearSelectedRegion: true,
          clearSelectedCity: true,
        ));
        return;
      }

      // Cargar ciudades
      await loadCities(region);

      // Buscar ciudad
      final city = _state.cities.cast<City?>().firstWhere(
            (c) => c!.id == defaultLocation.cityId,
            orElse: () => null,
          );

      if (city == null) {
        _logger.w('Saved city not found in DB - early return');
        // Early return: mantener país y región seleccionados pero sin ciudad
        await _locationService.clearDefaultLocation();
        // Solo actualizar país y región, dejar ciudad en null
        _updateState(_state.copyWith(
          selectedCountry: country,
          selectedRegion: region,
          clearSelectedCity: true,
        ));
        return;
      }

      // Seleccionar ciudad (esto también actualiza país y región)
      selectCity(city);

      _logger.i('Default location loaded successfully');
    } catch (error, stackTrace) {
      _logger.e('Failed to load default location',
          error: error, stackTrace: stackTrace);
    }
  }

  /// Limpia la ubicación seleccionada (reset)
  void clearLocation() {
    _logger.d('Clearing selected location');

    _updateState(_state.copyWith(
      clearSelectedCountry: true,
      clearSelectedRegion: true,
      clearSelectedCity: true,
      regions: [],
      cities: [],
      clearError: true,
    ));
  }

  /// Valida que la jerarquía esté completa y sea consistente
  ///
  /// **Validaciones:**
  /// - Región pertenece al país
  /// - Ciudad pertenece a la región
  bool validateHierarchy() {
    if (!_state.isValid) {
      return false;
    }

    // Validar que región pertenece al país
    final regionBelongsToCountry = _state.regions.any(
      (r) => r.id == _state.selectedRegion!.id,
    );

    if (!regionBelongsToCountry) {
      _logger.e('Region does not belong to selected country');
      return false;
    }

    // Validar que ciudad pertenece a la región
    final cityBelongsToRegion = _state.cities.any(
      (c) => c.id == _state.selectedCity!.id,
    );

    if (!cityBelongsToRegion) {
      _logger.e('City does not belong to selected region');
      return false;
    }

    return true;
  }
}
