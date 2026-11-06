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
@injectable
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
    _logger.d('🌍 Cargando países');

    _updateState(_state.copyWith(
      isLoadingCountries: true,
      clearError: true,
    ));

    try {
      final result = await _getCountries();

      result.when(
        onFailure: (failure) {
          _logger.e('Error al cargar países', context: {
            'error': failure.toString(),
          });
          _updateState(_state.copyWith(
            isLoadingCountries: false,
            error: 'Error al cargar países',
          ));
        },
        onSuccess: (countries) {
          _logger.i('✅ Países cargados', context: {'count': countries.length});
          _updateState(_state.copyWith(
            countries: countries,
            isLoadingCountries: false,
            clearError: true,
          ));
        },
      );
    } catch (error, stackTrace) {
      _logger.e('Error inesperado al cargar países',
          error: error, stackTrace: stackTrace);
      _updateState(_state.copyWith(
        isLoadingCountries: false,
        error: 'Error inesperado',
      ));
    }
  }

  /// Carga las regiones del país seleccionado
  Future<void> loadRegions(Country country) async {
    _logger.d('🗺️ Cargando regiones', context: {'countryId': country.id});

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
          _logger.e('Error al cargar regiones', context: {
            'countryId': country.id,
            'error': failure.toString(),
          });
          _updateState(_state.copyWith(
            isLoadingRegions: false,
            error: 'Error al cargar regiones',
          ));
        },
        onSuccess: (regions) {
          _logger.i('✅ Regiones cargadas', context: {
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
      _logger.e('Error inesperado al cargar regiones',
          error: error, stackTrace: stackTrace);
      _updateState(_state.copyWith(
        isLoadingRegions: false,
        error: 'Error inesperado',
      ));
    }
  }

  /// Carga las ciudades de la región seleccionada
  Future<void> loadCities(Region region) async {
    _logger.d('🏙️ Cargando ciudades', context: {'regionId': region.id});

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
          _logger.e('Error al cargar ciudades', context: {
            'regionId': region.id,
            'error': failure.toString(),
          });
          _updateState(_state.copyWith(
            isLoadingCities: false,
            error: 'Error al cargar ciudades',
          ));
        },
        onSuccess: (cities) {
          _logger.i('✅ Ciudades cargadas', context: {
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
      _logger.e('Error inesperado al cargar ciudades',
          error: error, stackTrace: stackTrace);
      _updateState(_state.copyWith(
        isLoadingCities: false,
        error: 'Error inesperado',
      ));
    }
  }

  /// Selecciona una ciudad (sin recargar)
  void selectCity(City city) {
    _logger.d('📍 Ciudad seleccionada', context: {'cityId': city.id});

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
    _logger.i('📡 Detectando ubicación por GPS');

    _updateState(_state.copyWith(
      isDetectingLocation: true,
      clearError: true,
    ));

    try {
      // Paso 1: Obtener coordenadas GPS
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        _logger.w('❌ No se pudo obtener posición GPS');
        _updateState(_state.copyWith(
          isDetectingLocation: false,
          error: 'No se pudo detectar ubicación. Activa GPS e intenta de nuevo.',
        ));
        return;
      }

      _logger.d('📍 Posición GPS obtenida', context: {
        'lat': position.latitude,
        'lon': position.longitude,
      });

      // Paso 2: Geocodificar
      final detectedLocation = await _locationService.getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (detectedLocation == null) {
        _logger.w('❌ No se pudo geocodificar ubicación');
        _updateState(_state.copyWith(
          isDetectingLocation: false,
          error: 'No se pudo identificar la ubicación',
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
        _logger.w('❌ País no encontrado en BD', context: {
          'country': detectedLocation.countryName,
        });
        _updateState(_state.copyWith(
          isDetectingLocation: false,
          error:
              'País "${detectedLocation.countryName}" no disponible. Selecciona manualmente.',
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
        _logger.w('❌ Región no encontrada en BD', context: {
          'region': detectedLocation.regionName,
        });
        _updateState(_state.copyWith(
          isDetectingLocation: false,
          error:
              'Región "${detectedLocation.regionName}" no disponible. Selecciona manualmente.',
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
        _logger.w('❌ Ciudad no encontrada en BD', context: {
          'city': detectedLocation.cityName,
        });
        _updateState(_state.copyWith(
          isDetectingLocation: false,
          error:
              'Ciudad "${detectedLocation.cityName}" no disponible. Selecciona manualmente.',
        ));
        return;
      }

      // Éxito: Seleccionar ciudad
      selectCity(city);

      _logger.i('✅ Ubicación detectada automáticamente', context: {
        'country': country.name,
        'region': region.name,
        'city': city.name,
      });

      _updateState(_state.copyWith(
        isDetectingLocation: false,
        clearError: true,
      ));
    } catch (error, stackTrace) {
      _logger.e('Error al detectar ubicación',
          error: error, stackTrace: stackTrace);
      _updateState(_state.copyWith(
        isDetectingLocation: false,
        error: 'Error al detectar ubicación. Intenta de nuevo.',
      ));
    }
  }

  // ============================================
  // PERSISTENCIA (UBICACIÓN POR DEFECTO)
  // ============================================

  /// Guarda la ubicación seleccionada como por defecto
  Future<void> saveDefaultLocation() async {
    if (!_state.isValid) {
      _logger.w('⚠️ No se puede guardar ubicación incompleta');
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

      _logger.i('✅ Ubicación por defecto guardada', context: {
        'country': _state.selectedCountry!.name,
        'region': _state.selectedRegion!.name,
        'city': _state.selectedCity!.name,
      });
    } catch (error, stackTrace) {
      _logger.e('Error al guardar ubicación por defecto',
          error: error, stackTrace: stackTrace);
    }
  }

  /// Carga la ubicación por defecto guardada
  Future<void> loadDefaultLocation() async {
    _logger.d('📂 Cargando ubicación por defecto');

    try {
      final defaultLocation = await _locationService.getDefaultLocation();

      if (defaultLocation == null) {
        _logger.d('ℹ️ No hay ubicación por defecto guardada');
        // Intentar auto-detectar
        await detectLocationFromGPS();
        return;
      }

      _logger.i('✅ Ubicación por defecto encontrada', context: {
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
        _logger.w('⚠️ País guardado no encontrado en BD');
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
        _logger.w('⚠️ Región guardada no encontrada en BD');
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
        _logger.w('⚠️ Ciudad guardada no encontrada en BD');
        return;
      }

      // Seleccionar ciudad
      selectCity(city);

      _logger.i('✅ Ubicación por defecto cargada exitosamente');
    } catch (error, stackTrace) {
      _logger.e('Error al cargar ubicación por defecto',
          error: error, stackTrace: stackTrace);
    }
  }

  /// Limpia la ubicación seleccionada (reset)
  void clearLocation() {
    _logger.d('🗑️ Limpiando ubicación seleccionada');

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
      _logger.e('⚠️ Región no pertenece al país seleccionado');
      return false;
    }

    // Validar que ciudad pertenece a la región
    final cityBelongsToRegion = _state.cities.any(
      (c) => c.id == _state.selectedCity!.id,
    );

    if (!cityBelongsToRegion) {
      _logger.e('⚠️ Ciudad no pertenece a la región seleccionada');
      return false;
    }

    return true;
  }
}
