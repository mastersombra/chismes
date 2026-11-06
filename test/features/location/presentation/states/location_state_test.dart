import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/location/presentation/states/location_state.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';
import 'package:chismes/features/location/domain/entities/city.dart';

void main() {
  group('LocationState', () {
    group('initial', () {
      test('debe crear estado inicial vacío', () {
        // Act
        final state = LocationState.initial();

        // Assert
        expect(state.countries, isEmpty);
        expect(state.regions, isEmpty);
        expect(state.cities, isEmpty);
        expect(state.selectedCountry, isNull);
        expect(state.selectedRegion, isNull);
        expect(state.selectedCity, isNull);
        expect(state.isLoadingCountries, isFalse);
        expect(state.isLoadingRegions, isFalse);
        expect(state.isLoadingCities, isFalse);
        expect(state.isDetectingLocation, isFalse);
        expect(state.error, isNull);
      });
    });

    group('isValid', () {
      test('debe retornar true cuando tiene país, región y ciudad', () {
        // Arrange
        const country = Country(id: 'co', code: 'CO', name: 'Colombia');
        const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
        const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

        final state = LocationState.initial().copyWith(
          selectedCountry: country,
          selectedRegion: region,
          selectedCity: city,
        );

        // Act & Assert
        expect(state.isValid, isTrue);
      });

      test('debe retornar false cuando falta país', () {
        // Arrange
        const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
        const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

        final state = LocationState.initial().copyWith(
          selectedRegion: region,
          selectedCity: city,
        );

        // Act & Assert
        expect(state.isValid, isFalse);
      });

      test('debe retornar false cuando falta región', () {
        // Arrange
        const country = Country(id: 'co', code: 'CO', name: 'Colombia');
        const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

        final state = LocationState.initial().copyWith(
          selectedCountry: country,
          selectedCity: city,
        );

        // Act & Assert
        expect(state.isValid, isFalse);
      });

      test('debe retornar false cuando falta ciudad', () {
        // Arrange
        const country = Country(id: 'co', code: 'CO', name: 'Colombia');
        const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');

        final state = LocationState.initial().copyWith(
          selectedCountry: country,
          selectedRegion: region,
        );

        // Act & Assert
        expect(state.isValid, isFalse);
      });

      test('debe retornar false cuando está vacío', () {
        // Arrange
        final state = LocationState.initial();

        // Act & Assert
        expect(state.isValid, isFalse);
      });
    });

    group('isLoading', () {
      test('debe retornar true cuando isLoadingCountries es true', () {
        // Arrange
        final state = LocationState.initial().copyWith(
          isLoadingCountries: true,
        );

        // Act & Assert
        expect(state.isLoading, isTrue);
      });

      test('debe retornar true cuando isLoadingRegions es true', () {
        // Arrange
        final state = LocationState.initial().copyWith(
          isLoadingRegions: true,
        );

        // Act & Assert
        expect(state.isLoading, isTrue);
      });

      test('debe retornar true cuando isLoadingCities es true', () {
        // Arrange
        final state = LocationState.initial().copyWith(
          isLoadingCities: true,
        );

        // Act & Assert
        expect(state.isLoading, isTrue);
      });

      test('debe retornar true cuando isDetectingLocation es true', () {
        // Arrange
        final state = LocationState.initial().copyWith(
          isDetectingLocation: true,
        );

        // Act & Assert
        expect(state.isLoading, isTrue);
      });

      test('debe retornar false cuando ninguna carga está activa', () {
        // Arrange
        final state = LocationState.initial();

        // Act & Assert
        expect(state.isLoading, isFalse);
      });
    });

    group('copyWith', () {
      test('debe copiar con nuevos countries', () {
        // Arrange
        final state = LocationState.initial();
        const countries = [
          Country(id: 'co', code: 'CO', name: 'Colombia'),
          Country(id: 'ar', code: 'AR', name: 'Argentina'),
        ];

        // Act
        final newState = state.copyWith(countries: countries);

        // Assert
        expect(newState.countries, countries);
        expect(newState.regions, state.regions);
      });

      test('debe copiar con nuevas regions', () {
        // Arrange
        final state = LocationState.initial();
        const regions = [
          Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department'),
        ];

        // Act
        final newState = state.copyWith(regions: regions);

        // Assert
        expect(newState.regions, regions);
      });

      test('debe copiar con nuevas cities', () {
        // Arrange
        final state = LocationState.initial();
        const cities = [
          City(id: 'med', regionId: 'ant', name: 'Medellín'),
        ];

        // Act
        final newState = state.copyWith(cities: cities);

        // Assert
        expect(newState.cities, cities);
      });

      test('debe copiar con selectedCountry', () {
        // Arrange
        final state = LocationState.initial();
        const country = Country(id: 'co', code: 'CO', name: 'Colombia');

        // Act
        final newState = state.copyWith(selectedCountry: country);

        // Assert
        expect(newState.selectedCountry, country);
      });

      test('debe copiar con selectedRegion', () {
        // Arrange
        final state = LocationState.initial();
        const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');

        // Act
        final newState = state.copyWith(selectedRegion: region);

        // Assert
        expect(newState.selectedRegion, region);
      });

      test('debe copiar con selectedCity', () {
        // Arrange
        final state = LocationState.initial();
        const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

        // Act
        final newState = state.copyWith(selectedCity: city);

        // Assert
        expect(newState.selectedCity, city);
      });

      test('debe limpiar selectedCountry cuando clearSelectedCountry es true', () {
        // Arrange
        const country = Country(id: 'co', code: 'CO', name: 'Colombia');
        final state = LocationState.initial().copyWith(selectedCountry: country);

        // Act
        final newState = state.copyWith(clearSelectedCountry: true);

        // Assert
        expect(newState.selectedCountry, isNull);
      });

      test('debe limpiar selectedRegion cuando clearSelectedRegion es true', () {
        // Arrange
        const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
        final state = LocationState.initial().copyWith(selectedRegion: region);

        // Act
        final newState = state.copyWith(clearSelectedRegion: true);

        // Assert
        expect(newState.selectedRegion, isNull);
      });

      test('debe limpiar selectedCity cuando clearSelectedCity es true', () {
        // Arrange
        const city = City(id: 'med', regionId: 'ant', name: 'Medellín');
        final state = LocationState.initial().copyWith(selectedCity: city);

        // Act
        final newState = state.copyWith(clearSelectedCity: true);

        // Assert
        expect(newState.selectedCity, isNull);
      });

      test('debe copiar con isLoadingCountries', () {
        // Arrange
        final state = LocationState.initial();

        // Act
        final newState = state.copyWith(isLoadingCountries: true);

        // Assert
        expect(newState.isLoadingCountries, isTrue);
      });

      test('debe copiar con isLoadingRegions', () {
        // Arrange
        final state = LocationState.initial();

        // Act
        final newState = state.copyWith(isLoadingRegions: true);

        // Assert
        expect(newState.isLoadingRegions, isTrue);
      });

      test('debe copiar con isLoadingCities', () {
        // Arrange
        final state = LocationState.initial();

        // Act
        final newState = state.copyWith(isLoadingCities: true);

        // Assert
        expect(newState.isLoadingCities, isTrue);
      });

      test('debe copiar con isDetectingLocation', () {
        // Arrange
        final state = LocationState.initial();

        // Act
        final newState = state.copyWith(isDetectingLocation: true);

        // Assert
        expect(newState.isDetectingLocation, isTrue);
      });

      test('debe copiar con error', () {
        // Arrange
        final state = LocationState.initial();
        const errorMessage = 'Error de red';

        // Act
        final newState = state.copyWith(error: errorMessage);

        // Assert
        expect(newState.error, errorMessage);
      });

      test('debe limpiar error cuando clearError es true', () {
        // Arrange
        final state = LocationState.initial().copyWith(error: 'Error previo');

        // Act
        final newState = state.copyWith(clearError: true);

        // Assert
        expect(newState.error, isNull);
      });

      test('debe mantener valores originales cuando no se pasan parámetros', () {
        // Arrange
        const country = Country(id: 'co', code: 'CO', name: 'Colombia');
        final state = LocationState.initial().copyWith(
          selectedCountry: country,
          isLoadingCountries: true,
          error: 'Error',
        );

        // Act
        final newState = state.copyWith();

        // Assert
        expect(newState.selectedCountry, country);
        expect(newState.isLoadingCountries, isTrue);
        expect(newState.error, 'Error');
      });
    });

    group('Equatable', () {
      test('debe ser igual cuando todos los valores son iguales', () {
        // Arrange
        const country = Country(id: 'co', code: 'CO', name: 'Colombia');

        final state1 = LocationState.initial().copyWith(selectedCountry: country);
        final state2 = LocationState.initial().copyWith(selectedCountry: country);

        // Act & Assert
        expect(state1, equals(state2));
      });

      test('debe ser diferente cuando los valores son diferentes', () {
        // Arrange
        const country1 = Country(id: 'co', code: 'CO', name: 'Colombia');
        const country2 = Country(id: 'ar', code: 'AR', name: 'Argentina');

        final state1 = LocationState.initial().copyWith(selectedCountry: country1);
        final state2 = LocationState.initial().copyWith(selectedCountry: country2);

        // Act & Assert
        expect(state1, isNot(equals(state2)));
      });

      test('debe tener el mismo hashCode cuando son iguales', () {
        // Arrange
        const country = Country(id: 'co', code: 'CO', name: 'Colombia');

        final state1 = LocationState.initial().copyWith(selectedCountry: country);
        final state2 = LocationState.initial().copyWith(selectedCountry: country);

        // Act & Assert
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('debe incluir todos los campos en props', () {
        // Arrange
        final state = LocationState.initial();

        // Act
        final props = state.props;

        // Assert
        expect(props.length, 11); // 11 campos
        expect(props, contains(state.countries));
        expect(props, contains(state.regions));
        expect(props, contains(state.cities));
        expect(props, contains(state.selectedCountry));
        expect(props, contains(state.selectedRegion));
        expect(props, contains(state.selectedCity));
        expect(props, contains(state.isLoadingCountries));
        expect(props, contains(state.isLoadingRegions));
        expect(props, contains(state.isLoadingCities));
        expect(props, contains(state.isDetectingLocation));
        expect(props, contains(state.error));
      });
    });

    group('Constructor', () {
      test('debe crear estado con todos los parámetros', () {
        // Arrange
        const countries = [Country(id: 'co', code: 'CO', name: 'Colombia')];
        const regions = [Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department')];
        const cities = [City(id: 'med', regionId: 'ant', name: 'Medellín')];
        const country = Country(id: 'co', code: 'CO', name: 'Colombia');
        const region = Region(id: 'ant', countryId: 'co', name: 'Antioquia', type: 'department');
        const city = City(id: 'med', regionId: 'ant', name: 'Medellín');

        // Act
        const state = LocationState(
          countries: countries,
          regions: regions,
          cities: cities,
          selectedCountry: country,
          selectedRegion: region,
          selectedCity: city,
          isLoadingCountries: true,
          isLoadingRegions: true,
          isLoadingCities: true,
          isDetectingLocation: true,
          error: 'Error',
        );

        // Assert
        expect(state.countries, countries);
        expect(state.regions, regions);
        expect(state.cities, cities);
        expect(state.selectedCountry, country);
        expect(state.selectedRegion, region);
        expect(state.selectedCity, city);
        expect(state.isLoadingCountries, isTrue);
        expect(state.isLoadingRegions, isTrue);
        expect(state.isLoadingCities, isTrue);
        expect(state.isDetectingLocation, isTrue);
        expect(state.error, 'Error');
      });
    });
  });
}
