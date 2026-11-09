import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/features/auth/domain/validators/auth_validator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/easy_localization_test_helper.dart';
import '../../../../helpers/security_test_helpers.dart';

/// Tests de SEGURIDAD para AuthValidator
///
/// Estos tests verifican que los mensajes de validación:
/// - NO expongan información técnica sensible
/// - NO permitan XSS o inyección
/// - NO filtren datos del usuario
/// - Estén correctamente traducidos
///
/// IMPORTANTE: Estos tests usan testWidgets() porque necesitan
/// inicializar EasyLocalization para verificar los mensajes reales
/// que verá el usuario en producción.
void main() {
  group('AuthValidator - Security Tests', () {
    group('validateEmail - Security', () {
      testWidgets('mensajes de error son seguros y no exponen info técnica',
          (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Test cases: (input, expectedCode, testName)
        final testCases = [
          (null, ErrorCode.missingRequiredField, 'email null'),
          ('', ErrorCode.missingRequiredField, 'email vacío'),
          ('invalid', ErrorCode.invalidInput, 'sin @'),
          ('test@', ErrorCode.invalidInput, 'sin dominio'),
          ('@test.com', ErrorCode.invalidInput, 'sin local part'),
          ('test@test', ErrorCode.invalidInput, 'sin TLD'),
          ('${'a' * 243}@example.com', ErrorCode.invalidInput, 'demasiado largo'),
        ];

        for (final (email, expectedCode, testName) in testCases) {
          final result = AuthValidator.validateEmail(email);

          // Verifica el código
          expect(result?.code, expectedCode, reason: 'Test: $testName');

          // SEGURIDAD: Verifica que el mensaje es seguro
          SecurityTestHelpers.verifyMessageSecurity(
            result?.technicalMessage,
            context: 'validateEmail - $testName',
            additionalForbidden: ['regex', 'pattern', 'validation rule'],
          );

          // SEGURIDAD: Verifica que no refleja el input sin sanitizar
          if (email != null && email.length > 3) {
            SecurityTestHelpers.verifyNoUserInputReflection(
              result?.technicalMessage,
              email,
              context: 'validateEmail - $testName',
            );
          }

          // Verifica que el mensaje está en español
          SecurityTestHelpers.verifyMessageLanguage(
            result?.technicalMessage,
            expectedLanguage: 'es',
            context: 'validateEmail - $testName',
          );

          // Verifica longitud razonable (< 150 chars para errores de validación)
          if (result?.technicalMessage != null) {
            expect(
              result!.technicalMessage!.length,
              lessThan(150),
              reason: 'Mensaje de validación debe ser conciso',
            );
          }
        }
      });

      testWidgets('mensaje no expone email del usuario', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        final result = AuthValidator.validateEmail('admin@internal.com');

        // CRÍTICO: El mensaje NO debe contener el email ingresado
        final msg = result?.technicalMessage ?? '';
        expect(msg, isNot(contains('admin@internal.com')));
        expect(msg, isNot(contains('@internal')));
        expect(msg, isNot(contains('admin@')));
      });

      testWidgets('emails válidos no generan mensajes', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        final validEmails = [
          'test@example.com',
          'user.name@domain.co',
          'test+tag@example.com',
          'test_123@sub.example.com',
        ];

        for (final email in validEmails) {
          final result = AuthValidator.validateEmail(email);
          expect(result, isNull, reason: 'Email válido: $email');
        }
      });
    });

    group('validatePassword - Security', () {
      testWidgets('mensajes NO revelan la contraseña ingresada', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Contraseñas débiles con diferentes problemas
        final weakPasswords = [
          'weak123',      // Muy corta
          'ALLUPPERCASE123!',  // Sin minúscula
          'alllowercase123!',  // Sin mayúscula
          'NoNumbers!@#',      // Sin número
          'NoSpecial123A',     // Sin carácter especial
        ];

        for (final password in weakPasswords) {
          final result = AuthValidator.validatePassword(password);

          // CRÍTICO: El mensaje NO debe contener la contraseña
          final msg = result?.technicalMessage ?? '';
          expect(msg, isNot(contains(password)),
            reason: 'Mensaje NO debe contener contraseña ingresada');

          // Verifica seguridad general
          SecurityTestHelpers.verifyMessageSecurity(
            msg,
            context: 'validatePassword',
            additionalForbidden: ['contraseña: ', 'password: ', 'value:'],
          );
        }
      });

      testWidgets('mensajes de error son seguros y descriptivos', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Test cases: (password, expectedCode, testName)
        final testCases = [
          (null, ErrorCode.missingRequiredField, 'password null'),
          ('', ErrorCode.missingRequiredField, 'password vacía'),
          ('Short1!', ErrorCode.weakPassword, 'muy corta'),
          ('NOLOW123!', ErrorCode.weakPassword, 'sin minúscula'),
          ('noupper123!', ErrorCode.weakPassword, 'sin mayúscula'),
          ('NoNumbers!@', ErrorCode.weakPassword, 'sin número'),
          ('NoSpecial123A', ErrorCode.weakPassword, 'sin especial'),
          ('A1!${'a' * 126}', ErrorCode.invalidInput, 'muy larga'),
        ];

        for (final (password, expectedCode, testName) in testCases) {
          final result = AuthValidator.validatePassword(password);

          expect(result?.code, expectedCode, reason: 'Test: $testName');

          // SEGURIDAD: Verifica mensaje seguro
          SecurityTestHelpers.verifyMessageSecurity(
            result?.technicalMessage,
            context: 'validatePassword - $testName',
          );

          // Verifica idioma español
          SecurityTestHelpers.verifyMessageLanguage(
            result?.technicalMessage,
            expectedLanguage: 'es',
            context: 'validatePassword - $testName',
          );
        }
      });

      testWidgets('contraseñas válidas no generan mensajes', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        final validPasswords = [
          'Test123!',
          'MyP@ssw0rd',
          'Secur3#Pass',
          'C0mpl3x!Password',
        ];

        for (final password in validPasswords) {
          final result = AuthValidator.validatePassword(password);
          expect(result, isNull, reason: 'Password válida: $password');
        }
      });
    });

    group('validateUsername - Security', () {
      testWidgets('mensajes no exponen info técnica de validación', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        final testCases = [
          (null, ErrorCode.missingRequiredField, 'username null'),
          ('', ErrorCode.missingRequiredField, 'username vacío'),
          ('ab', ErrorCode.invalidInput, 'muy corto'),
          ('a' * 31, ErrorCode.invalidInput, 'muy largo'),
          ('UserName', ErrorCode.invalidInput, 'con mayúsculas'),
          ('123user', ErrorCode.invalidInput, 'empieza con número'),
          ('_user', ErrorCode.invalidInput, 'empieza con underscore'),
          ('user_', ErrorCode.invalidInput, 'termina con underscore'),
          ('user-name', ErrorCode.invalidInput, 'con guión'),
          ('user name', ErrorCode.invalidInput, 'con espacio'),
          ('admin', ErrorCode.invalidInput, 'palabra reservada'),
        ];

        for (final (username, expectedCode, testName) in testCases) {
          final result = AuthValidator.validateUsername(username);

          expect(result?.code, expectedCode, reason: 'Test: $testName');

          // SEGURIDAD: Verifica mensaje seguro
          SecurityTestHelpers.verifyMessageSecurity(
            result?.technicalMessage,
            context: 'validateUsername - $testName',
            additionalForbidden: ['reserved words list', 'blocked', 'blacklist'],
          );

          // No debe reflejar el username si es potencialmente malicioso
          if (username != null && (username.contains('<') || username.contains('>'))) {
            SecurityTestHelpers.verifyNoUserInputReflection(
              result?.technicalMessage,
              username,
              context: 'validateUsername - XSS check',
            );
          }
        }
      });

      testWidgets('mensaje no revela lista de palabras reservadas', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        final reservedWords = ['admin', 'root', 'system'];

        for (final word in reservedWords) {
          final result = AuthValidator.validateUsername(word);

          expect(result, isA<ValidationFailure>());

          // SEGURIDAD: El mensaje NO debe revelar otras palabras reservadas
          final msg = result?.technicalMessage ?? '';
          expect(msg, isNot(contains('admin, root, system')),
            reason: 'No debe listar todas las palabras reservadas');

          // El mensaje solo debe decir que está reservado, sin detalles
          expect(msg.toLowerCase(), contains('reservad'),
            reason: 'Debe indicar que está reservado');
        }
      });
    });

    group('validateDisplayName - Security', () {
      testWidgets('mensajes no exponen input del usuario en errores', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Casos que SÍ generan error (demasiado largos)
        final testCases = [
          '<script>alert("xss")</script>' * 3, // > 50 chars
          'User\'; DROP TABLE users;--' * 3, // > 50 chars
          'a' * 51, // Más de 50 caracteres
        ];

        for (final displayName in testCases) {
          final result = AuthValidator.validateDisplayName(displayName);

          // Verifica que retorna error de longitud
          expect(result, isA<ValidationFailure>());
          expect(result?.code, ErrorCode.invalidInput);

          // CRÍTICO: El mensaje NO debe incluir el input completo
          final msg = result?.technicalMessage ?? '';

          // No debe contener el texto malicioso
          expect(msg, isNot(contains('<script>')),
            reason: 'No debe reflejar tags HTML del input');
          expect(msg, isNot(contains('DROP TABLE')),
            reason: 'No debe reflejar SQL del input');

          // No debe incluir el displayName largo completo
          if (displayName.length > 50) {
            expect(msg.contains(displayName), isFalse,
              reason: 'No debe incluir todo el displayName largo');
          }

          SecurityTestHelpers.verifyMessageSecurity(
            msg,
            context: 'validateDisplayName - longitud',
          );
        }
      });

      testWidgets('displayNames válidos no generan warning incluso con caracteres especiales',
          (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Nota: El validator NO rechaza HTML/caracteres especiales
        // Esto está OK porque Flutter Text widgets no renderizan HTML
        // El escape/sanitización se hace a nivel de UI si es necesario
        final validNames = [
          'Juan Pérez',
          'María José',
          'O\'Brien',
          'Jean-Pierre',
        ];

        for (final name in validNames) {
          final result = AuthValidator.validateDisplayName(name);
          expect(result, isNull, reason: 'Name válido: $name');
        }
      });
    });

    group('validateBio - Security', () {
      testWidgets('mensajes son seguros para bio muy larga', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        final longBio = 'a' * 161;
        final result = AuthValidator.validateBio(longBio);

        expect(result, isA<ValidationFailure>());

        // SEGURIDAD: No debe incluir el bio completo en el mensaje
        final msg = result?.technicalMessage ?? '';
        expect(msg, isNot(contains('a' * 161)),
          reason: 'No debe incluir todo el contenido del bio');

        SecurityTestHelpers.verifyMessageSecurity(
          msg,
          context: 'validateBio',
        );
      });
    });

    group('General Security Compliance', () {
      testWidgets('todos los mensajes cumplen con límite de longitud', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        // Recolectar todos los mensajes posibles
        final allResults = <ValidationFailure>[
          // Email errors
          AuthValidator.validateEmail(null)!,
          AuthValidator.validateEmail('')!,
          AuthValidator.validateEmail('invalid')!,
          AuthValidator.validateEmail('${'a' * 250}@test.com')!,

          // Password errors
          AuthValidator.validatePassword(null)!,
          AuthValidator.validatePassword('weak')!,
          AuthValidator.validatePassword('NOUPPER123!')!,

          // Username errors
          AuthValidator.validateUsername(null)!,
          AuthValidator.validateUsername('ab')!,
          AuthValidator.validateUsername('admin')!,

          // DisplayName errors
          AuthValidator.validateDisplayName(null)!,
          AuthValidator.validateDisplayName('a' * 51)!,

          // Bio errors
          AuthValidator.validateBio('a' * 161)!,
        ];

        for (final result in allResults) {
          final msg = result.technicalMessage ?? '';

          // Límite de 200 caracteres para mensajes de validación
          expect(msg.length, lessThan(200),
            reason: 'Mensaje muy largo puede indicar data leakage: "$msg"');

          // Verificar seguridad de cada mensaje
          SecurityTestHelpers.verifyMessageSecurity(
            msg,
            context: 'Código: ${result.code}',
          );
        }
      });

      testWidgets('ningún mensaje contiene URLs o paths', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        final allResults = [
          AuthValidator.validateEmail('invalid'),
          AuthValidator.validatePassword('weak'),
          AuthValidator.validateUsername('a'),
        ];

        for (final result in allResults) {
          final msg = result?.technicalMessage ?? '';

          // No debe contener URLs
          expect(msg, isNot(matches(RegExp(r'https?://'))),
            reason: 'No debe contener URLs');

          // No debe contener paths
          expect(msg, isNot(matches(RegExp(r'[/\\][\w/\\]+'))),
            reason: 'No debe contener file paths');
        }
      });
    });
  });
}
