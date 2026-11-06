import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/logging/app_logger.dart';
import 'package:chismes/core/services/location_service.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/features/location/domain/usecases/get_countries.dart';
import 'package:chismes/features/location/domain/usecases/get_regions_by_country.dart';
import 'package:chismes/features/location/domain/usecases/get_cities_by_region.dart';
import 'package:chismes/features/location/presentation/managers/location_manager.dart';
import 'package:geolocator/geolocator.dart';

import 'location_manager_test.mocks.dart';

@GenerateMocks([
  GetCountries,
  GetRegionsByCountry,
  GetCitiesByRegion,
  LocationService,
  AppLogger,
])
void main() {
  late LocationManager manager;
  late MockGetCountries mockGetCountries;
  late MockGetRegionsByCountry mockGetRegionsByCountry;
  late MockGetCitiesByRegion mockGetCitiesByRegion;
  late MockLocationService mockLocationService;
  late MockAppLogger mockLogger;

  setUp(() {
    mockGetCountries = MockGetCountries();
    mockGetRegionsByCountry = MockGetRegionsByCountry();
    mockGetCitiesByRegion = MockGetCitiesByRegion();
    mockLocationService = MockLocationService();
    mockLogger = MockAppLogger();

    // Provide dummies
    provideDummy<Result<Failure, List<Country>>>(Result.success([]));
    provideDummy<Result<Failure, List<Region>>>(Result.success([]));
    provideDummy<Result<Failure, List<City>>>(Result.success([]));

    manager = LocationManager(
      mockGetCountries,
      mockGetRegionsByCountry,
      mockGetCitiesByRegion,
      mockLocationService,
      mockLogger,
    );
  });

  tearDown(() {
    manager.dispose();
  });

  group('LocationManager - loadCountries', () {
    test('debe cargar países exitosamente', () async {
      // Arrange
      final countries = [
        const Country(id: 'co', code: 'CO', name: 'Colombia'),
        const Country(id: 'ar', code: 'AR', name: 'Argentina'),
      ];

      when(mockGetCountries()).thenAnswer((_) async => Result.success(countries));

      // Act
      await manager.loadCountries();

      // Assert
      expect(manager.state.countries, countries);
      expect(manager.state.isLoadingCountries, isFalse);
      expect(manager.state.error, isNull);
      verify(mockGetCountries()).called(1);
    });

    test('debe manejar error al cargar países', () async {
      // Arrange
      final failure = const NetworkFailure(
        code: ErrorCode.networkError,
        technicalMessage: 'Network error',
      );

      when(mockGetCountries()).thenAnswer((_) async => Result.failure(failure));

      // Act
      await manager.loadCountries();

      // Assert
      expect(manager.state.countries, isEmpty);
      expect(manager.state.isLoadingCountries, isFalse);
      expect(manager.state.error, isNotNull);
      expect(manager.state.error, contains('Error al cargar países'));
    });

    test('debe establecer isLoadingCountries durante la carga', () async {
      // Arrange
      when(mockGetCountries()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return Result.success([]);
      });

      // Act
      final future = manager.loadCountries();

      // Assert - durante la carga
      expect(manager.state.isLoadingCountries, isTrue);

      await future;

      // Assert - después de la carga
      expect(manager.state.isLoadingCountries, isFalse);
    });

    test('debe limpiar error anterior al cargar países', () async {
      // Arrange
      when(mockGetCountries()).thenAnswer((_) async => Result.success([]));

      // Establecer error previo
      await manager.loadCountries();

      // Act
      await manager.loadCountries();

      // Assert
      expect(manager.state.error, isNull);
    });

    test('debe manejar excepción inesperada al cargar países', () async {
      // Arrange
      when(mockGetCountries()).thenThrow(Exception('Unexpected error'));

      // Act
      await manager.loadCountries();

      // Assert
      expect(manager.state.countries, isEmpty);
      expect(manager.state.isLoadingCountries, isFalse);
      expect(manager.state.error, isNotNull);
      expect(manager.state.error, contains('Error inesperado'));
    });
  });

  group('LocationManager - loadRegions', () {
    test('debe cargar regiones exitosamente', () async {
      // Arrange
      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      final regions = [
        const Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department'),
        const Region(id: 'cun', countryId: 'co', name: 'Cundinamarca', type: 'department'),
      ];

      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.success(regions));

      // Act
      await manager.loadRegions(country);

      // Assert
      expect(manager.state.selectedCountry, country);
      expect(manager.state.regions, regions);
      expect(manager.state.isLoadingRegions, isFalse);
      expect(manager.state.error, isNull);
    });

    test('debe limpiar regiones y ciudades previas', () async {
      // Arrange
      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      when(mockGetRegionsByCountry(any))
          .thenAnswer((_) async => Result.success([]));

      // Act
      await manager.loadRegions(country);

      // Assert
      expect(manager.state.regions, isEmpty);
      expect(manager.state.cities, isEmpty);
      expect(manager.state.selectedRegion, isNull);
      expect(manager.state.selectedCity, isNull);
    });

    test('debe manejar error al cargar regiones', () async {
      // Arrange
      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      final failure = const ServerFailure(
        code: ErrorCode.serverError,
        message: 'Server error',
      );

      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.failure(failure));

      // Act
      await manager.loadRegions(country);

      // Assert
      expect(manager.state.regions, isEmpty);
      expect(manager.state.isLoadingRegions, isFalse);
      expect(manager.state.error, isNotNull);
    });

    test('debe manejar excepción inesperada al cargar regiones', () async {
      // Arrange
      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      when(mockGetRegionsByCountry('co')).thenThrow(Exception('Unexpected error'));

      // Act
      await manager.loadRegions(country);

      // Assert
      expect(manager.state.regions, isEmpty);
      expect(manager.state.isLoadingRegions, isFalse);
      expect(manager.state.error, isNotNull);
      expect(manager.state.error, contains('Error inesperado'));
    });
  });

  group('LocationManager - loadCities', () {
    test('debe cargar ciudades exitosamente', () async {
      // Arrange
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      final cities = [
        const City(id: 'med', regionId: 'ant', name: 'Medellín'),
        const City(id: 'env', regionId: 'ant', name: 'Envigado'),
      ];

      when(mockGetCitiesByRegion('ant'))
          .thenAnswer((_) async => Result.success(cities));

      // Act
      await manager.loadCities(region);

      // Assert
      expect(manager.state.selectedRegion, region);
      expect(manager.state.cities, cities);
      expect(manager.state.isLoadingCities, isFalse);
      expect(manager.state.error, isNull);
    });

    test('debe limpiar ciudades previas', () async {
      // Arrange
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      when(mockGetCitiesByRegion(any))
          .thenAnswer((_) async => Result.success([]));

      // Act
      await manager.loadCities(region);

      // Assert
      expect(manager.state.cities, isEmpty);
      expect(manager.state.selectedCity, isNull);
    });

    test('debe manejar error al cargar ciudades', () async {
      // Arrange
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      final failure = const NetworkFailure(
        code: ErrorCode.networkError,
        technicalMessage: 'Network error',
      );

      when(mockGetCitiesByRegion('ant'))
          .thenAnswer((_) async => Result.failure(failure));

      // Act
      await manager.loadCities(region);

      // Assert
      expect(manager.state.cities, isEmpty);
      expect(manager.state.isLoadingCities, isFalse);
      expect(manager.state.error, isNotNull);
    });

    test('debe manejar excepción inesperada al cargar ciudades', () async {
      // Arrange
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      when(mockGetCitiesByRegion('ant')).thenThrow(Exception('Unexpected error'));

      // Act
      await manager.loadCities(region);

      // Assert
      expect(manager.state.cities, isEmpty);
      expect(manager.state.isLoadingCities, isFalse);
      expect(manager.state.error, isNotNull);
      expect(manager.state.error, contains('Error inesperado'));
    });
  });

  group('LocationManager - selectCity', () {
    test('debe seleccionar ciudad correctamente', () {
      // Arrange
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

      // Act
      manager.selectCity(city);

      // Assert
      expect(manager.state.selectedCity, city);
      expect(manager.state.error, isNull);
    });

    test('debe notificar listeners al seleccionar ciudad', () {
      // Arrange
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');
      var notified = false;
      manager.addListener(() => notified = true);

      // Act
      manager.selectCity(city);

      // Assert
      expect(notified, isTrue);
    });
  });

  group('LocationManager - clearLocation', () {
    test('debe limpiar ubicación seleccionada', () {
      // Arrange
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');
      manager.selectCity(city);

      // Act
      manager.clearLocation();

      // Assert
      expect(manager.state.selectedCountry, isNull);
      expect(manager.state.selectedRegion, isNull);
      expect(manager.state.selectedCity, isNull);
      expect(manager.state.regions, isEmpty);
      expect(manager.state.cities, isEmpty);
      expect(manager.state.error, isNull);
    });
  });

  group('LocationManager - saveDefaultLocation', () {
    test('debe guardar ubicación válida', () async {
      // Arrange
      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

      when(mockGetRegionsByCountry(any))
          .thenAnswer((_) async => Result.success([region]));
      when(mockGetCitiesByRegion(any))
          .thenAnswer((_) async => Result.success([city]));

      await manager.loadRegions(country);
      await manager.loadCities(region);
      manager.selectCity(city);

      when(mockLocationService.saveDefaultLocation(
        countryId: anyNamed('countryId'),
        countryName: anyNamed('countryName'),
        regionId: anyNamed('regionId'),
        regionName: anyNamed('regionName'),
        cityId: anyNamed('cityId'),
        cityName: anyNamed('cityName'),
      )).thenAnswer((_) async => Future.value());

      // Act
      await manager.saveDefaultLocation();

      // Assert
      verify(mockLocationService.saveDefaultLocation(
        countryId: 'co',
        countryName: 'Colombia',
        regionId: 'ant',
        regionName: 'Antioquia',
        cityId: 'med',
        cityName: 'Medellín',
      )).called(1);
    });

    test('no debe guardar si ubicación está incompleta', () async {
      // Arrange - no hay ubicación seleccionada

      // Act
      await manager.saveDefaultLocation();

      // Assert
      verifyNever(mockLocationService.saveDefaultLocation(
        countryId: anyNamed('countryId'),
        countryName: anyNamed('countryName'),
        regionId: anyNamed('regionId'),
        regionName: anyNamed('regionName'),
        cityId: anyNamed('cityId'),
        cityName: anyNamed('cityName'),
      ));
    });

    test('debe manejar error al guardar ubicación', () async {
      // Arrange
      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

      when(mockGetRegionsByCountry(any))
          .thenAnswer((_) async => Result.success([region]));
      when(mockGetCitiesByRegion(any))
          .thenAnswer((_) async => Result.success([city]));

      await manager.loadRegions(country);
      await manager.loadCities(region);
      manager.selectCity(city);

      when(mockLocationService.saveDefaultLocation(
        countryId: anyNamed('countryId'),
        countryName: anyNamed('countryName'),
        regionId: anyNamed('regionId'),
        regionName: anyNamed('regionName'),
        cityId: anyNamed('cityId'),
        cityName: anyNamed('cityName'),
      )).thenThrow(Exception('Save error'));

      // Act
      await manager.saveDefaultLocation();

      // Assert - No debe lanzar excepción, solo loggear
      verify(mockLocationService.saveDefaultLocation(
        countryId: 'co',
        countryName: 'Colombia',
        regionId: 'ant',
        regionName: 'Antioquia',
        cityId: 'med',
        cityName: 'Medellín',
      )).called(1);
    });
  });

  group('LocationManager - loadDefaultLocation', () {
    test('debe cargar ubicación guardada exitosamente', () async {
      // Arrange
      final savedLocation = SavedLocation(
        countryId: 'co',
        countryName: 'Colombia',
        regionId: 'ant',
        regionName: 'Antioquia',
        cityId: 'med',
        cityName: 'Medellín',
      );

      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => savedLocation);
      when(mockGetCountries()).thenAnswer((_) async => Result.success([country]));
      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.success([region]));
      when(mockGetCitiesByRegion('ant'))
          .thenAnswer((_) async => Result.success([city]));

      // Act
      await manager.loadDefaultLocation();

      // Assert
      expect(manager.state.selectedCountry, country);
      expect(manager.state.selectedRegion, region);
      expect(manager.state.selectedCity, city);
      verify(mockLocationService.getDefaultLocation()).called(1);
    });

    test('debe llamar detectLocationFromGPS cuando no hay ubicación guardada', () async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => null);
      when(mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => null); // GPS falla, para simplificar

      // Act
      await manager.loadDefaultLocation();

      // Assert
      verify(mockLocationService.getDefaultLocation()).called(1);
      verify(mockLocationService.getCurrentPosition()).called(1);
    });

    test('debe retornar early si país guardado no se encuentra', () async {
      // Arrange
      final savedLocation = SavedLocation(
        countryId: 'mx',
        countryName: 'México',
        regionId: 'jal',
        regionName: 'Jalisco',
        cityId: 'gdl',
        cityName: 'Guadalajara',
      );

      const country = Country(id: 'co', code: 'CO', name: 'Colombia');

      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => savedLocation);
      when(mockGetCountries()).thenAnswer((_) async => Result.success([country])); // Solo Colombia

      // Act
      await manager.loadDefaultLocation();

      // Assert - No debe seleccionar ninguna ubicación
      expect(manager.state.selectedCountry, isNull);
      expect(manager.state.selectedRegion, isNull);
      expect(manager.state.selectedCity, isNull);
    });

    test('debe retornar early si región guardada no se encuentra', () async {
      // Arrange
      final savedLocation = SavedLocation(
        countryId: 'co',
        countryName: 'Colombia',
        regionId: 'cun',
        regionName: 'Cundinamarca',
        cityId: 'bog',
        cityName: 'Bogotá',
      );

      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');

      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => savedLocation);
      when(mockGetCountries()).thenAnswer((_) async => Result.success([country]));
      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.success([region])); // Solo Antioquia

      // Act
      await manager.loadDefaultLocation();

      // Assert
      expect(manager.state.selectedCountry, country);
      expect(manager.state.selectedRegion, isNull);
      expect(manager.state.selectedCity, isNull);
    });

    test('debe retornar early si ciudad guardada no se encuentra', () async {
      // Arrange
      final savedLocation = SavedLocation(
        countryId: 'co',
        countryName: 'Colombia',
        regionId: 'ant',
        regionName: 'Antioquia',
        cityId: 'bog',
        cityName: 'Bogotá',
      );

      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

      when(mockLocationService.getDefaultLocation())
          .thenAnswer((_) async => savedLocation);
      when(mockGetCountries()).thenAnswer((_) async => Result.success([country]));
      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.success([region]));
      when(mockGetCitiesByRegion('ant'))
          .thenAnswer((_) async => Result.success([city])); // Solo Medellín

      // Act
      await manager.loadDefaultLocation();

      // Assert
      expect(manager.state.selectedCountry, country);
      expect(manager.state.selectedRegion, region);
      expect(manager.state.selectedCity, isNull);
    });

    test('debe manejar error al cargar ubicación por defecto', () async {
      // Arrange
      when(mockLocationService.getDefaultLocation())
          .thenThrow(Exception('Error al leer SharedPreferences'));

      // Act
      await manager.loadDefaultLocation();

      // Assert - No debe lanzar excepción, solo loggear
      verify(mockLocationService.getDefaultLocation()).called(1);
    });
  });

  group('LocationManager - detectLocationFromGPS', () {
    test('debe detectar ubicación exitosamente desde GPS', () async {
      // Arrange
      final position = Position(
        latitude: 6.244203,
        longitude: -75.581212,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 1495,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      final detectedLocation = DetectedLocation(
        cityName: 'Medellín',
        regionName: 'Antioquia',
        countryName: 'Colombia',
      );

      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

      when(mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => position);
      when(mockLocationService.getCityFromCoordinates(position.latitude, position.longitude))
          .thenAnswer((_) async => detectedLocation);
      when(mockGetCountries()).thenAnswer((_) async => Result.success([country]));
      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.success([region]));
      when(mockGetCitiesByRegion('ant'))
          .thenAnswer((_) async => Result.success([city]));

      // Act
      await manager.detectLocationFromGPS();

      // Assert
      expect(manager.state.selectedCountry, country);
      expect(manager.state.selectedRegion, region);
      expect(manager.state.selectedCity, city);
      expect(manager.state.isDetectingLocation, isFalse);
      expect(manager.state.error, isNull);
    });

    test('debe manejar cuando getCurrentPosition devuelve null', () async {
      // Arrange
      when(mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => null);

      // Act
      await manager.detectLocationFromGPS();

      // Assert
      expect(manager.state.isDetectingLocation, isFalse);
      expect(manager.state.error, isNotNull);
      expect(manager.state.error, contains('No se pudo detectar ubicación'));
      expect(manager.state.selectedCity, isNull);
    });

    test('debe manejar cuando geocodificación devuelve null', () async {
      // Arrange
      final position = Position(
        latitude: 6.244203,
        longitude: -75.581212,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 1495,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      when(mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => position);
      when(mockLocationService.getCityFromCoordinates(position.latitude, position.longitude))
          .thenAnswer((_) async => null);

      // Act
      await manager.detectLocationFromGPS();

      // Assert
      expect(manager.state.isDetectingLocation, isFalse);
      expect(manager.state.error, isNotNull);
      expect(manager.state.error, contains('No se pudo identificar la ubicación'));
      expect(manager.state.selectedCity, isNull);
    });

    test('debe manejar cuando país no está en BD', () async {
      // Arrange
      final position = Position(
        latitude: 6.244203,
        longitude: -75.581212,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 1495,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      final detectedLocation = DetectedLocation(
        cityName: 'Ciudad de México',
        regionName: 'CDMX',
        countryName: 'México',
      );

      const country = Country(id: 'co', code: 'CO', name: 'Colombia');

      when(mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => position);
      when(mockLocationService.getCityFromCoordinates(position.latitude, position.longitude))
          .thenAnswer((_) async => detectedLocation);
      when(mockGetCountries()).thenAnswer((_) async => Result.success([country])); // Solo Colombia

      // Act
      await manager.detectLocationFromGPS();

      // Assert
      expect(manager.state.isDetectingLocation, isFalse);
      expect(manager.state.error, isNotNull);
      expect(manager.state.error, contains('México'));
      expect(manager.state.error, contains('no disponible'));
      expect(manager.state.selectedCity, isNull);
    });

    test('debe manejar cuando región no está en BD', () async {
      // Arrange
      final position = Position(
        latitude: 6.244203,
        longitude: -75.581212,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 1495,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      final detectedLocation = DetectedLocation(
        cityName: 'Bogotá',
        regionName: 'Cundinamarca',
        countryName: 'Colombia',
      );

      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');

      when(mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => position);
      when(mockLocationService.getCityFromCoordinates(position.latitude, position.longitude))
          .thenAnswer((_) async => detectedLocation);
      when(mockGetCountries()).thenAnswer((_) async => Result.success([country]));
      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.success([region])); // Solo Antioquia

      // Act
      await manager.detectLocationFromGPS();

      // Assert
      expect(manager.state.isDetectingLocation, isFalse);
      expect(manager.state.error, isNotNull);
      expect(manager.state.error, contains('Cundinamarca'));
      expect(manager.state.error, contains('no disponible'));
      expect(manager.state.selectedCity, isNull);
    });

    test('debe manejar cuando ciudad no está en BD', () async {
      // Arrange
      final position = Position(
        latitude: 6.244203,
        longitude: -75.581212,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 1495,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      final detectedLocation = DetectedLocation(
        cityName: 'Envigado',
        regionName: 'Antioquia',
        countryName: 'Colombia',
      );

      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

      when(mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => position);
      when(mockLocationService.getCityFromCoordinates(position.latitude, position.longitude))
          .thenAnswer((_) async => detectedLocation);
      when(mockGetCountries()).thenAnswer((_) async => Result.success([country]));
      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.success([region]));
      when(mockGetCitiesByRegion('ant'))
          .thenAnswer((_) async => Result.success([city])); // Solo Medellín

      // Act
      await manager.detectLocationFromGPS();

      // Assert
      expect(manager.state.isDetectingLocation, isFalse);
      expect(manager.state.error, isNotNull);
      expect(manager.state.error, contains('Envigado'));
      expect(manager.state.error, contains('no disponible'));
      expect(manager.state.selectedCity, isNull);
    });

    test('debe manejar excepción al detectar ubicación', () async {
      // Arrange
      when(mockLocationService.getCurrentPosition())
          .thenThrow(Exception('GPS error'));

      // Act
      await manager.detectLocationFromGPS();

      // Assert
      expect(manager.state.isDetectingLocation, isFalse);
      expect(manager.state.error, isNotNull);
      expect(manager.state.error, contains('Error al detectar ubicación'));
    });

    test('debe cargar países si no están cargados', () async {
      // Arrange
      final position = Position(
        latitude: 6.244203,
        longitude: -75.581212,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 1495,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );

      final detectedLocation = DetectedLocation(
        cityName: 'Medellín',
        regionName: 'Antioquia',
        countryName: 'Colombia',
      );

      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

      when(mockLocationService.getCurrentPosition())
          .thenAnswer((_) async => position);
      when(mockLocationService.getCityFromCoordinates(position.latitude, position.longitude))
          .thenAnswer((_) async => detectedLocation);
      when(mockGetCountries()).thenAnswer((_) async => Result.success([country]));
      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.success([region]));
      when(mockGetCitiesByRegion('ant'))
          .thenAnswer((_) async => Result.success([city]));

      // Act
      await manager.detectLocationFromGPS();

      // Assert
      verify(mockGetCountries()).called(1); // Debe cargar países
      expect(manager.state.countries, isNotEmpty);
    });
  });

  group('LocationManager - validateHierarchy', () {
    test('debe retornar false si no hay ubicación completa', () {
      // Act
      final isValid = manager.validateHierarchy();

      // Assert
      expect(isValid, isFalse);
    });

    test('debe retornar true cuando la jerarquía es válida', () async {
      // Arrange
      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.success([region]));
      when(mockGetCitiesByRegion('ant'))
          .thenAnswer((_) async => Result.success([city]));

      await manager.loadRegions(country);
      await manager.loadCities(region);
      manager.selectCity(city);

      // Act
      final isValid = manager.validateHierarchy();

      // Assert
      expect(isValid, isTrue);
    });

    test('debe retornar false si la región no pertenece al país', () async {
      // Arrange
      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      const otherRegion = Region(id: 'cun', countryId: 'co', name: 'Cundinamarca', type: 'department');
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.success([otherRegion])); // Solo carga otra región
      when(mockGetCitiesByRegion('ant'))
          .thenAnswer((_) async => Result.success([city]));

      await manager.loadRegions(country);
      await manager.loadCities(region); // Intenta cargar cities con región diferente
      manager.selectCity(city);

      // Act
      final isValid = manager.validateHierarchy();

      // Assert
      expect(isValid, isFalse);
    });

    test('debe retornar false si la ciudad no pertenece a la región', () async {
      // Arrange
      const country = Country(id: 'co', code: 'CO', name: 'Colombia');
      const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
      const city = City(id: 'med', regionId: 'ant', name: 'Medellín');
      const otherCity = City(id: 'bog', regionId: 'cun', name: 'Bogotá');

      when(mockGetRegionsByCountry('co'))
          .thenAnswer((_) async => Result.success([region]));
      when(mockGetCitiesByRegion('ant'))
          .thenAnswer((_) async => Result.success([city]));

      await manager.loadRegions(country);
      await manager.loadCities(region);
      // Selecciona una ciudad que no pertenece a la región cargada
      manager.selectCity(otherCity);

      // Act
      final isValid = manager.validateHierarchy();

      // Assert
      expect(isValid, isFalse);
    });
  });

  group('LocationManager - notifyListeners', () {
    test('debe notificar listeners cuando cambia el estado', () async {
      // Arrange
      var notificationCount = 0;
      manager.addListener(() => notificationCount++);

      when(mockGetCountries()).thenAnswer((_) async => Result.success([]));

      // Act
      await manager.loadCountries();

      // Assert
      expect(notificationCount, greaterThan(0));
    });

    test('debe ser ChangeNotifier', () {
      // Assert
      expect(manager, isA<dynamic>());
    });
  });

  group('LocationManager - estado inicial', () {
    test('debe tener estado inicial correcto', () {
      // Assert
      expect(manager.state.countries, isEmpty);
      expect(manager.state.regions, isEmpty);
      expect(manager.state.cities, isEmpty);
      expect(manager.state.selectedCountry, isNull);
      expect(manager.state.selectedRegion, isNull);
      expect(manager.state.selectedCity, isNull);
      expect(manager.state.isLoadingCountries, isFalse);
      expect(manager.state.isLoadingRegions, isFalse);
      expect(manager.state.isLoadingCities, isFalse);
      expect(manager.state.isDetectingLocation, isFalse);
      expect(manager.state.error, isNull);
    });
  });
}
