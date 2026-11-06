import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/presentation/states/add_gossip_state.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';

void main() {
  group('AddGossipState - copyWith', () {
    test('debe actualizar countries correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');
      final newCountries = [
        const Country(id: '1', code: 'CO', name: 'Colombia'),
        const Country(id: '2', code: 'AR', name: 'Argentina'),
      ];

      // Act
      final newState = initialState.copyWith(countries: newCountries);

      // Assert
      expect(newState.countries, equals(newCountries));
      expect(newState.regions, equals(initialState.regions));
      expect(newState.cities, equals(initialState.cities));
    });

    test('debe actualizar regions correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');
      final newRegions = [
        const Region(id: 'ant', name: 'Antioquia', countryId: '1', type: 'department'),
        const Region(id: 'cun', name: 'Cundinamarca', countryId: '1', type: 'department'),
      ];

      // Act
      final newState = initialState.copyWith(regions: newRegions);

      // Assert
      expect(newState.regions, equals(newRegions));
      expect(newState.countries, equals(initialState.countries));
      expect(newState.cities, equals(initialState.cities));
    });

    test('debe actualizar cities correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');
      final newCities = [
        const City(id: 'med', name: 'Medellín', regionId: 'ant'),
        const City(id: 'bog', name: 'Bogotá', regionId: 'cun'),
      ];

      // Act
      final newState = initialState.copyWith(cities: newCities);

      // Assert
      expect(newState.cities, equals(newCities));
      expect(newState.countries, equals(initialState.countries));
      expect(newState.regions, equals(initialState.regions));
    });

    test('debe actualizar selectedCountryId correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(selectedCountryId: '1');

      // Assert
      expect(newState.selectedCountryId, '1');
      expect(newState.selectedRegionId, isNull);
      expect(newState.selectedCityId, isNull);
    });

    test('debe actualizar selectedRegionId correctamente', () {
      // Arrange
      const initialState = AddGossipState(selectedCountryId: '1', idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(selectedRegionId: 'ant');

      // Assert
      expect(newState.selectedRegionId, 'ant');
      expect(newState.selectedCountryId, '1');
      expect(newState.selectedCityId, isNull);
    });

    test('debe actualizar selectedCityId correctamente', () {
      // Arrange
      const initialState = AddGossipState(
        idempotencyKey: 'test-key',
        selectedCountryId: '1',
        selectedRegionId: 'ant',
      );

      // Act
      final newState = initialState.copyWith(selectedCityId: 'med');

      // Assert
      expect(newState.selectedCityId, 'med');
      expect(newState.selectedCountryId, '1');
      expect(newState.selectedRegionId, 'ant');
    });

    test('debe actualizar publishedAs correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(publishedAs: PublishAs.profile);

      // Assert
      expect(newState.publishedAs, PublishAs.profile);
      expect(newState.subject, initialState.subject);
      expect(newState.content, initialState.content);
    });

    test('debe actualizar subject correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(subject: 'Nuevo subject');

      // Assert
      expect(newState.subject, 'Nuevo subject');
      expect(newState.content, initialState.content);
      expect(newState.publishedAs, initialState.publishedAs);
    });

    test('debe actualizar content correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(content: 'Nuevo content');

      // Assert
      expect(newState.content, 'Nuevo content');
      expect(newState.subject, initialState.subject);
      expect(newState.publishedAs, initialState.publishedAs);
    });

    test('debe actualizar audioUrl correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(audioUrl: 'https://example.com/audio.mp3');

      // Assert
      expect(newState.audioUrl, 'https://example.com/audio.mp3');
      expect(newState.imageUrl, isNull);
    });

    test('debe actualizar imageUrl correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(imageUrl: 'https://example.com/image.jpg');

      // Assert
      expect(newState.imageUrl, 'https://example.com/image.jpg');
      expect(newState.audioUrl, isNull);
    });

    test('debe actualizar isLoadingCountries correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(isLoadingCountries: true);

      // Assert
      expect(newState.isLoadingCountries, isTrue);
      expect(newState.isLoadingRegions, isFalse);
      expect(newState.isLoadingCities, isFalse);
      expect(newState.isSubmitting, isFalse);
    });

    test('debe actualizar isLoadingRegions correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(isLoadingRegions: true);

      // Assert
      expect(newState.isLoadingRegions, isTrue);
      expect(newState.isLoadingCountries, isFalse);
      expect(newState.isLoadingCities, isFalse);
      expect(newState.isSubmitting, isFalse);
    });

    test('debe actualizar isLoadingCities correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(isLoadingCities: true);

      // Assert
      expect(newState.isLoadingCities, isTrue);
      expect(newState.isLoadingCountries, isFalse);
      expect(newState.isLoadingRegions, isFalse);
      expect(newState.isSubmitting, isFalse);
    });

    test('debe actualizar isSubmitting correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(isSubmitting: true);

      // Assert
      expect(newState.isSubmitting, isTrue);
      expect(newState.isLoadingCountries, isFalse);
      expect(newState.isLoadingRegions, isFalse);
      expect(newState.isLoadingCities, isFalse);
    });

    test('debe actualizar isUploadingImage correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(isUploadingImage: true);

      // Assert
      expect(newState.isUploadingImage, isTrue);
      expect(newState.isSubmitting, isFalse);
    });

    test('debe actualizar failure correctamente', () {
      // Arrange
      const initialState = AddGossipState(idempotencyKey: 'test-key');
      const failure = NetworkFailure(code: ErrorCode.networkError);

      // Act
      final newState = initialState.copyWith(failure: failure);

      // Assert
      expect(newState.failure, equals(failure));
      expect(newState.hasError, isTrue);
    });

    test('debe mantener otros campos sin cambiar al actualizar uno solo', () {
      // Arrange
      const initialState = AddGossipState(
        idempotencyKey: 'test-key',
        subject: 'Subject original',
        content: 'Content original',
        selectedCountryId: '1',
        publishedAs: PublishAs.anonymous,
      );

      // Act - Solo actualizar content
      final newState = initialState.copyWith(content: 'Content nuevo');

      // Assert - Los demás campos deben mantenerse igual
      expect(newState.content, 'Content nuevo');
      expect(newState.subject, 'Subject original');
      expect(newState.selectedCountryId, '1');
      expect(newState.publishedAs, PublishAs.anonymous);
    });

    test('debe poder establecer selectedCountryId a null usando _unset', () {
      // Arrange
      const initialState = AddGossipState(selectedCountryId: '1', idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(selectedCountryId: null);

      // Assert
      expect(newState.selectedCountryId, isNull);
    });

    test('debe poder establecer selectedRegionId a null usando _unset', () {
      // Arrange
      const initialState = AddGossipState(selectedRegionId: 'ant', idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(selectedRegionId: null);

      // Assert
      expect(newState.selectedRegionId, isNull);
    });

    test('debe poder establecer selectedCityId a null usando _unset', () {
      // Arrange
      const initialState = AddGossipState(selectedCityId: 'med', idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(selectedCityId: null);

      // Assert
      expect(newState.selectedCityId, isNull);
    });

    test('debe poder establecer audioUrl a null usando _unset', () {
      // Arrange
      const initialState = AddGossipState(audioUrl: 'https://example.com/audio.mp3', idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(audioUrl: null);

      // Assert
      expect(newState.audioUrl, isNull);
    });

    test('debe poder establecer imageUrl a null usando _unset', () {
      // Arrange
      const initialState = AddGossipState(imageUrl: 'https://example.com/image.jpg', idempotencyKey: 'test-key');

      // Act
      final newState = initialState.copyWith(imageUrl: null);

      // Assert
      expect(newState.imageUrl, isNull);
    });

    test('debe poder establecer failure a null usando _unset', () {
      // Arrange
      const initialState = AddGossipState(
        idempotencyKey: 'test-key',
        failure: NetworkFailure(code: ErrorCode.networkError),
      );

      // Act
      final newState = initialState.copyWith(failure: null);

      // Assert
      expect(newState.failure, isNull);
      expect(newState.hasError, isFalse);
    });
  });

  group('AddGossipState - clearFailure', () {
    test('debe limpiar failure y mantener otros campos', () {
      // Arrange
      const initialState = AddGossipState(
        idempotencyKey: 'test-key',
        subject: 'Subject',
        content: 'Content',
        selectedCountryId: '1',
        selectedRegionId: 'ant',
        selectedCityId: 'med',
        publishedAs: PublishAs.profile,
        failure: NetworkFailure(code: ErrorCode.networkError),
      );

      // Act
      final newState = initialState.clearFailure();

      // Assert
      expect(newState.failure, isNull);
      expect(newState.hasError, isFalse);
      expect(newState.subject, 'Subject');
      expect(newState.content, 'Content');
      expect(newState.selectedCountryId, '1');
      expect(newState.selectedRegionId, 'ant');
      expect(newState.selectedCityId, 'med');
      expect(newState.publishedAs, PublishAs.profile);
    });

    test('clearFailure debe funcionar incluso si ya no hay failure', () {
      // Arrange
      const initialState = AddGossipState(subject: 'Subject', idempotencyKey: 'test-key');

      // Act
      final newState = initialState.clearFailure();

      // Assert
      expect(newState.failure, isNull);
      expect(newState.subject, 'Subject');
    });
  });

  group('AddGossipState - clearLocation', () {
    test('debe limpiar selectedRegionId y selectedCityId', () {
      // Arrange
      const initialState = AddGossipState(
        idempotencyKey: 'test-key',
        selectedCountryId: '1',
        selectedRegionId: 'ant',
        selectedCityId: 'med',
      );

      // Act
      final newState = initialState.clearLocation();

      // Assert
      expect(newState.selectedRegionId, isNull);
      expect(newState.selectedCityId, isNull);
      expect(newState.regions, isEmpty);
      expect(newState.cities, isEmpty);
    });

    test('debe mantener selectedCountryId al limpiar location', () {
      // Arrange
      const initialState = AddGossipState(
        idempotencyKey: 'test-key',
        selectedCountryId: '1',
        selectedRegionId: 'ant',
        selectedCityId: 'med',
      );

      // Act
      final newState = initialState.clearLocation();

      // Assert
      expect(newState.selectedCountryId, '1');
      expect(newState.selectedRegionId, isNull);
      expect(newState.selectedCityId, isNull);
    });

    test('debe limpiar listas de regions y cities', () {
      // Arrange
      final initialState = AddGossipState(
        idempotencyKey: 'test-key',
        selectedCountryId: '1',
        selectedRegionId: 'ant',
        selectedCityId: 'med',
        regions: const [
          Region(id: 'ant', name: 'Antioquia', countryId: '1', type: 'department'),
        ],
        cities: const [
          City(id: 'med', name: 'Medellín', regionId: 'ant'),
        ],
      );

      // Act
      final newState = initialState.clearLocation();

      // Assert
      expect(newState.regions, isEmpty);
      expect(newState.cities, isEmpty);
    });
  });

  group('AddGossipState - Equatable', () {
    test('dos estados con mismos valores deben ser iguales', () {
      // Arrange
      final state1 = AddGossipState(
        idempotencyKey: 'test-key',
        subject: 'Subject',
        content: 'Content',
        selectedCountryId: '1',
        selectedRegionId: 'ant',
        selectedCityId: 'med',
        publishedAs: PublishAs.anonymous,
        countries: const [
          Country(id: '1', code: 'CO', name: 'Colombia'),
        ],
        regions: const [
          Region(id: 'ant', name: 'Antioquia', countryId: '1', type: 'department'),
        ],
        cities: const [
          City(id: 'med', name: 'Medellín', regionId: 'ant'),
        ],
      );

      final state2 = AddGossipState(
        idempotencyKey: 'test-key',
        subject: 'Subject',
        content: 'Content',
        selectedCountryId: '1',
        selectedRegionId: 'ant',
        selectedCityId: 'med',
        publishedAs: PublishAs.anonymous,
        countries: const [
          Country(id: '1', code: 'CO', name: 'Colombia'),
        ],
        regions: const [
          Region(id: 'ant', name: 'Antioquia', countryId: '1', type: 'department'),
        ],
        cities: const [
          City(id: 'med', name: 'Medellín', regionId: 'ant'),
        ],
      );

      // Assert
      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('dos estados con valores diferentes deben ser distintos', () {
      // Arrange
      const state1 = AddGossipState(subject: 'Subject 1', idempotencyKey: 'test-key');
      const state2 = AddGossipState(subject: 'Subject 2', idempotencyKey: 'test-key');

      // Assert
      expect(state1, isNot(equals(state2)));
      expect(state1.hashCode, isNot(equals(state2.hashCode)));
    });

    test('props debe incluir todos los campos', () {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key');

      // Act
      final props = state.props;

      // Assert - Verificar que todos los campos están incluidos
      expect(props, hasLength(18)); // 18 campos en AddGossipState (17 campos + failure)
      expect(props, contains(state.countries));
      expect(props, contains(state.regions));
      expect(props, contains(state.cities));
      expect(props, contains(state.selectedCountryId));
      expect(props, contains(state.selectedRegionId));
      expect(props, contains(state.selectedCityId));
      expect(props, contains(state.publishedAs));
      expect(props, contains(state.subject));
      expect(props, contains(state.content));
      expect(props, contains(state.idempotencyKey));
      expect(props, contains(state.audioUrl));
      expect(props, contains(state.imageUrl));
      expect(props, contains(state.isLoadingCountries));
      expect(props, contains(state.isLoadingRegions));
      expect(props, contains(state.isLoadingCities));
      expect(props, contains(state.isSubmitting));
      expect(props, contains(state.isUploadingImage));
    });
  });

  group('AddGossipState - hasError', () {
    test('hasError debe retornar true cuando hay failure', () {
      // Arrange
      const state = AddGossipState(
        idempotencyKey: 'test-key',
        failure: NetworkFailure(code: ErrorCode.networkError),
      );

      // Assert
      expect(state.hasError, isTrue);
    });

    test('hasError debe retornar false cuando no hay failure', () {
      // Arrange
      const state = AddGossipState(idempotencyKey: 'test-key');

      // Assert
      expect(state.hasError, isFalse);
    });
  });

  group('AddGossipState - Estado Inicial', () {
    test('debe tener valores por defecto correctos', () {
      // Act
      const state = AddGossipState(idempotencyKey: 'test-key');

      // Assert
      expect(state.countries, isEmpty);
      expect(state.regions, isEmpty);
      expect(state.cities, isEmpty);
      expect(state.selectedCountryId, isNull);
      expect(state.selectedRegionId, isNull);
      expect(state.selectedCityId, isNull);
      expect(state.publishedAs, PublishAs.anonymous);
      expect(state.subject, isEmpty);
      expect(state.content, isEmpty);
      expect(state.audioUrl, isNull);
      expect(state.imageUrl, isNull);
      expect(state.isLoadingCountries, isFalse);
      expect(state.isLoadingRegions, isFalse);
      expect(state.isLoadingCities, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.isUploadingImage, isFalse);
      expect(state.failure, isNull);
      expect(state.hasError, isFalse);
    });
  });
}
