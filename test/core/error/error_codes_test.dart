import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/error/error_codes.dart';

void main() {
  group('ErrorCode', () {
    test('debe tener todos los códigos de error de red', () {
      // Assert
      expect(ErrorCode.values, contains(ErrorCode.networkError));
      expect(ErrorCode.values, contains(ErrorCode.timeoutError));
      expect(ErrorCode.values, contains(ErrorCode.noInternetConnection));
    });

    test('debe tener todos los códigos de error de servidor', () {
      // Assert
      expect(ErrorCode.values, contains(ErrorCode.serverError));
      expect(ErrorCode.values, contains(ErrorCode.serverMaintenance));
      expect(ErrorCode.values, contains(ErrorCode.serviceUnavailable));
      expect(ErrorCode.values, contains(ErrorCode.tooManyRequests));
      expect(ErrorCode.values, contains(ErrorCode.badRequest));
    });

    test('debe tener todos los códigos de error de autenticación', () {
      // Assert
      expect(ErrorCode.values, contains(ErrorCode.unauthorized));
      expect(ErrorCode.values, contains(ErrorCode.sessionExpired));
      expect(ErrorCode.values, contains(ErrorCode.invalidCredentials));
      expect(ErrorCode.values, contains(ErrorCode.emailAlreadyInUse));
      expect(ErrorCode.values, contains(ErrorCode.weakPassword));
      expect(ErrorCode.values, contains(ErrorCode.userNotFound));
      expect(ErrorCode.values, contains(ErrorCode.userNotAuthenticated));
      expect(ErrorCode.values, contains(ErrorCode.usernameAlreadyTaken));
      expect(ErrorCode.values, contains(ErrorCode.invalidToken));
      expect(ErrorCode.values, contains(ErrorCode.expiredToken));
      expect(ErrorCode.values, contains(ErrorCode.oauthCancelled));
      expect(ErrorCode.values, contains(ErrorCode.oauthProviderError));
      expect(ErrorCode.values, contains(ErrorCode.emailNotVerified));
      expect(ErrorCode.values, contains(ErrorCode.tooManyLoginAttempts));
    });

    test('debe tener todos los códigos de error de validación', () {
      // Assert
      expect(ErrorCode.values, contains(ErrorCode.validationError));
      expect(ErrorCode.values, contains(ErrorCode.invalidInput));
      expect(ErrorCode.values, contains(ErrorCode.missingRequiredField));
    });

    test('debe tener todos los códigos de error de datos', () {
      // Assert
      expect(ErrorCode.values, contains(ErrorCode.notFound));
      expect(ErrorCode.values, contains(ErrorCode.alreadyExists));
      expect(ErrorCode.values, contains(ErrorCode.conflict));
    });

    test('debe tener todos los códigos de error de permisos', () {
      // Assert
      expect(ErrorCode.values, contains(ErrorCode.forbidden));
      expect(ErrorCode.values, contains(ErrorCode.insufficientPermissions));
    });

    test('debe tener todos los códigos de error de negocio', () {
      // Assert
      expect(ErrorCode.values, contains(ErrorCode.invalidLocation));
      expect(ErrorCode.values, contains(ErrorCode.invalidGossipContent));
      expect(ErrorCode.values, contains(ErrorCode.gossipNotFound));
      expect(ErrorCode.values, contains(ErrorCode.moderationRejected));
      expect(ErrorCode.values, contains(ErrorCode.mediaUploadFailed));
      expect(ErrorCode.values, contains(ErrorCode.rateLimitExceeded));
      expect(ErrorCode.values, contains(ErrorCode.accountRestricted));
      expect(ErrorCode.values, contains(ErrorCode.accountSuspended));
      expect(ErrorCode.values, contains(ErrorCode.usernameChangeCooldown));
      expect(ErrorCode.values, contains(ErrorCode.usernameReserved));
      expect(ErrorCode.values, contains(ErrorCode.moderationUnavailable));
      expect(ErrorCode.values, contains(ErrorCode.invalidImage));
    });

    test('debe tener código de error desconocido', () {
      // Assert
      expect(ErrorCode.values, contains(ErrorCode.unknownError));
    });

    test('debe tener exactamente 43 códigos de error', () {
      // Assert
      expect(ErrorCode.values, hasLength(43));
    });

    test('enum values debe contener solo valores de ErrorCode', () {
      // Assert
      for (final code in ErrorCode.values) {
        expect(code, isA<ErrorCode>());
      }
    });

    test('debe poder comparar códigos de error por identidad', () {
      // Arrange
      const code1 = ErrorCode.networkError;
      const code2 = ErrorCode.networkError;
      const code3 = ErrorCode.timeoutError;

      // Assert
      expect(code1 == code2, isTrue);
      expect(code1 == code3, isFalse);
    });

    test('debe tener toString() con nombre del enum', () {
      // Arrange
      const code = ErrorCode.networkError;

      // Act
      final string = code.toString();

      // Assert
      expect(string, contains('ErrorCode.networkError'));
    });

    test('debe poder obtener código por index', () {
      // Act
      final firstCode = ErrorCode.values[0];
      final lastCode = ErrorCode.values[ErrorCode.values.length - 1];

      // Assert
      expect(firstCode, equals(ErrorCode.networkError));
      expect(lastCode, equals(ErrorCode.unknownError));
    });
  });
}
