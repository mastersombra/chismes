import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/shared/data/gossip_mock_data.dart';

void main() {
  group('gossip_mock_data', () {
    test('debe contener 4 gossips de prueba', () {
      // Assert
      expect(mockGossips, hasLength(4));
    });

    test('cada gossip debe tener estructura válida', () {
      // Arrange & Act
      for (final gossip in mockGossips) {
        // Assert - Campos requeridos
        expect(gossip['id'], isNotNull);
        expect(gossip['countryId'], isNotNull);
        expect(gossip['regionId'], isNotNull);
        expect(gossip['cityId'], isNotNull);
        expect(gossip['subject'], isNotNull);
        expect(gossip['content'], isNotNull);
        expect(gossip['imageUrl'], isNotNull);
        expect(gossip['publishedAs'], isNotNull);
        expect(gossip['createdAt'], isNotNull);
        expect(gossip['createdBy'], isNotNull);

        // Assert - Tipos correctos
        expect(gossip['id'], isA<String>());
        expect(gossip['countryId'], isA<String>());
        expect(gossip['regionId'], isA<String>());
        expect(gossip['cityId'], isA<String>());
        expect(gossip['subject'], isA<String>());
        expect(gossip['content'], isA<String>());
        expect(gossip['imageUrl'], isA<String>());
        expect(gossip['publishedAs'], isA<String>());
        expect(gossip['createdAt'], isA<String>());
        expect(gossip['createdBy'], isA<String>());
      }
    });

    test('publishedAs debe ser "anonymous" o "profile"', () {
      // Arrange & Act
      final validValues = {'anonymous', 'profile'};

      for (final gossip in mockGossips) {
        // Assert
        expect(validValues.contains(gossip['publishedAs']), isTrue,
            reason: 'publishedAs debe ser "anonymous" o "profile", encontrado: ${gossip['publishedAs']}');
      }
    });

    test('imageUrl debe ser URL válida', () {
      // Arrange & Act
      for (final gossip in mockGossips) {
        final imageUrl = gossip['imageUrl'] as String;

        // Assert
        expect(Uri.tryParse(imageUrl)?.isAbsolute, isTrue,
            reason: 'imageUrl debe ser URL válida: $imageUrl');
      }
    });

    test('createdAt debe ser fecha válida en formato ISO 8601', () {
      // Arrange & Act
      for (final gossip in mockGossips) {
        final createdAt = gossip['createdAt'] as String;

        // Assert
        expect(() => DateTime.parse(createdAt), returnsNormally,
            reason: 'createdAt debe ser fecha válida: $createdAt');
      }
    });

    test('modifiedAt puede ser null o fecha válida', () {
      // Arrange & Act
      for (final gossip in mockGossips) {
        final modifiedAt = gossip['modifiedAt'];

        if (modifiedAt != null) {
          // Assert
          expect(() => DateTime.parse(modifiedAt as String), returnsNormally,
              reason: 'modifiedAt debe ser null o fecha válida: $modifiedAt');
        }
      }
    });

    test('gossip con id "1" debe tener datos esperados', () {
      // Arrange
      final gossip1 = mockGossips.firstWhere((g) => g['id'] == '1');

      // Assert
      expect(gossip1['subject'], 'Shakira');
      expect(gossip1['countryId'], 'co');
      expect(gossip1['regionId'], 'antioquia');
      expect(gossip1['cityId'], 'medellin');
      expect(gossip1['publishedAs'], 'anonymous');
    });
  });
}
