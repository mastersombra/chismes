import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/features/auth/domain/validators/auth_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthValidator', () {
    group('validateEmail', () {
      test('debe retornar null cuando email es válido', () {
        // Arrange
        const email = 'test@example.com';

        // Act
        final result = AuthValidator.validateEmail(email);

        // Assert
        expect(result, isNull);
      });

      test('debe retornar failure cuando email es null', () {
        // Arrange
        const String? email = null;

        // Act
        final result = AuthValidator.validateEmail(email);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.missingRequiredField);
      });

      test('debe retornar failure cuando email está vacío', () {
        // Arrange
        const email = '';

        // Act
        final result = AuthValidator.validateEmail(email);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.missingRequiredField);
      });

      test('debe retornar failure cuando email no tiene @', () {
        // Arrange
        const email = 'testexample.com';

        // Act
        final result = AuthValidator.validateEmail(email);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe retornar failure cuando email no tiene dominio', () {
        // Arrange
        const email = 'test@';

        // Act
        final result = AuthValidator.validateEmail(email);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe aceptar email con subdominios', () {
        // Arrange
        const email = 'test@mail.example.com';

        // Act
        final result = AuthValidator.validateEmail(email);

        // Assert
        expect(result, isNull);
      });

      test('debe retornar failure cuando email es muy largo (>254)', () {
        // Arrange - Email de 255 caracteres
        final email = '${'a' * 243}@example.com'; // 243 + 12 = 255

        // Act
        final result = AuthValidator.validateEmail(email);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
        expect(result?.technicalMessage, contains('too long'));
      });

      test('debe aceptar email en límite máximo (254)', () {
        // Arrange - Email de exactamente 254 caracteres
        final email = '${'a' * 242}@example.com'; // 242 + 12 = 254

        // Act
        final result = AuthValidator.validateEmail(email);

        // Assert
        expect(result, isNull);
      });
    });

    group('validatePassword', () {
      test('debe retornar null cuando password es fuerte', () {
        // Arrange
        const password = 'Test123!@';

        // Act
        final result = AuthValidator.validatePassword(password);

        // Assert
        expect(result, isNull);
      });

      test('debe retornar failure cuando password es null', () {
        // Arrange
        const String? password = null;

        // Act
        final result = AuthValidator.validatePassword(password);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.missingRequiredField);
      });

      test('debe retornar failure cuando password es muy corta', () {
        // Arrange
        const password = 'Test1!';

        // Act
        final result = AuthValidator.validatePassword(password);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.weakPassword);
      });

      test('debe retornar failure cuando password no tiene minúscula', () {
        // Arrange
        const password = 'TEST123!@';

        // Act
        final result = AuthValidator.validatePassword(password);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.weakPassword);
      });

      test('debe retornar failure cuando password no tiene mayúscula', () {
        // Arrange
        const password = 'test123!@';

        // Act
        final result = AuthValidator.validatePassword(password);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.weakPassword);
      });

      test('debe retornar failure cuando password no tiene número', () {
        // Arrange
        const password = 'TestTest!@';

        // Act
        final result = AuthValidator.validatePassword(password);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.weakPassword);
      });

      test('debe retornar failure cuando password no tiene carácter especial', () {
        // Arrange
        const password = 'Test123456';

        // Act
        final result = AuthValidator.validatePassword(password);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.weakPassword);
      });

      test('debe retornar failure cuando password está vacía', () {
        // Arrange
        const password = '';

        // Act
        final result = AuthValidator.validatePassword(password);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.missingRequiredField);
      });

      test('debe retornar failure cuando password es muy larga (>128)', () {
        // Arrange
        final password = 'A1!${'a' * 126}'; // 129 caracteres

        // Act
        final result = AuthValidator.validatePassword(password);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
        expect(result?.technicalMessage, contains('too long'));
      });

      test('debe aceptar password en longitud máxima (128)', () {
        // Arrange
        final password = 'A1!${'a' * 125}'; // 128 caracteres

        // Act
        final result = AuthValidator.validatePassword(password);

        // Assert
        expect(result, isNull);
      });

      test('debe aceptar password en longitud mínima (8)', () {
        // Arrange
        const password = 'Test123!';

        // Act
        final result = AuthValidator.validatePassword(password);

        // Assert
        expect(result, isNull);
      });
    });

    group('calculatePasswordStrength', () {
      test('debe retornar 0 para password vacía', () {
        // Arrange
        const password = '';

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, 0);
      });

      test('debe retornar valor bajo para password débil', () {
        // Arrange
        const password = 'test';

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, lessThan(34));
      });

      test('debe retornar valor medio para password media', () {
        // Arrange
        const password = 'Test1234';

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, greaterThanOrEqualTo(34));
        expect(strength, lessThan(67));
      });

      test('debe retornar valor alto para password fuerte', () {
        // Arrange
        const password = 'Test123!@#abc';

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, greaterThanOrEqualTo(67));
      });

      test('debe dar 10 puntos por longitud >= 8', () {
        // Arrange
        const password = 'testtest'; // Longitud 8

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, greaterThanOrEqualTo(10));
      });

      test('debe dar 20 puntos adicionales por longitud >= 12', () {
        // Arrange
        const password = 'testtesttest'; // Longitud 12

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, greaterThanOrEqualTo(20));
      });

      test('debe dar 30 puntos adicionales por longitud >= 16', () {
        // Arrange
        const password = 'testtesttesttest'; // Longitud 16

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, greaterThanOrEqualTo(30));
      });

      test('debe dar 10 puntos adicionales por diversidad >= 8 caracteres únicos',
          () {
        // Arrange
        const password = 'abcdefgh'; // 8 caracteres únicos

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        // Debería tener al menos los puntos de longitud (10) + minúsculas (15) + diversidad (10) = 35
        expect(strength, greaterThanOrEqualTo(35));
      });

      test('debe dar 20 puntos adicionales por diversidad >= 12 caracteres únicos',
          () {
        // Arrange
        const password = 'abcdefghijklm'; // 13 caracteres únicos

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        // Longitud(20) + minúsculas(15) + diversidad(20) = 55
        expect(strength, greaterThanOrEqualTo(55));
      });

      test('debe dar puntos por minúsculas', () {
        // Arrange
        const password = 'test';

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, greaterThanOrEqualTo(15));
      });

      test('debe dar puntos por mayúsculas', () {
        // Arrange
        const password = 'TEST';

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, greaterThanOrEqualTo(15));
      });

      test('debe dar puntos por números', () {
        // Arrange
        const password = '12345';

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, greaterThanOrEqualTo(15));
      });

      test('debe dar puntos por caracteres especiales', () {
        // Arrange
        const password = '!@#\$%';

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, greaterThanOrEqualTo(15));
      });

      test('debe clampear el resultado entre 0 y 100', () {
        // Arrange - Password que potencialmente daría más de 100
        const password = 'SuperSecure123!@#VeryLongPasswordWithManyUniqueCharacters';

        // Act
        final strength = AuthValidator.calculatePasswordStrength(password);

        // Assert
        expect(strength, lessThanOrEqualTo(100));
        expect(strength, greaterThanOrEqualTo(0));
      });
    });

    group('getPasswordStrengthLevel', () {
      test('debe retornar weak para passwords con strength < 34', () {
        // Arrange
        const password = 'test'; // strength bajo

        // Act
        final level = AuthValidator.getPasswordStrengthLevel(password);

        // Assert
        expect(level, PasswordStrength.weak);
      });

      test('debe retornar medium para passwords con strength entre 34-66', () {
        // Arrange
        const password = 'Test1234'; // strength medio

        // Act
        final level = AuthValidator.getPasswordStrengthLevel(password);

        // Assert
        expect(level, PasswordStrength.medium);
      });

      test('debe retornar strong para passwords con strength >= 67', () {
        // Arrange
        const password = 'Test123!@#abc'; // strength alto

        // Act
        final level = AuthValidator.getPasswordStrengthLevel(password);

        // Assert
        expect(level, PasswordStrength.strong);
      });

      test('debe retornar weak para password vacía', () {
        // Arrange
        const password = '';

        // Act
        final level = AuthValidator.getPasswordStrengthLevel(password);

        // Assert
        expect(level, PasswordStrength.weak);
      });
    });

    group('validateUsername', () {
      test('debe retornar null cuando username es válido', () {
        // Arrange
        const username = 'juanperez';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isNull);
      });

      test('debe retornar failure cuando username es null', () {
        // Arrange
        const String? username = null;

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.missingRequiredField);
      });

      test('debe retornar failure cuando username está vacío', () {
        // Arrange
        const username = '';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.missingRequiredField);
      });

      test('debe aceptar username con números', () {
        // Arrange
        const username = 'juan123';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isNull);
      });

      test('debe aceptar username con guión bajo', () {
        // Arrange
        const username = 'juan_perez';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isNull);
      });

      test('debe retornar failure cuando username es muy corto', () {
        // Arrange
        const username = 'ab';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe retornar failure cuando username tiene mayúsculas', () {
        // Arrange
        const username = 'JuanPerez';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe retornar failure cuando username empieza con número', () {
        // Arrange
        const username = '123juan';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe retornar failure cuando username empieza con guión bajo', () {
        // Arrange
        const username = '_juan';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe retornar failure cuando username termina con guión bajo', () {
        // Arrange
        const username = 'juan_';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe retornar failure cuando username es palabra reservada', () {
        // Arrange
        const username = 'admin';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe retornar failure cuando username es muy largo (>30)', () {
        // Arrange
        final username = 'a' * 31; // 31 caracteres

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
        expect(result?.technicalMessage, contains('too long'));
      });

      test('debe aceptar username en longitud máxima (30)', () {
        // Arrange
        final username = 'a' * 30; // Exactamente 30 caracteres

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isNull);
      });

      test('debe aceptar username en longitud mínima (3)', () {
        // Arrange
        const username = 'abc';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isNull);
      });

      test('debe rechazar username con caracteres especiales no permitidos', () {
        // Arrange
        const username = 'juan-perez';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe rechazar username con espacios', () {
        // Arrange
        const username = 'juan perez';

        // Act
        final result = AuthValidator.validateUsername(username);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe rechazar todas las palabras reservadas', () {
        // Arrange
        const reservedWords = [
          'admin',
          'root',
          'system',
          'chismes',
          'support',
          'help',
          'anonymous',
          'user',
          'guest',
        ];

        // Act & Assert
        for (final word in reservedWords) {
          final result = AuthValidator.validateUsername(word);
          expect(result, isA<ValidationFailure>(),
              reason: '$word should be rejected');
          expect(result?.code, ErrorCode.invalidInput);
        }
      });
    });

    group('validateDisplayName', () {
      test('debe retornar null cuando display name es válido', () {
        // Arrange
        const displayName = 'Juan Pérez';

        // Act
        final result = AuthValidator.validateDisplayName(displayName);

        // Assert
        expect(result, isNull);
      });

      test('debe retornar failure cuando display name es null', () {
        // Arrange
        const String? displayName = null;

        // Act
        final result = AuthValidator.validateDisplayName(displayName);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.missingRequiredField);
      });

      test('debe retornar failure cuando display name solo tiene espacios', () {
        // Arrange
        const displayName = '   ';

        // Act
        final result = AuthValidator.validateDisplayName(displayName);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe retornar failure cuando display name está vacío', () {
        // Arrange
        const displayName = '';

        // Act
        final result = AuthValidator.validateDisplayName(displayName);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.missingRequiredField);
      });

      test('debe retornar failure cuando display name es muy largo (>50)', () {
        // Arrange
        final displayName = 'a' * 51; // 51 caracteres

        // Act
        final result = AuthValidator.validateDisplayName(displayName);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
        expect(result?.technicalMessage, contains('too long'));
      });

      test('debe aceptar display name en longitud máxima (50)', () {
        // Arrange
        final displayName = 'a' * 50; // Exactamente 50 caracteres

        // Act
        final result = AuthValidator.validateDisplayName(displayName);

        // Assert
        expect(result, isNull);
      });

      test('debe aceptar display name con espacios al inicio que luego se trim',
          () {
        // Arrange
        const displayName = '  Juan Pérez  ';

        // Act
        final result = AuthValidator.validateDisplayName(displayName);

        // Assert
        expect(result, isNull);
      });
    });

    group('validateBio', () {
      test('debe retornar null cuando bio es null (opcional)', () {
        // Arrange
        const String? bio = null;

        // Act
        final result = AuthValidator.validateBio(bio);

        // Assert
        expect(result, isNull);
      });

      test('debe retornar null cuando bio es vacía (opcional)', () {
        // Arrange
        const bio = '';

        // Act
        final result = AuthValidator.validateBio(bio);

        // Assert
        expect(result, isNull);
      });

      test('debe retornar null cuando bio es válida', () {
        // Arrange
        const bio = 'Amante de los chismes y el café.';

        // Act
        final result = AuthValidator.validateBio(bio);

        // Assert
        expect(result, isNull);
      });

      test('debe retornar failure cuando bio es muy larga', () {
        // Arrange
        final bio = 'a' * 161;

        // Act
        final result = AuthValidator.validateBio(bio);

        // Assert
        expect(result, isA<ValidationFailure>());
        expect(result?.code, ErrorCode.invalidInput);
      });

      test('debe aceptar bio en longitud máxima (160)', () {
        // Arrange
        final bio = 'a' * 160; // Exactamente 160 caracteres

        // Act
        final result = AuthValidator.validateBio(bio);

        // Assert
        expect(result, isNull);
      });
    });
  });
}
