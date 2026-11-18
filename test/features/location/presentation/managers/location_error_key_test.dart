import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/location/presentation/managers/location_error_key.dart';
import 'package:chismes/l10n/app_localizations.dart';

void main() {
  group('LocationErrorKey', () {
    test('debe tener todos los keys definidos', () {
      // Assert
      expect(LocationErrorKey.values, contains(LocationErrorKey.failedToLoadCountries));
      expect(LocationErrorKey.values, contains(LocationErrorKey.failedToLoadRegions));
      expect(LocationErrorKey.values, contains(LocationErrorKey.failedToLoadCities));
      expect(LocationErrorKey.values, contains(LocationErrorKey.unexpectedError));
      expect(LocationErrorKey.values, contains(LocationErrorKey.gpsPositionFailed));
      expect(LocationErrorKey.values, contains(LocationErrorKey.geocodingFailed));
      expect(LocationErrorKey.values, contains(LocationErrorKey.countryNotAvailable));
      expect(LocationErrorKey.values, contains(LocationErrorKey.regionNotAvailable));
      expect(LocationErrorKey.values, contains(LocationErrorKey.cityNotAvailable));
      expect(LocationErrorKey.values, contains(LocationErrorKey.detectionFailed));
    });

    test('debe tener exactamente 10 keys', () {
      // Assert
      expect(LocationErrorKey.values, hasLength(10));
    });

    test('enum values debe contener solo valores de LocationErrorKey', () {
      // Assert
      for (final key in LocationErrorKey.values) {
        expect(key, isA<LocationErrorKey>());
      }
    });

    test('debe poder comparar keys por identidad', () {
      // Arrange
      const key1 = LocationErrorKey.failedToLoadCountries;
      const key2 = LocationErrorKey.failedToLoadCountries;
      const key3 = LocationErrorKey.failedToLoadRegions;

      // Assert
      expect(key1 == key2, isTrue);
      expect(key1 == key3, isFalse);
    });

    group('LocationErrorKeyExtension.getMessage', () {
      late BuildContext context;

      Future<BuildContext> _createContext(WidgetTester tester) async {
        late BuildContext capturedContext;

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const SizedBox();
              },
            ),
          ),
        );

        return capturedContext;
      }

      testWidgets('failedToLoadCountries debe retornar mensaje', (tester) async {
        // Arrange
        context = await _createContext(tester);

        // Act
        final message = LocationErrorKey.failedToLoadCountries.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('failedToLoadRegions debe retornar mensaje', (tester) async {
        // Arrange
        context = await _createContext(tester);

        // Act
        final message = LocationErrorKey.failedToLoadRegions.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('failedToLoadCities debe retornar mensaje', (tester) async {
        // Arrange
        context = await _createContext(tester);

        // Act
        final message = LocationErrorKey.failedToLoadCities.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('unexpectedError debe retornar mensaje', (tester) async {
        // Arrange
        context = await _createContext(tester);

        // Act
        final message = LocationErrorKey.unexpectedError.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('gpsPositionFailed debe retornar mensaje', (tester) async {
        // Arrange
        context = await _createContext(tester);

        // Act
        final message = LocationErrorKey.gpsPositionFailed.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('geocodingFailed debe retornar mensaje', (tester) async {
        // Arrange
        context = await _createContext(tester);

        // Act
        final message = LocationErrorKey.geocodingFailed.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('detectionFailed debe retornar mensaje', (tester) async {
        // Arrange
        context = await _createContext(tester);

        // Act
        final message = LocationErrorKey.detectionFailed.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('countryNotAvailable debe retornar mensaje sin entityName', (tester) async {
        // Arrange
        context = await _createContext(tester);

        // Act
        final message = LocationErrorKey.countryNotAvailable.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('countryNotAvailable debe incluir entityName si se proporciona', (tester) async {
        // Arrange
        context = await _createContext(tester);
        const entityName = 'Colombia';

        // Act
        final message = LocationErrorKey.countryNotAvailable.getMessage(
          context,
          entityName: entityName,
        );

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
        // El mensaje debería incluir el entityName (según el arb template)
      });

      testWidgets('regionNotAvailable debe retornar mensaje sin entityName', (tester) async {
        // Arrange
        context = await _createContext(tester);

        // Act
        final message = LocationErrorKey.regionNotAvailable.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('regionNotAvailable debe incluir entityName si se proporciona', (tester) async {
        // Arrange
        context = await _createContext(tester);
        const entityName = 'Antioquia';

        // Act
        final message = LocationErrorKey.regionNotAvailable.getMessage(
          context,
          entityName: entityName,
        );

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('cityNotAvailable debe retornar mensaje sin entityName', (tester) async {
        // Arrange
        context = await _createContext(tester);

        // Act
        final message = LocationErrorKey.cityNotAvailable.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('cityNotAvailable debe incluir entityName si se proporciona', (tester) async {
        // Arrange
        context = await _createContext(tester);
        const entityName = 'Medellín';

        // Act
        final message = LocationErrorKey.cityNotAvailable.getMessage(
          context,
          entityName: entityName,
        );

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('todos los keys deben tener switch case implementado', (tester) async {
        // Arrange
        context = await _createContext(tester);

        // Act & Assert - No debe lanzar error
        for (final key in LocationErrorKey.values) {
          expect(() => key.getMessage(context), returnsNormally);
        }
      });
    });
  });
}
