import 'package:equatable/equatable.dart';

import '../../domain/entities/city.dart';
import '../../domain/entities/country.dart';
import '../../domain/entities/region.dart';
import '../managers/location_error_key.dart';

/// Estado inmutable para gestión de ubicación en formularios
///
/// **Responsabilidad:** Mantener el estado de ubicación con validaciones
/// **Uso:** Controllers que necesitan selección de país/región/ciudad
///
/// **Principios:**
/// - Inmutable (copyWith para cambios)
/// - Type-safe (valores siempre consistentes)
/// - Validable (jerarquía completa o null)
///
/// **Ejemplo:**
/// ```dart
/// // Estado inicial
/// var state = LocationState.initial();
///
/// // Usuario selecciona país
/// state = state.copyWith(
///   selectedCountry: country,
///   isLoadingRegions: true,
/// );
/// ```
class LocationState extends Equatable {
  /// Lista de países disponibles
  final List<Country> countries;

  /// Lista de regiones disponibles (filtradas por país seleccionado)
  final List<Region> regions;

  /// Lista de ciudades disponibles (filtradas por región seleccionada)
  final List<City> cities;

  /// País seleccionado por el usuario (o null si no ha seleccionado)
  final Country? selectedCountry;

  /// Región seleccionada por el usuario (o null si no ha seleccionado)
  final Region? selectedRegion;

  /// Ciudad seleccionada por el usuario (o null si no ha seleccionado)
  final City? selectedCity;

  /// Indica si se están cargando los países
  final bool isLoadingCountries;

  /// Indica si se están cargando las regiones
  final bool isLoadingRegions;

  /// Indica si se están cargando las ciudades
  final bool isLoadingCities;

  /// Indica si se está detectando ubicación por GPS
  final bool isDetectingLocation;

  /// Error cargar ubicación (si hay)
  /// @deprecated Usar errorKey en su lugar
  final String? error;

  /// Clave de error localizada (reemplaza a error)
  final LocationErrorKey? errorKey;

  /// Nombre de la entidad relacionada con el error (ej: nombre de país/región/ciudad)
  final String? errorEntityName;

  const LocationState({
    required this.countries,
    required this.regions,
    required this.cities,
    this.selectedCountry,
    this.selectedRegion,
    this.selectedCity,
    required this.isLoadingCountries,
    required this.isLoadingRegions,
    required this.isLoadingCities,
    required this.isDetectingLocation,
    this.error,
    this.errorKey,
    this.errorEntityName,
  });

  /// Estado inicial (vacío, sin cargas)
  factory LocationState.initial() {
    return const LocationState(
      countries: [],
      regions: [],
      cities: [],
      selectedCountry: null,
      selectedRegion: null,
      selectedCity: null,
      isLoadingCountries: false,
      isLoadingRegions: false,
      isLoadingCities: false,
      isDetectingLocation: false,
      error: null,
      errorKey: null,
      errorEntityName: null,
    );
  }

  /// Valida si la jerarquía está completa
  ///
  /// **Regla:** Para crear un gossip se requiere país, región Y ciudad
  bool get isValid {
    return selectedCountry != null &&
        selectedRegion != null &&
        selectedCity != null;
  }

  /// Indica si hay alguna carga en progreso
  bool get isLoading {
    return isLoadingCountries ||
        isLoadingRegions ||
        isLoadingCities ||
        isDetectingLocation;
  }

  /// Copia el estado con cambios opcionales
  LocationState copyWith({
    List<Country>? countries,
    List<Region>? regions,
    List<City>? cities,
    Country? selectedCountry,
    Region? selectedRegion,
    City? selectedCity,
    bool? isLoadingCountries,
    bool? isLoadingRegions,
    bool? isLoadingCities,
    bool? isDetectingLocation,
    String? error,
    LocationErrorKey? errorKey,
    String? errorEntityName,
    bool clearError = false,
    bool clearSelectedCountry = false,
    bool clearSelectedRegion = false,
    bool clearSelectedCity = false,
  }) {
    return LocationState(
      countries: countries ?? this.countries,
      regions: regions ?? this.regions,
      cities: cities ?? this.cities,
      selectedCountry: clearSelectedCountry
          ? null
          : (selectedCountry ?? this.selectedCountry),
      selectedRegion: clearSelectedRegion
          ? null
          : (selectedRegion ?? this.selectedRegion),
      selectedCity:
          clearSelectedCity ? null : (selectedCity ?? this.selectedCity),
      isLoadingCountries: isLoadingCountries ?? this.isLoadingCountries,
      isLoadingRegions: isLoadingRegions ?? this.isLoadingRegions,
      isLoadingCities: isLoadingCities ?? this.isLoadingCities,
      isDetectingLocation: isDetectingLocation ?? this.isDetectingLocation,
      error: clearError ? null : (error ?? this.error),
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
      errorEntityName: clearError ? null : (errorEntityName ?? this.errorEntityName),
    );
  }

  @override
  List<Object?> get props => [
        countries,
        regions,
        cities,
        selectedCountry,
        selectedRegion,
        selectedCity,
        isLoadingCountries,
        isLoadingRegions,
        isLoadingCities,
        isDetectingLocation,
        error,
        errorKey,
        errorEntityName,
      ];
}
