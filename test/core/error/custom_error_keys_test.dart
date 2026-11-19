import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/error/custom_error_keys.dart';
import 'package:chismes/l10n/app_localizations.dart';

void main() {
  group('CustomErrorKey', () {
    test('debe tener todos los keys definidos', () {
      // Assert
      expect(CustomErrorKey.values, contains(CustomErrorKey.authEmailAlreadyInUseAction));
      expect(CustomErrorKey.values, contains(CustomErrorKey.authOtpCodeMustBe6Digits));
      expect(CustomErrorKey.values, contains(CustomErrorKey.profileScreenErrorLoading));
      expect(CustomErrorKey.values, contains(CustomErrorKey.profileSettingsUpdateError));
      expect(CustomErrorKey.values, contains(CustomErrorKey.profileSignOutError));
    });

    test('debe tener exactamente 5 keys', () {
      // Assert
      expect(CustomErrorKey.values, hasLength(5));
    });

    test('enum values debe contener solo valores de CustomErrorKey', () {
      // Assert
      for (final key in CustomErrorKey.values) {
        expect(key, isA<CustomErrorKey>());
      }
    });

    test('debe poder comparar keys por identidad', () {
      // Arrange
      const key1 = CustomErrorKey.authEmailAlreadyInUseAction;
      const key2 = CustomErrorKey.authEmailAlreadyInUseAction;
      const key3 = CustomErrorKey.authOtpCodeMustBe6Digits;

      // Assert
      expect(key1 == key2, isTrue);
      expect(key1 == key3, isFalse);
    });

    group('getMessage', () {
      late BuildContext context;

      Future<BuildContext> createContext(WidgetTester tester) async {
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

      testWidgets('authEmailAlreadyInUseAction debe retornar mensaje', (tester) async {
        // Arrange
        context = await createContext(tester);

        // Act
        final message = CustomErrorKey.authEmailAlreadyInUseAction.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('authOtpCodeMustBe6Digits debe retornar mensaje', (tester) async {
        // Arrange
        context = await createContext(tester);

        // Act
        final message = CustomErrorKey.authOtpCodeMustBe6Digits.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('profileScreenErrorLoading debe retornar mensaje', (tester) async {
        // Arrange
        context = await createContext(tester);

        // Act
        final message = CustomErrorKey.profileScreenErrorLoading.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('profileSettingsUpdateError debe retornar mensaje', (tester) async {
        // Arrange
        context = await createContext(tester);

        // Act
        final message = CustomErrorKey.profileSettingsUpdateError.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('profileSignOutError debe retornar mensaje', (tester) async {
        // Arrange
        context = await createContext(tester);

        // Act
        final message = CustomErrorKey.profileSignOutError.getMessage(context);

        // Assert
        expect(message, isNotEmpty);
        expect(message, isA<String>());
      });

      testWidgets('todos los keys deben tener switch case implementado', (tester) async {
        // Arrange
        context = await createContext(tester);

        // Act & Assert - No debe lanzar error
        for (final key in CustomErrorKey.values) {
          expect(() => key.getMessage(context), returnsNormally);
        }
      });
    });
  });
}
