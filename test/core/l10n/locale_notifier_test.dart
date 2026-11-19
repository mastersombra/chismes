import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/l10n/locale_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('LocaleNotifier', () {
    late SharedPreferences prefs;

    setUp(() async {
      // Resetear SharedPreferences antes de cada test
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    group('Inicialización', () {
      test('debe usar español como locale por defecto', () async {
        // Arrange & Act
        final notifier = LocaleNotifier(prefs);

        // Assert
        expect(notifier.locale, equals(const Locale('es')));
      });

      test('debe cargar locale guardado desde SharedPreferences', () async {
        // Arrange
        await prefs.setString('app_locale', 'en');

        // Act
        final notifier = LocaleNotifier(prefs);

        // Assert
        expect(notifier.locale, equals(const Locale('en')));
      });

      test('debe usar español si locale guardado no está en supportedLocales', () async {
        // Arrange
        await prefs.setString('app_locale', 'fr');

        // Act
        final notifier = LocaleNotifier(prefs);

        // Assert
        expect(notifier.locale, equals(const Locale('es')));
      });
    });

    group('setLocale', () {
      test('debe cambiar el locale', () async {
        // Arrange
        final notifier = LocaleNotifier(prefs);
        expect(notifier.locale, equals(const Locale('es')));

        // Act
        await notifier.setLocale(const Locale('en'));

        // Assert
        expect(notifier.locale, equals(const Locale('en')));
      });

      test('debe persistir el locale en SharedPreferences', () async {
        // Arrange
        final notifier = LocaleNotifier(prefs);

        // Act
        await notifier.setLocale(const Locale('en'));

        // Assert
        final savedLocale = prefs.getString('app_locale');
        expect(savedLocale, equals('en'));
      });

      test('debe notificar listeners cuando cambia el locale', () async {
        // Arrange
        final notifier = LocaleNotifier(prefs);
        var notified = false;
        notifier.addListener(() {
          notified = true;
        });

        // Act
        await notifier.setLocale(const Locale('en'));

        // Assert
        expect(notified, isTrue);
      });

      test('NO debe notificar si el locale es el mismo', () async {
        // Arrange
        final notifier = LocaleNotifier(prefs);
        await notifier.setLocale(const Locale('en'));

        var notified = false;
        notifier.addListener(() {
          notified = true;
        });

        // Act
        await notifier.setLocale(const Locale('en'));

        // Assert
        expect(notified, isFalse);
      });

      test('debe permitir cambiar entre locales soportados', () async {
        // Arrange
        final notifier = LocaleNotifier(prefs);

        // Act & Assert
        await notifier.setLocale(const Locale('en'));
        expect(notifier.locale, equals(const Locale('en')));

        await notifier.setLocale(const Locale('es'));
        expect(notifier.locale, equals(const Locale('es')));

        await notifier.setLocale(const Locale('en'));
        expect(notifier.locale, equals(const Locale('en')));
      });
    });

    group('supportedLocales', () {
      test('debe contener español', () {
        // Assert
        expect(
          LocaleNotifier.supportedLocales,
          contains(const Locale('es')),
        );
      });

      test('debe contener inglés', () {
        // Assert
        expect(
          LocaleNotifier.supportedLocales,
          contains(const Locale('en')),
        );
      });

      test('debe tener exactamente 2 locales', () {
        // Assert
        expect(LocaleNotifier.supportedLocales, hasLength(2));
      });
    });

    group('Persistencia', () {
      test('debe persistir locale entre instancias', () async {
        // Arrange
        final notifier1 = LocaleNotifier(prefs);
        await notifier1.setLocale(const Locale('en'));

        // Act
        final notifier2 = LocaleNotifier(prefs);

        // Assert
        expect(notifier2.locale, equals(const Locale('en')));
      });

      test('debe mantener español por defecto si no hay persistencia', () async {
        // Arrange - No guardar nada en prefs

        // Act
        final notifier = LocaleNotifier(prefs);

        // Assert
        expect(notifier.locale, equals(const Locale('es')));
        expect(prefs.getString('app_locale'), isNull);
      });
    });

    group('Edge cases', () {
      test('debe manejar locale null en SharedPreferences', () async {
        // Arrange
        await prefs.remove('app_locale');

        // Act
        final notifier = LocaleNotifier(prefs);

        // Assert
        expect(notifier.locale, equals(const Locale('es')));
      });

      test('debe manejar locale vacío en SharedPreferences', () async {
        // Arrange
        await prefs.setString('app_locale', '');

        // Act
        final notifier = LocaleNotifier(prefs);

        // Assert
        expect(notifier.locale, equals(const Locale('es')));
      });

      test('debe manejar múltiples listeners', () async {
        // Arrange
        final notifier = LocaleNotifier(prefs);
        var listener1Called = false;
        var listener2Called = false;

        notifier.addListener(() {
          listener1Called = true;
        });
        notifier.addListener(() {
          listener2Called = true;
        });

        // Act
        await notifier.setLocale(const Locale('en'));

        // Assert
        expect(listener1Called, isTrue);
        expect(listener2Called, isTrue);
      });
    });
  });
}
