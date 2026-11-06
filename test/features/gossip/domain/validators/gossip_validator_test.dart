import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/domain/validators/gossip_validator.dart';
import 'package:chismes/features/gossip/domain/entities/create_gossip_input.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';

void main() {
  group('GossipValidator.validateInput', () {
    test('debe retornar null cuando el input es válido', () {
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final result = GossipValidator.validateInput(input);
      expect(result, isNull);
    });

    test('debe retornar error cuando subject está vacío', () {
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: '',
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final result = GossipValidator.validateInput(input);
      expect(result, isNotNull);
      expect(result, isA<ValidationFailure>());
      expect(result?.code, ErrorCode.missingRequiredField);
    });

    test('debe retornar error cuando subject excede longitud máxima', () {
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'a' * 201, // 201 caracteres (máximo es 200)
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final result = GossipValidator.validateInput(input);
      expect(result, isNotNull);
      expect(result, isA<ValidationFailure>());
      expect(result?.code, ErrorCode.invalidInput);
    });

    test('debe aceptar subject con longitud máxima exacta', () {
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'a' * 200, // 200 caracteres (máximo es 200)
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final result = GossipValidator.validateInput(input);
      expect(result, isNull);
    });

    test('debe retornar error cuando content está vacío', () {
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: '',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final result = GossipValidator.validateInput(input);
      expect(result, isNotNull);
      expect(result, isA<ValidationFailure>());
      expect(result?.code, ErrorCode.missingRequiredField);
    });

    test('debe retornar error cuando content excede longitud máxima', () {
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: 'a' * 1001, // 1001 caracteres (máximo es 1000)
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final result = GossipValidator.validateInput(input);
      expect(result, isNotNull);
      expect(result, isA<ValidationFailure>());
      expect(result?.code, ErrorCode.invalidInput);
    });

    test('debe aceptar content con longitud máxima exacta', () {
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: 'a' * 1000, // 1000 caracteres (máximo es 1000)
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final result = GossipValidator.validateInput(input);
      expect(result, isNull);
    });

    test('debe retornar error cuando countryId está vacío', () {
      final input = CreateGossipInput(
        countryId: '',
        regionId: '1',
        cityId: '1',
        subject: 'Tema válido',
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final result = GossipValidator.validateInput(input);
      expect(result, isNotNull);
      expect(result, isA<DataFailure>());
      expect(result?.code, ErrorCode.invalidLocation);
    });

    test('debe retornar error cuando regionId está vacío', () {
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '',
        cityId: '1',
        subject: 'Tema válido',
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final result = GossipValidator.validateInput(input);
      expect(result, isNotNull);
      expect(result, isA<DataFailure>());
      expect(result?.code, ErrorCode.invalidLocation);
    });

    test('debe retornar error cuando cityId está vacío', () {
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '',
        subject: 'Tema válido',
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final result = GossipValidator.validateInput(input);
      expect(result, isNotNull);
      expect(result, isA<DataFailure>());
      expect(result?.code, ErrorCode.invalidLocation);
    });

    test('debe retornar error cuando toda la ubicación está vacía', () {
      final input = CreateGossipInput(
        countryId: '',
        regionId: '',
        cityId: '',
        subject: 'Tema válido',
        content: 'Contenido válido',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final result = GossipValidator.validateInput(input);
      expect(result, isNotNull);
      expect(result, isA<DataFailure>());
      expect(result?.code, ErrorCode.invalidLocation);
    });
  });

  group('GossipValidator.validateLocationHierarchy', () {
    test('debe retornar null cuando la jerarquía es válida', () {
      final country = Country(id: '1', code: 'US', name: 'Country 1');
      final region = Region(id: '1', name: 'Region 1', countryId: '1', type: 'state');
      final city = City(id: '1', name: 'City 1', regionId: '1');

      final result = GossipValidator.validateLocationHierarchy(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        countries: [country],
        regions: [region],
        cities: [city],
      );

      expect(result, isNull);
    });

    test('debe retornar error cuando la región no pertenece al país', () {
      final country = Country(id: '1', code: 'US', name: 'Country 1');
      final region = Region(id: '1', name: 'Region 1', countryId: '2', type: 'state'); // countryId diferente
      final city = City(id: '1', name: 'City 1', regionId: '1');

      final result = GossipValidator.validateLocationHierarchy(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        countries: [country],
        regions: [region],
        cities: [city],
      );

      expect(result, isNotNull);
      expect(result, isA<DataFailure>());
      expect(result?.code, ErrorCode.invalidLocation);
    });

    test('debe retornar error cuando la ciudad no pertenece a la región', () {
      final country = Country(id: '1', code: 'US', name: 'Country 1');
      final region = Region(id: '1', name: 'Region 1', countryId: '1', type: 'state');
      final city = City(id: '1', name: 'City 1', regionId: '2'); // regionId diferente

      final result = GossipValidator.validateLocationHierarchy(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        countries: [country],
        regions: [region],
        cities: [city],
      );

      expect(result, isNotNull);
      expect(result, isA<DataFailure>());
      expect(result?.code, ErrorCode.invalidLocation);
    });

    test('debe retornar error cuando toda la jerarquía es inconsistente', () {
      final country = Country(id: '1', code: 'US', name: 'Country 1');
      final region = Region(id: '1', name: 'Region 1', countryId: '2', type: 'state');
      final city = City(id: '1', name: 'City 1', regionId: '3');

      final result = GossipValidator.validateLocationHierarchy(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        countries: [country],
        regions: [region],
        cities: [city],
      );

      expect(result, isNotNull);
      expect(result, isA<DataFailure>());
      expect(result?.code, ErrorCode.invalidLocation);
    });
  });

  group('GossipValidator.validateStatusCombination', () {
    test('debe aceptar draft + pending (creado, motor revisando)', () {
      // Act
      final result = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.draft,
        moderationStatus: ModerationStatus.pending,
      );

      // Assert
      expect(result, isNull);
    });

    test('debe aceptar draft + rejected (motor detectó problema)', () {
      // Act
      final result = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.draft,
        moderationStatus: ModerationStatus.rejected,
      );

      // Assert
      expect(result, isNull);
    });

    test('debe aceptar published + approved (publicado y aprobado)', () {
      // Act
      final result = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
      );

      // Assert
      expect(result, isNull);
    });

    test('debe aceptar hidden + flagged (reportado, oculto)', () {
      // Act
      final result = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.hidden,
        moderationStatus: ModerationStatus.flagged,
      );

      // Assert
      expect(result, isNull);
    });

    test('debe aceptar hidden + rejected (rechazado por moderación)', () {
      // Act
      final result = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.hidden,
        moderationStatus: ModerationStatus.rejected,
      );

      // Assert
      expect(result, isNull);
    });

    test('debe aceptar deleted + cualquier status de moderación', () {
      // Act & Assert
      final result1 = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.deleted,
        moderationStatus: ModerationStatus.pending,
      );
      expect(result1, isNull);

      final result2 = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.deleted,
        moderationStatus: ModerationStatus.approved,
      );
      expect(result2, isNull);

      final result3 = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.deleted,
        moderationStatus: ModerationStatus.flagged,
      );
      expect(result3, isNull);

      final result4 = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.deleted,
        moderationStatus: ModerationStatus.rejected,
      );
      expect(result4, isNull);
    });

    test('debe rechazar published + pending (inválida)', () {
      // Act
      final result = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.published,
        moderationStatus: ModerationStatus.pending,
      );

      // Assert
      expect(result, isNotNull);
      expect(result, isA<ValidationFailure>());
      expect(result?.code, ErrorCode.invalidInput);
    });

    test('debe rechazar published + rejected (inválida)', () {
      // Act
      final result = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.published,
        moderationStatus: ModerationStatus.rejected,
      );

      // Assert
      expect(result, isNotNull);
      expect(result, isA<ValidationFailure>());
    });

    test('debe rechazar draft + approved (inválida)', () {
      // Act
      final result = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.draft,
        moderationStatus: ModerationStatus.approved,
      );

      // Assert
      expect(result, isNotNull);
      expect(result, isA<ValidationFailure>());
    });

    test('debe rechazar draft + flagged (inválida)', () {
      // Act
      final result = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.draft,
        moderationStatus: ModerationStatus.flagged,
      );

      // Assert
      expect(result, isNotNull);
      expect(result, isA<ValidationFailure>());
    });

    test('debe rechazar hidden + pending (inválida)', () {
      // Act
      final result = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.hidden,
        moderationStatus: ModerationStatus.pending,
      );

      // Assert
      expect(result, isNotNull);
      expect(result, isA<ValidationFailure>());
    });

    test('debe rechazar hidden + approved (inválida)', () {
      // Act
      final result = GossipValidator.validateStatusCombination(
        gossipStatus: GossipStatus.hidden,
        moderationStatus: ModerationStatus.approved,
      );

      // Assert
      expect(result, isNotNull);
      expect(result, isA<ValidationFailure>());
    });
  });
}
