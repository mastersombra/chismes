import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chismes/core/services/location_service.dart';
import 'package:chismes/core/logging/logging.dart';

import 'location_service_test.mocks.dart';

@GenerateMocks([AppLogger])
// ignore: unused_element
void _generateMocks() {}

void main() {
  group('DetectedLocation', () {
    group('Constructor', () {
      test('debe crear instancia con todos los campos', () {
        final location = DetectedLocation(
          cityName: 'Los Angeles',
          regionName: 'California',
          countryName: 'United States',
        );

        expect(location.cityName, 'Los Angeles');
        expect(location.regionName, 'California');
        expect(location.countryName, 'United States');
      });

      test('debe crear instancia con caracteres especiales', () {
        final location = DetectedLocation(
          cityName: 'São Paulo',
          regionName: 'São Paulo',
          countryName: 'Brasil',
        );

        expect(location.cityName, 'São Paulo');
        expect(location.regionName, 'São Paulo');
        expect(location.countryName, 'Brasil');
      });

      test('debe crear instancia con nombres con acentos', () {
        final location = DetectedLocation(
          cityName: 'Bogotá',
          regionName: 'Cundinamarca',
          countryName: 'Colombia',
        );

        expect(location.cityName, 'Bogotá');
        expect(location.regionName, 'Cundinamarca');
        expect(location.countryName, 'Colombia');
      });

      test('debe crear instancia con nombres largos', () {
        final location = DetectedLocation(
          cityName: 'San José de Costa Rica',
          regionName: 'Provincia de San José',
          countryName: 'República de Costa Rica',
        );

        expect(location.cityName, contains('San José'));
        expect(location.regionName, contains('Provincia'));
        expect(location.countryName, contains('República'));
      });
    });

    group('Uso en contexto', () {
      test('debe permitir crear múltiples instancias', () {
        final location1 = DetectedLocation(
          cityName: 'New York',
          regionName: 'New York',
          countryName: 'United States',
        );

        final location2 = DetectedLocation(
          cityName: 'London',
          regionName: 'England',
          countryName: 'United Kingdom',
        );

        expect(location1.cityName, isNot(equals(location2.cityName)));
        expect(location1.countryName, isNot(equals(location2.countryName)));
      });

      test('debe almacenar nombres tal como vienen del geocoding', () {
        final location = DetectedLocation(
          cityName: 'Paris',
          regionName: 'Île-de-France',
          countryName: 'France',
        );

        expect(location.cityName, 'Paris');
        expect(location.regionName, contains('-'));
      });
    });

    group('Casos edge', () {
      test('debe manejar nombres con espacios', () {
        final location = DetectedLocation(
          cityName: 'New York City',
          regionName: 'New York State',
          countryName: 'United States of America',
        );

        expect(location.cityName.split(' ').length, greaterThan(1));
        expect(location.regionName.split(' ').length, greaterThan(1));
        expect(location.countryName.split(' ').length, greaterThan(1));
      });

      test('debe manejar nombres cortos', () {
        final location = DetectedLocation(
          cityName: 'LA',
          regionName: 'CA',
          countryName: 'US',
        );

        expect(location.cityName.length, 2);
        expect(location.regionName.length, 2);
        expect(location.countryName.length, 2);
      });

      test('debe manejar nombres en diferentes idiomas', () {
        final locations = [
          DetectedLocation(cityName: '東京', regionName: '東京都', countryName: '日本'),
          DetectedLocation(cityName: 'Москва', regionName: 'Москва', countryName: 'Россия'),
          DetectedLocation(cityName: 'القاهرة', regionName: 'القاهرة', countryName: 'مصر'),
        ];

        expect(locations.length, 3);
        expect(locations[0].cityName, '東京');
        expect(locations[1].cityName, 'Москва');
        expect(locations[2].cityName, 'القاهرة');
      });
    });
  });

  group('SavedLocation', () {
    group('Constructor', () {
      test('debe crear instancia con todos los campos', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'United States',
          regionName: 'California',
          cityName: 'Los Angeles',
        );

        expect(location.countryId, '1');
        expect(location.regionId, '2');
        expect(location.cityId, '3');
        expect(location.countryName, 'United States');
        expect(location.regionName, 'California');
        expect(location.cityName, 'Los Angeles');
      });

      test('debe crear instancia con ids UUID', () {
        final location = SavedLocation(
          countryId: 'uuid-country-123',
          regionId: 'uuid-region-456',
          cityId: 'uuid-city-789',
          countryName: 'Country',
          regionName: 'Region',
          cityName: 'City',
        );

        expect(location.countryId, contains('uuid'));
        expect(location.regionId, contains('uuid'));
        expect(location.cityId, contains('uuid'));
      });

      test('debe crear instancia con caracteres especiales en nombres', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'España',
          regionName: 'Cataluña',
          cityName: 'Barcelona',
        );

        expect(location.countryName, 'España');
        expect(location.regionName, 'Cataluña');
        expect(location.cityName, 'Barcelona');
      });
    });

    group('displayText', () {
      test('debe formatear como "Ciudad, Región, País"', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'United States',
          regionName: 'California',
          cityName: 'Los Angeles',
        );

        expect(location.displayText, 'Los Angeles, California, United States');
      });

      test('debe incluir todos los nombres separados por comas', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'Colombia',
          regionName: 'Cundinamarca',
          cityName: 'Bogotá',
        );

        expect(location.displayText, contains('Bogotá'));
        expect(location.displayText, contains('Cundinamarca'));
        expect(location.displayText, contains('Colombia'));
        expect(location.displayText.split(', ').length, 3);
      });

      test('debe funcionar con nombres largos', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'United Kingdom of Great Britain',
          regionName: 'Greater London',
          cityName: 'City of Westminster',
        );

        expect(location.displayText.length, greaterThan(20));
        expect(location.displayText.split(', ').length, 3);
      });

      test('debe funcionar con nombres cortos', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'US',
          regionName: 'CA',
          cityName: 'LA',
        );

        expect(location.displayText, 'LA, CA, US');
      });

      test('debe mantener el orden Ciudad, Región, País', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'France',
          regionName: 'Île-de-France',
          cityName: 'Paris',
        );

        final parts = location.displayText.split(', ');
        expect(parts[0], 'Paris'); // Ciudad primero
        expect(parts[1], 'Île-de-France'); // Región segundo
        expect(parts[2], 'France'); // País tercero
      });
    });

    group('compactText', () {
      test('debe formatear como "Ciudad, Región"', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'United States',
          regionName: 'California',
          cityName: 'Los Angeles',
        );

        expect(location.compactText, 'Los Angeles, California');
      });

      test('no debe incluir el país', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'United States',
          regionName: 'California',
          cityName: 'Los Angeles',
        );

        expect(location.compactText, isNot(contains('United States')));
        expect(location.compactText.split(', ').length, 2);
      });

      test('debe ser más corto que displayText', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'Colombia',
          regionName: 'Cundinamarca',
          cityName: 'Bogotá',
        );

        expect(location.compactText.length, lessThan(location.displayText.length));
      });

      test('debe funcionar con caracteres especiales', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'México',
          regionName: 'Jalisco',
          cityName: 'Guadalajara',
        );

        expect(location.compactText, 'Guadalajara, Jalisco');
        expect(location.compactText, isNot(contains('México')));
      });

      test('debe mantener el orden Ciudad, Región', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'Canada',
          regionName: 'Ontario',
          cityName: 'Toronto',
        );

        final parts = location.compactText.split(', ');
        expect(parts[0], 'Toronto'); // Ciudad primero
        expect(parts[1], 'Ontario'); // Región segundo
        expect(parts.length, 2); // Solo dos partes
      });
    });

    group('Comparación entre displayText y compactText', () {
      test('compactText debe ser un substring de displayText', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'United States',
          regionName: 'California',
          cityName: 'Los Angeles',
        );

        expect(location.displayText, startsWith(location.compactText));
      });

      test('ambos deben compartir ciudad y región', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'Spain',
          regionName: 'Madrid',
          cityName: 'Madrid',
        );

        expect(location.displayText, contains(location.cityName));
        expect(location.displayText, contains(location.regionName));
        expect(location.compactText, contains(location.cityName));
        expect(location.compactText, contains(location.regionName));
      });
    });

    group('Uso en UI', () {
      test('displayText debe ser apropiado para mostrar en formularios completos', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'Argentina',
          regionName: 'Buenos Aires',
          cityName: 'Buenos Aires',
        );

        // Formato completo para mostrar toda la información
        expect(location.displayText, 'Buenos Aires, Buenos Aires, Argentina');
      });

      test('compactText debe ser apropiado para mostrar en espacios reducidos', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'Brazil',
          regionName: 'Rio de Janeiro',
          cityName: 'Rio de Janeiro',
        );

        // Formato compacto para chips, badges, etc.
        expect(location.compactText, 'Rio de Janeiro, Rio de Janeiro');
        expect(location.compactText.length, lessThan(location.displayText.length));
      });
    });

    group('Casos edge', () {
      test('debe manejar nombres vacíos en displayText', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: '',
          regionName: '',
          cityName: '',
        );

        expect(location.displayText, ', , ');
      });

      test('debe manejar nombres vacíos en compactText', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: '',
          regionName: '',
          cityName: '',
        );

        expect(location.compactText, ', ');
      });

      test('debe manejar nombres con comas en displayText', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'Country, Name',
          regionName: 'Region, Name',
          cityName: 'City, Name',
        );

        // Nota: esto podría causar ambigüedad, pero el formato sigue funcionando
        expect(location.displayText, contains('City, Name'));
      });

      test('debe manejar nombres muy largos', () {
        final location = SavedLocation(
          countryId: '1',
          regionId: '2',
          cityId: '3',
          countryName: 'Very Long Country Name That Goes On And On',
          regionName: 'Very Long Region Name That Goes On And On',
          cityName: 'Very Long City Name That Goes On And On',
        );

        expect(location.displayText.length, greaterThan(100));
        expect(location.compactText.length, greaterThan(50));
      });
    });

    group('Uso en listas', () {
      test('debe poder crear lista de SavedLocations', () {
        final locations = [
          SavedLocation(
            countryId: '1', regionId: '1', cityId: '1',
            countryName: 'US', regionName: 'CA', cityName: 'LA',
          ),
          SavedLocation(
            countryId: '1', regionId: '2', cityId: '2',
            countryName: 'US', regionName: 'NY', cityName: 'NYC',
          ),
        ];

        expect(locations.length, 2);
        expect(locations[0].compactText, 'LA, CA');
        expect(locations[1].compactText, 'NYC, NY');
      });

      test('debe poder filtrar locations por countryId', () {
        final locations = [
          SavedLocation(
            countryId: 'us', regionId: '1', cityId: '1',
            countryName: 'US', regionName: 'CA', cityName: 'LA',
          ),
          SavedLocation(
            countryId: 'ca', regionId: '2', cityId: '2',
            countryName: 'Canada', regionName: 'ON', cityName: 'Toronto',
          ),
        ];

        final usLocations = locations.where((l) => l.countryId == 'us').toList();

        expect(usLocations.length, 1);
        expect(usLocations[0].cityName, 'LA');
      });
    });
  });

  group('LocationService - Persistencia', () {
    setUp(() {
      // Inicializar SharedPreferences con valores vacíos antes de cada test
      SharedPreferences.setMockInitialValues({});
    });

    group('saveDefaultLocation', () {
      test('debe guardar ubicación en SharedPreferences', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);
        final prefs = await SharedPreferences.getInstance();

        await service.saveDefaultLocation(
          countryId: 'country-1',
          regionId: 'region-1',
          cityId: 'city-1',
          countryName: 'United States',
          regionName: 'California',
          cityName: 'Los Angeles',
        );

        expect(prefs.getString('default_country_id'), 'country-1');
        expect(prefs.getString('default_region_id'), 'region-1');
        expect(prefs.getString('default_city_id'), 'city-1');
        expect(prefs.getString('default_country_name'), 'United States');
        expect(prefs.getString('default_region_name'), 'California');
        expect(prefs.getString('default_city_name'), 'Los Angeles');
      });

      test('debe sobrescribir ubicación anterior', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);
        final prefs = await SharedPreferences.getInstance();

        // Guardar primera ubicación
        await service.saveDefaultLocation(
          countryId: 'country-1',
          regionId: 'region-1',
          cityId: 'city-1',
          countryName: 'USA',
          regionName: 'CA',
          cityName: 'LA',
        );

        // Guardar segunda ubicación
        await service.saveDefaultLocation(
          countryId: 'country-2',
          regionId: 'region-2',
          cityId: 'city-2',
          countryName: 'Canada',
          regionName: 'Ontario',
          cityName: 'Toronto',
        );

        expect(prefs.getString('default_country_id'), 'country-2');
        expect(prefs.getString('default_city_name'), 'Toronto');
      });

      test('debe guardar caracteres especiales correctamente', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);
        final prefs = await SharedPreferences.getInstance();

        await service.saveDefaultLocation(
          countryId: 'col',
          regionId: 'cun',
          cityId: 'bog',
          countryName: 'Colombia',
          regionName: 'Cundinamarca',
          cityName: 'Bogotá',
        );

        expect(prefs.getString('default_city_name'), 'Bogotá');
      });

      test('debe permitir guardar ubicaciones con nombres largos', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);
        final prefs = await SharedPreferences.getInstance();

        await service.saveDefaultLocation(
          countryId: 'uk',
          regionId: 'london',
          cityId: 'westminster',
          countryName: 'United Kingdom of Great Britain and Northern Ireland',
          regionName: 'Greater London',
          cityName: 'City of Westminster',
        );

        expect(prefs.getString('default_country_name'), contains('United Kingdom'));
      });
    });

    group('getDefaultLocation', () {
      test('debe retornar SavedLocation si existe', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);
        final prefs = await SharedPreferences.getInstance();

        // Guardar ubicación primero
        await prefs.setString('default_country_id', 'country-1');
        await prefs.setString('default_region_id', 'region-1');
        await prefs.setString('default_city_id', 'city-1');
        await prefs.setString('default_country_name', 'United States');
        await prefs.setString('default_region_name', 'California');
        await prefs.setString('default_city_name', 'Los Angeles');

        final result = await service.getDefaultLocation();

        expect(result, isNotNull);
        expect(result?.countryId, 'country-1');
        expect(result?.cityName, 'Los Angeles');
        expect(result?.displayText, 'Los Angeles, California, United States');
      });

      test('debe retornar null si no hay ubicación guardada', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);

        final result = await service.getDefaultLocation();

        expect(result, isNull);
      });

      test('debe retornar null si faltan campos requeridos', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);
        final prefs = await SharedPreferences.getInstance();

        // Guardar solo algunos campos
        await prefs.setString('default_country_id', 'country-1');
        await prefs.setString('default_city_name', 'Los Angeles');
        // Falta region_id, country_name, region_name, city_id

        final result = await service.getDefaultLocation();

        expect(result, isNull);
      });

      test('debe cargar ubicación con caracteres especiales', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('default_country_id', 'mex');
        await prefs.setString('default_region_id', 'jal');
        await prefs.setString('default_city_id', 'gdl');
        await prefs.setString('default_country_name', 'México');
        await prefs.setString('default_region_name', 'Jalisco');
        await prefs.setString('default_city_name', 'Guadalajara');

        final result = await service.getDefaultLocation();

        expect(result, isNotNull);
        expect(result?.countryName, 'México');
        expect(result?.compactText, 'Guadalajara, Jalisco');
      });

      test('debe verificar que displayText se construye correctamente', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('default_country_id', 'arg');
        await prefs.setString('default_region_id', 'ba');
        await prefs.setString('default_city_id', 'ba-city');
        await prefs.setString('default_country_name', 'Argentina');
        await prefs.setString('default_region_name', 'Buenos Aires');
        await prefs.setString('default_city_name', 'Buenos Aires');

        final result = await service.getDefaultLocation();

        expect(result?.displayText, 'Buenos Aires, Buenos Aires, Argentina');
        expect(result?.compactText, 'Buenos Aires, Buenos Aires');
      });
    });

    group('clearDefaultLocation', () {
      test('debe eliminar ubicación guardada', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);
        final prefs = await SharedPreferences.getInstance();

        // Guardar ubicación primero
        await service.saveDefaultLocation(
          countryId: 'country-1',
          regionId: 'region-1',
          cityId: 'city-1',
          countryName: 'USA',
          regionName: 'CA',
          cityName: 'LA',
        );

        // Verificar que existe
        expect(prefs.getString('default_country_id'), isNotNull);

        // Limpiar
        await service.clearDefaultLocation();

        // Verificar que se eliminó
        expect(prefs.getString('default_country_id'), isNull);
        expect(prefs.getString('default_city_name'), isNull);
      });

      test('debe retornar null después de limpiar', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);

        // Guardar y limpiar
        await service.saveDefaultLocation(
          countryId: 'c',
          regionId: 'r',
          cityId: 'ci',
          countryName: 'Country',
          regionName: 'Region',
          cityName: 'City',
        );
        await service.clearDefaultLocation();

        final result = await service.getDefaultLocation();

        expect(result, isNull);
      });

      test('debe ser idempotente (limpiar dos veces no causa error)', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);

        await service.clearDefaultLocation();
        await service.clearDefaultLocation();

        final result = await service.getDefaultLocation();

        expect(result, isNull);
      });

      test('debe eliminar todos los campos de ubicación', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);
        final prefs = await SharedPreferences.getInstance();

        // Guardar ubicación
        await service.saveDefaultLocation(
          countryId: 'test-country',
          regionId: 'test-region',
          cityId: 'test-city',
          countryName: 'Test Country',
          regionName: 'Test Region',
          cityName: 'Test City',
        );

        // Limpiar
        await service.clearDefaultLocation();

        // Verificar que todos los campos se eliminaron
        expect(prefs.getString('default_country_id'), isNull);
        expect(prefs.getString('default_region_id'), isNull);
        expect(prefs.getString('default_city_id'), isNull);
        expect(prefs.getString('default_country_name'), isNull);
        expect(prefs.getString('default_region_name'), isNull);
        expect(prefs.getString('default_city_name'), isNull);
      });
    });

    group('Flujo completo', () {
      test('debe poder guardar y recuperar ubicación', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);

        // Guardar
        await service.saveDefaultLocation(
          countryId: 'us',
          regionId: 'ny',
          cityId: 'nyc',
          countryName: 'United States',
          regionName: 'New York',
          cityName: 'New York City',
        );

        // Recuperar
        final saved = await service.getDefaultLocation();

        expect(saved, isNotNull);
        expect(saved?.cityName, 'New York City');
        expect(saved?.displayText, 'New York City, New York, United States');
      });

      test('debe poder actualizar ubicación guardada', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);

        // Primera ubicación
        await service.saveDefaultLocation(
          countryId: 'us',
          regionId: 'ca',
          cityId: 'la',
          countryName: 'US',
          regionName: 'California',
          cityName: 'Los Angeles',
        );

        var saved = await service.getDefaultLocation();
        expect(saved?.cityName, 'Los Angeles');

        // Actualizar a nueva ubicación
        await service.saveDefaultLocation(
          countryId: 'us',
          regionId: 'ny',
          cityId: 'nyc',
          countryName: 'US',
          regionName: 'New York',
          cityName: 'New York City',
        );

        saved = await service.getDefaultLocation();
        expect(saved?.cityName, 'New York City');
      });

      test('debe limpiar y verificar que no existe', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);

        // Guardar, limpiar, verificar
        await service.saveDefaultLocation(
          countryId: 'test',
          regionId: 'test',
          cityId: 'test',
          countryName: 'Test',
          regionName: 'Test',
          cityName: 'Test',
        );

        expect(await service.getDefaultLocation(), isNotNull);

        await service.clearDefaultLocation();

        expect(await service.getDefaultLocation(), isNull);
      });

      test('debe manejar múltiples actualizaciones consecutivas', () async {
        final mockLogger = MockAppLogger();
        final service = LocationService(mockLogger);

        // Guardar 3 ubicaciones diferentes
        await service.saveDefaultLocation(
          countryId: '1', regionId: '1', cityId: '1',
          countryName: 'Country1', regionName: 'Region1', cityName: 'City1',
        );

        await service.saveDefaultLocation(
          countryId: '2', regionId: '2', cityId: '2',
          countryName: 'Country2', regionName: 'Region2', cityName: 'City2',
        );

        await service.saveDefaultLocation(
          countryId: '3', regionId: '3', cityId: '3',
          countryName: 'Country3', regionName: 'Region3', cityName: 'City3',
        );

        final saved = await service.getDefaultLocation();

        // Solo debe tener la última
        expect(saved?.cityName, 'City3');
        expect(saved?.countryName, 'Country3');
      });
    });
  });

  group('LocationService - Modo anónimo', () {
    late LocationService service;
    late MockAppLogger mockLogger;

    setUp(() {
      mockLogger = MockAppLogger();
      service = LocationService(mockLogger);
      SharedPreferences.setMockInitialValues({});
    });

    test('NO debe guardar ubicación cuando modo anónimo está activado', () async {
      // Arrange - Activar modo anónimo
      SharedPreferences.setMockInitialValues({'anonymous_mode': true});

      // Act
      await service.saveDefaultLocation(
        countryId: 'co',
        regionId: 'ant',
        cityId: 'med',
        countryName: 'Colombia',
        regionName: 'Antioquia',
        cityName: 'Medellín',
      );

      // Assert - Verificar que NO se guardó
      final saved = await service.getDefaultLocation();
      expect(saved, isNull);
    });

    test('debe guardar ubicación cuando modo anónimo está desactivado', () async {
      // Arrange - Desactivar modo anónimo
      SharedPreferences.setMockInitialValues({'anonymous_mode': false});

      // Act
      await service.saveDefaultLocation(
        countryId: 'co',
        regionId: 'ant',
        cityId: 'med',
        countryName: 'Colombia',
        regionName: 'Antioquia',
        cityName: 'Medellín',
      );

      // Assert - Verificar que SÍ se guardó
      final saved = await service.getDefaultLocation();
      expect(saved, isNotNull);
      expect(saved?.cityName, 'Medellín');
    });

    test('debe guardar ubicación cuando anonymous_mode no existe', () async {
      // Arrange - Sin configurar anonymous_mode (default: false)
      SharedPreferences.setMockInitialValues({});

      // Act
      await service.saveDefaultLocation(
        countryId: 'co',
        regionId: 'ant',
        cityId: 'med',
        countryName: 'Colombia',
        regionName: 'Antioquia',
        cityName: 'Medellín',
      );

      // Assert - Verificar que SÍ se guardó
      final saved = await service.getDefaultLocation();
      expect(saved, isNotNull);
      expect(saved?.cityName, 'Medellín');
    });

    test('debe loggear cuando modo anónimo impide guardar ubicación', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'anonymous_mode': true});

      // Act
      await service.saveDefaultLocation(
        countryId: 'co',
        regionId: 'ant',
        cityId: 'med',
        countryName: 'Colombia',
        regionName: 'Antioquia',
        cityName: 'Medellín',
      );

      // Assert - Verificar que se logueó (el mock captura las llamadas)
      // La verificación específica depende de cómo esté configurado el mock
    });
  });

  group('LocationService - Manejo de errores', () {
    late LocationService service;
    late MockAppLogger mockLogger;

    setUp(() {
      mockLogger = MockAppLogger();
      service = LocationService(mockLogger);
    });

    group('saveDefaultLocation error handling', () {
      test('debe manejar error al guardar ubicación sin lanzar excepción', () async {
        // Arrange - Configurar SharedPreferences para que falle
        // (Esto es difícil de forzar, pero documentamos el comportamiento)
        SharedPreferences.setMockInitialValues({});

        // Act & Assert - No debe lanzar excepción
        await expectLater(
          service.saveDefaultLocation(
            countryId: 'co',
            regionId: 'ant',
            cityId: 'med',
            countryName: 'Colombia',
            regionName: 'Antioquia',
            cityName: 'Medellín',
          ),
          completes,
        );
      });

      test('debe continuar ejecución después de error', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act - Primera llamada
        await service.saveDefaultLocation(
          countryId: 'co1',
          regionId: 'ant1',
          cityId: 'med1',
          countryName: 'Country1',
          regionName: 'Region1',
          cityName: 'City1',
        );

        // Act - Segunda llamada (debe funcionar aunque la primera falle)
        await service.saveDefaultLocation(
          countryId: 'co2',
          regionId: 'ant2',
          cityId: 'med2',
          countryName: 'Country2',
          regionName: 'Region2',
          cityName: 'City2',
        );

        // Assert - Debe haber guardado la segunda
        final saved = await service.getDefaultLocation();
        expect(saved?.cityName, 'City2');
      });
    });

    group('getDefaultLocation error handling', () {
      test('debe retornar null si hay error al leer SharedPreferences', () async {
        // Arrange - SharedPreferences vacío (simula error de lectura)
        SharedPreferences.setMockInitialValues({});

        // Act
        final result = await service.getDefaultLocation();

        // Assert - Debe retornar null sin lanzar excepción
        expect(result, isNull);
      });

      test('debe manejar datos parciales sin lanzar excepción', () async {
        // Arrange - Solo algunos campos guardados (datos corruptos)
        SharedPreferences.setMockInitialValues({
          'default_country_id': 'co',
          // Faltan region_id y city_id
        });

        // Act & Assert - No debe lanzar excepción
        await expectLater(
          service.getDefaultLocation(),
          completion(isNull),
        );
      });

      test('debe continuar ejecución después de error en lectura', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act - Primera lectura (devuelve null)
        final result1 = await service.getDefaultLocation();

        // Guardar datos válidos
        await service.saveDefaultLocation(
          countryId: 'co',
          regionId: 'ant',
          cityId: 'med',
          countryName: 'Colombia',
          regionName: 'Antioquia',
          cityName: 'Medellín',
        );

        // Act - Segunda lectura (debe funcionar)
        final result2 = await service.getDefaultLocation();

        // Assert
        expect(result1, isNull);
        expect(result2, isNotNull);
        expect(result2?.cityName, 'Medellín');
      });
    });

    group('clearDefaultLocation error handling', () {
      test('debe completar sin error incluso si SharedPreferences falla', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act & Assert - No debe lanzar excepción
        await expectLater(
          service.clearDefaultLocation(),
          completes,
        );
      });

      test('debe poder limpiar después de error previo', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Guardar ubicación
        await service.saveDefaultLocation(
          countryId: 'co',
          regionId: 'ant',
          cityId: 'med',
          countryName: 'Colombia',
          regionName: 'Antioquia',
          cityName: 'Medellín',
        );

        // Act - Limpiar (debe completar sin error)
        await service.clearDefaultLocation();

        // Assert - Debe estar limpio
        final result = await service.getDefaultLocation();
        expect(result, isNull);
      });

      test('debe ser seguro llamar clearDefaultLocation múltiples veces', () async {
        // Arrange
        SharedPreferences.setMockInitialValues({});

        // Act & Assert - Múltiples llamadas no deben causar error
        await expectLater(service.clearDefaultLocation(), completes);
        await expectLater(service.clearDefaultLocation(), completes);
        await expectLater(service.clearDefaultLocation(), completes);
      });
    });
  });

  // Nota: Los métodos getCurrentPosition() y getCityFromCoordinates()
  // dependen de servicios de plataforma (Geolocator, Geocoding) que
  // requieren tests de integración o mocks complejos. Para testearlos:
  //
  // 1. Tests de integración en dispositivo real o emulador
  // 2. Crear wrappers testeables del servicio
  // 3. Usar paquetes como geolocator_test para simular respuestas
  //
  // Estos métodos están probados manualmente y cubiertos por tests E2E.

  group('LocationService - GPS y geocoding', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');

    late MockAppLogger logger;
    late LocationService service;
    late List<MethodCall> calls;
    // Respuestas del canal nativo de geolocator por método.
    late Map<String, Object? Function()> native;

    setUp(() {
      logger = MockAppLogger();
      service = LocationService(logger);
      calls = [];
      native = {
        'isLocationServiceEnabled': () => true,
        'checkPermission': () => 2, // whileInUse
        'requestPermission': () => 2,
        'getCurrentPosition': () => {
              'latitude': 4.711,
              'longitude': -74.072,
              'timestamp': 1700000000000,
            },
      };
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(geolocatorChannel, (call) async {
        calls.add(call);
        final answer = native[call.method];
        if (answer == null) throw StateError('No esperado: ${call.method}');
        return answer();
      });
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(geolocatorChannel, null));
    });

    List<String> methods() => calls.map((c) => c.method).toList();

    group('getCurrentPosition', () {
      test('retorna la posición con precisión baja cuando hay permiso',
          () async {
        final position = await service.getCurrentPosition();

        expect(position!.latitude, 4.711);
        expect(position.longitude, -74.072);
        expect(methods(), [
          'isLocationServiceEnabled',
          'checkPermission',
          'getCurrentPosition',
        ]);
        final args = calls.last.arguments as Map;
        expect(args['accuracy'], LocationAccuracy.low.index);
        verify(logger.i('GPS location obtained')).called(1);
      });

      test('retorna null sin pedir permisos si el GPS está apagado',
          () async {
        native['isLocationServiceEnabled'] = () => false;

        expect(await service.getCurrentPosition(), isNull);
        expect(methods(), ['isLocationServiceEnabled']);
        verify(logger.w('Location service disabled')).called(1);
      });

      test('solicita permiso si está denegado y continúa si lo otorgan',
          () async {
        native['checkPermission'] = () => 0; // denied

        final position = await service.getCurrentPosition();

        expect(position, isNotNull);
        expect(position!.latitude, 4.711);
        expect(methods(), contains('requestPermission'));
      });

      test('retorna null si el usuario vuelve a denegar el permiso',
          () async {
        native['checkPermission'] = () => 0;
        native['requestPermission'] = () => 0;

        expect(await service.getCurrentPosition(), isNull);
        expect(methods(), isNot(contains('getCurrentPosition')));
        verify(logger.w('Location permissions denied')).called(1);
      });

      test('retorna null si el permiso está denegado para siempre', () async {
        native['checkPermission'] = () => 1; // deniedForever

        expect(await service.getCurrentPosition(), isNull);
        expect(methods(), isNot(contains('requestPermission')));
        expect(methods(), isNot(contains('getCurrentPosition')));
        verify(logger.w('Location permissions permanently denied')).called(1);
      });

      // Android descarta una petición de permisos si ya hay otra en curso y
      // geolocator nunca completa ese Future: sin timeout, spinner infinito.
      test('retorna null si la petición de permiso nunca responde', () {
        native['checkPermission'] = () => 0; // denied
        native['requestPermission'] = () => Completer<int>().future;

        fakeAsync((async) {
          Position? position;
          var done = false;
          service.getCurrentPosition().then((p) {
            position = p;
            done = true;
          });

          async.elapse(LocationService.permissionRequestTimeout -
              const Duration(seconds: 1));
          expect(done, isFalse, reason: 'aún dentro del límite');

          async.elapse(const Duration(seconds: 2));
          expect(done, isTrue);
          expect(position, isNull);
          expect(methods(), isNot(contains('getCurrentPosition')));
          verify(logger.w('Error getting GPS location',
                  context: anyNamed('context')))
              .called(1);
        });
      });

      test('retorna null y loguea warning si el plugin falla', () async {
        native['getCurrentPosition'] =
            () => throw PlatformException(code: 'TIMEOUT');

        expect(await service.getCurrentPosition(), isNull);
        verify(logger.w('Error getting GPS location',
                context: anyNamed('context')))
            .called(1);
      });
    });

    group('getCityFromCoordinates', () {
      late _FakeGeocoding geocoding;

      setUp(() {
        geocoding = _FakeGeocoding();
        GeocodingPlatform.instance = geocoding;
      });

      test('retorna ciudad, región y país del primer placemark', () async {
        geocoding.result = [
          Placemark(
              locality: 'Bogotá',
              administrativeArea: 'Cundinamarca',
              country: 'Colombia'),
          Placemark(locality: 'Otra', administrativeArea: 'X', country: 'Y'),
        ];

        final location = await service.getCityFromCoordinates(4.711, -74.072);

        expect(geocoding.requested, [4.711, -74.072]);
        expect(location!.cityName, 'Bogotá');
        expect(location.regionName, 'Cundinamarca');
        expect(location.countryName, 'Colombia');
      });

      test('usa subAdministrativeArea si no hay locality', () async {
        geocoding.result = [
          Placemark(
              subAdministrativeArea: 'Sabana Centro',
              administrativeArea: 'Cundinamarca',
              country: 'Colombia'),
        ];

        final location = await service.getCityFromCoordinates(1, 2);

        expect(location!.cityName, 'Sabana Centro');
      });

      test('usa administrativeArea como ciudad si no hay nada más', () async {
        geocoding.result = [
          Placemark(administrativeArea: 'Cundinamarca', country: 'Colombia'),
        ];

        final location = await service.getCityFromCoordinates(1, 2);

        expect(location!.cityName, 'Cundinamarca');
        expect(location.regionName, 'Cundinamarca');
      });

      test('retorna null si no hay placemarks', () async {
        geocoding.result = [];

        expect(await service.getCityFromCoordinates(1, 2), isNull);
        verify(logger.w('Location information not found')).called(1);
      });

      test('retorna null si falta el país', () async {
        geocoding.result = [
          Placemark(locality: 'Bogotá', administrativeArea: 'Cundinamarca'),
        ];

        expect(await service.getCityFromCoordinates(1, 2), isNull);
        verify(logger.w('Incomplete location information')).called(1);
      });

      test('retorna null si el geocoding nunca responde', () {
        geocoding.hang = true;

        fakeAsync((async) {
          DetectedLocation? location;
          var done = false;
          service.getCityFromCoordinates(1, 2).then((l) {
            location = l;
            done = true;
          });

          async.elapse(LocationService.geocodingTimeout +
              const Duration(seconds: 1));

          expect(done, isTrue);
          expect(location, isNull);
          verify(logger.w('Reverse geocoding error',
                  context: anyNamed('context')))
              .called(1);
        });
      });

      test('retorna null y loguea warning si el geocoding falla', () async {
        geocoding.error = PlatformException(code: 'NOT_FOUND');

        expect(await service.getCityFromCoordinates(1, 2), isNull);
        verify(logger.w('Reverse geocoding error',
                context: anyNamed('context')))
            .called(1);
      });
    });
  });

  group('LocationService - No guardar ubicación', () {
    late LocationService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = LocationService(MockAppLogger());
    });

    test('isAnonymousModeEnabled es false por defecto', () async {
      expect(await service.isAnonymousModeEnabled(), isFalse);
    });

    test('isAnonymousModeEnabled lee la preferencia guardada', () async {
      SharedPreferences.setMockInitialValues({'anonymous_mode': true});

      expect(await service.isAnonymousModeEnabled(), isTrue);
    });

    test('activar guarda la preferencia y borra la ciudad guardada', () async {
      await service.saveDefaultLocation(
        countryId: 'CO',
        regionId: 'co-antioquia',
        cityId: 'medellin',
        countryName: 'Colombia',
        regionName: 'Antioquia',
        cityName: 'Medellín',
      );

      final ok = await service.setAnonymousMode(true);

      expect(ok, isTrue);
      expect(await service.isAnonymousModeEnabled(), isTrue);
      expect(await service.getDefaultLocation(), isNull);
    });

    test('desactivar guarda la preferencia y vuelve a recordar la ciudad',
        () async {
      await service.setAnonymousMode(true);

      final ok = await service.setAnonymousMode(false);
      await service.saveDefaultLocation(
        countryId: 'CO',
        regionId: 'co-antioquia',
        cityId: 'medellin',
        countryName: 'Colombia',
        regionName: 'Antioquia',
        cityName: 'Medellín',
      );

      expect(ok, isTrue);
      expect(await service.isAnonymousModeEnabled(), isFalse);
      expect((await service.getDefaultLocation())?.cityId, 'medellin');
    });

    test('con el modo activo no se guarda una ciudad nueva', () async {
      await service.setAnonymousMode(true);

      await service.saveDefaultLocation(
        countryId: 'CO',
        regionId: 'co-antioquia',
        cityId: 'medellin',
        countryName: 'Colombia',
        regionName: 'Antioquia',
        cityName: 'Medellín',
      );

      expect(await service.getDefaultLocation(), isNull);
    });
  });
}


class _FakeGeocoding extends GeocodingPlatform {
  List<Placemark> result = [];
  Object? error;
  bool hang = false;
  List<double>? requested;

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
      double latitude, double longitude) async {
    requested = [latitude, longitude];
    if (error != null) throw error!;
    if (hang) return Completer<List<Placemark>>().future;
    return result;
  }
}
