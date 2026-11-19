import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/localization/locale_detector.dart';

void main() {
  group('LocaleDetector', () {
    group('getLocaleInfo', () {
      test('debe retornar info completa para español', () {
        // Arrange
        const locale = Locale('es', 'MX');

        // Act
        final info = LocaleDetector.getLocaleInfo(locale);

        // Assert
        expect(info['languageCode'], equals('es'));
        expect(info['countryCode'], equals('MX'));
        expect(info['scriptCode'], equals('N/A'));
        expect(info['displayName'], equals('Spanish'));
        expect(info['nativeName'], equals('Español'));
        expect(info['emoji'], equals('🇪🇸'));
      });

      test('debe retornar info completa para inglés', () {
        // Arrange
        const locale = Locale('en', 'US');

        // Act
        final info = LocaleDetector.getLocaleInfo(locale);

        // Assert
        expect(info['languageCode'], equals('en'));
        expect(info['countryCode'], equals('US'));
        expect(info['scriptCode'], equals('N/A'));
        expect(info['displayName'], equals('English'));
        expect(info['nativeName'], equals('English'));
        expect(info['emoji'], equals('🇺🇸'));
      });

      test('debe retornar N/A para countryCode null', () {
        // Arrange
        const locale = Locale('es');

        // Act
        final info = LocaleDetector.getLocaleInfo(locale);

        // Assert
        expect(info['countryCode'], equals('N/A'));
      });

      test('debe retornar N/A para scriptCode null', () {
        // Arrange
        const locale = Locale('es', 'MX');

        // Act
        final info = LocaleDetector.getLocaleInfo(locale);

        // Assert
        expect(info['scriptCode'], equals('N/A'));
      });

      test('debe retornar Unknown para idioma no soportado', () {
        // Arrange
        const locale = Locale('fr', 'FR');

        // Act
        final info = LocaleDetector.getLocaleInfo(locale);

        // Assert
        expect(info['languageCode'], equals('fr'));
        expect(info['countryCode'], equals('FR'));
        expect(info['displayName'], equals('Unknown'));
        expect(info['nativeName'], equals('Unknown'));
        expect(info['emoji'], equals('🌐'));
      });

      test('debe incluir todas las claves requeridas', () {
        // Arrange
        const locale = Locale('es', 'MX');

        // Act
        final info = LocaleDetector.getLocaleInfo(locale);

        // Assert
        expect(info.keys, containsAll([
          'languageCode',
          'countryCode',
          'scriptCode',
          'displayName',
          'nativeName',
          'emoji',
        ]));
        expect(info.keys.length, equals(6));
      });
    });

    group('edge cases', () {
      test('getLocaleInfo debe manejar locale con scriptCode', () {
        // Arrange
        const locale = Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hans',
          countryCode: 'CN',
        );

        // Act
        final info = LocaleDetector.getLocaleInfo(locale);

        // Assert
        expect(info['scriptCode'], equals('Hans'));
        expect(info['languageCode'], equals('zh'));
        expect(info['countryCode'], equals('CN'));
      });

    });

    group('métodos privados (testeo indirecto)', () {
      test('_getDisplayName debe retornar nombres correctos via getLocaleInfo',
          () {
        // Arrange & Act
        final esInfo = LocaleDetector.getLocaleInfo(const Locale('es'));
        final enInfo = LocaleDetector.getLocaleInfo(const Locale('en'));
        final unknownInfo = LocaleDetector.getLocaleInfo(const Locale('fr'));

        // Assert
        expect(esInfo['displayName'], equals('Spanish'));
        expect(enInfo['displayName'], equals('English'));
        expect(unknownInfo['displayName'], equals('Unknown'));
      });

      test('_getNativeName debe retornar nombres correctos via getLocaleInfo',
          () {
        // Arrange & Act
        final esInfo = LocaleDetector.getLocaleInfo(const Locale('es'));
        final enInfo = LocaleDetector.getLocaleInfo(const Locale('en'));
        final unknownInfo = LocaleDetector.getLocaleInfo(const Locale('fr'));

        // Assert
        expect(esInfo['nativeName'], equals('Español'));
        expect(enInfo['nativeName'], equals('English'));
        expect(unknownInfo['nativeName'], equals('Unknown'));
      });

      test('_getEmoji debe retornar emojis correctos via getLocaleInfo', () {
        // Arrange & Act
        final esInfo = LocaleDetector.getLocaleInfo(const Locale('es'));
        final enInfo = LocaleDetector.getLocaleInfo(const Locale('en'));
        final unknownInfo = LocaleDetector.getLocaleInfo(const Locale('fr'));

        // Assert
        expect(esInfo['emoji'], equals('🇪🇸'));
        expect(enInfo['emoji'], equals('🇺🇸'));
        expect(unknownInfo['emoji'], equals('🌐'));
      });
    });
  });
}
