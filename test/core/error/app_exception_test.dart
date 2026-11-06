import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/error/app_exception.dart';
import 'package:chismes/core/error/error_codes.dart';

void main() {
  group('AppException', () {
    test('toString debe incluir code y technicalMessage', () {
      // Arrange
      const exception = NetworkException(
        code: ErrorCode.networkError,
        technicalMessage: 'Connection timeout',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, 'AppException: ErrorCode.networkError - Connection timeout');
      expect(result, contains('ErrorCode.networkError'));
      expect(result, contains('Connection timeout'));
    });

    test('toString debe incluir solo code cuando no hay technicalMessage', () {
      // Arrange
      const exception = NetworkException(code: ErrorCode.networkError);

      // Act
      final result = exception.toString();

      // Assert
      expect(result, 'AppException: ErrorCode.networkError');
      expect(result, contains('ErrorCode.networkError'));
      expect(result, isNot(contains(' - ')));
    });

    test('debe almacenar originalError y stackTrace', () {
      // Arrange
      final originalError = Exception('Original error');
      final stackTrace = StackTrace.current;
      final exception = NetworkException(
        code: ErrorCode.networkError,
        originalError: originalError,
        stackTrace: stackTrace,
      );

      // Assert
      expect(exception.originalError, originalError);
      expect(exception.stackTrace, stackTrace);
    });

    test('debe ser lanzable como Exception', () {
      // Arrange & Act & Assert
      expect(
        () => throw const NetworkException(code: ErrorCode.networkError),
        throwsA(isA<Exception>()),
      );
    });

    test('debe ser lanzable como AppException', () {
      // Arrange & Act & Assert
      expect(
        () => throw const NetworkException(code: ErrorCode.networkError),
        throwsA(isA<AppException>()),
      );
    });
  });

  group('NetworkException', () {
    test('debe crear instancia con todos los parámetros', () {
      // Arrange
      final originalError = Exception('Network error');
      final stackTrace = StackTrace.current;

      // Act
      final exception = NetworkException(
        code: ErrorCode.networkError,
        technicalMessage: 'Connection failed',
        originalError: originalError,
        stackTrace: stackTrace,
      );

      // Assert
      expect(exception.code, ErrorCode.networkError);
      expect(exception.technicalMessage, 'Connection failed');
      expect(exception.originalError, originalError);
      expect(exception.stackTrace, stackTrace);
      expect(exception, isA<AppException>());
    });

    test('debe crear instancia solo con code', () {
      // Act
      const exception = NetworkException(code: ErrorCode.timeoutError);

      // Assert
      expect(exception.code, ErrorCode.timeoutError);
      expect(exception.technicalMessage, isNull);
      expect(exception.originalError, isNull);
      expect(exception.stackTrace, isNull);
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const exception = NetworkException(
        code: ErrorCode.noInternetConnection,
        technicalMessage: 'No internet',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('ErrorCode.noInternetConnection'));
      expect(result, contains('No internet'));
    });

    test('debe ser lanzable', () {
      // Arrange & Act & Assert
      expect(
        () => throw const NetworkException(
          code: ErrorCode.networkError,
          technicalMessage: 'Test',
        ),
        throwsA(predicate<NetworkException>(
          (e) =>
              e.code == ErrorCode.networkError &&
              e.technicalMessage == 'Test',
        )),
      );
    });
  });

  group('ServerException', () {
    test('debe crear instancia con statusCode', () {
      // Arrange
      final originalError = Exception('Server error');
      final stackTrace = StackTrace.current;

      // Act
      final exception = ServerException(
        code: ErrorCode.serverError,
        technicalMessage: 'Internal server error',
        statusCode: 500,
        originalError: originalError,
        stackTrace: stackTrace,
      );

      // Assert
      expect(exception.code, ErrorCode.serverError);
      expect(exception.technicalMessage, 'Internal server error');
      expect(exception.statusCode, 500);
      expect(exception.originalError, originalError);
      expect(exception.stackTrace, stackTrace);
      expect(exception, isA<AppException>());
    });

    test('debe crear instancia sin statusCode', () {
      // Act
      const exception = ServerException(code: ErrorCode.serverError);

      // Assert
      expect(exception.code, ErrorCode.serverError);
      expect(exception.statusCode, isNull);
    });

    test('debe manejar diferentes statusCodes', () {
      // Arrange & Act
      const exception404 = ServerException(
        code: ErrorCode.notFound,
        statusCode: 404,
      );
      const exception429 = ServerException(
        code: ErrorCode.tooManyRequests,
        statusCode: 429,
      );
      const exception503 = ServerException(
        code: ErrorCode.serviceUnavailable,
        statusCode: 503,
      );

      // Assert
      expect(exception404.statusCode, 404);
      expect(exception429.statusCode, 429);
      expect(exception503.statusCode, 503);
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const exception = ServerException(
        code: ErrorCode.serverError,
        technicalMessage: '500 error',
        statusCode: 500,
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('ErrorCode.serverError'));
      expect(result, contains('500 error'));
    });
  });

  group('AuthException', () {
    test('debe crear instancia con todos los parámetros', () {
      // Arrange
      final originalError = Exception('Auth error');
      final stackTrace = StackTrace.current;

      // Act
      final exception = AuthException(
        code: ErrorCode.unauthorized,
        technicalMessage: 'Invalid token',
        originalError: originalError,
        stackTrace: stackTrace,
      );

      // Assert
      expect(exception.code, ErrorCode.unauthorized);
      expect(exception.technicalMessage, 'Invalid token');
      expect(exception.originalError, originalError);
      expect(exception.stackTrace, stackTrace);
      expect(exception, isA<AppException>());
    });

    test('debe crear instancia solo con code', () {
      // Act
      const exception = AuthException(code: ErrorCode.sessionExpired);

      // Assert
      expect(exception.code, ErrorCode.sessionExpired);
      expect(exception.technicalMessage, isNull);
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const exception = AuthException(
        code: ErrorCode.invalidCredentials,
        technicalMessage: 'Wrong password',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('ErrorCode.invalidCredentials'));
      expect(result, contains('Wrong password'));
    });
  });

  group('ValidationException', () {
    test('debe crear instancia con fieldErrors', () {
      // Arrange
      final fieldErrors = {
        'email': 'Invalid format',
        'password': 'Too short',
      };
      final originalError = Exception('Validation error');
      final stackTrace = StackTrace.current;

      // Act
      final exception = ValidationException(
        code: ErrorCode.validationError,
        technicalMessage: 'Form validation failed',
        fieldErrors: fieldErrors,
        originalError: originalError,
        stackTrace: stackTrace,
      );

      // Assert
      expect(exception.code, ErrorCode.validationError);
      expect(exception.technicalMessage, 'Form validation failed');
      expect(exception.fieldErrors, fieldErrors);
      expect(exception.fieldErrors?['email'], 'Invalid format');
      expect(exception.fieldErrors?['password'], 'Too short');
      expect(exception.originalError, originalError);
      expect(exception.stackTrace, stackTrace);
      expect(exception, isA<AppException>());
    });

    test('debe crear instancia sin fieldErrors', () {
      // Act
      const exception = ValidationException(
        code: ErrorCode.invalidInput,
      );

      // Assert
      expect(exception.code, ErrorCode.invalidInput);
      expect(exception.fieldErrors, isNull);
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const exception = ValidationException(
        code: ErrorCode.missingRequiredField,
        technicalMessage: 'Required field missing',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('ErrorCode.missingRequiredField'));
      expect(result, contains('Required field missing'));
    });
  });

  group('DataException', () {
    test('debe crear instancia con todos los parámetros', () {
      // Arrange
      final originalError = Exception('Parse error');
      final stackTrace = StackTrace.current;

      // Act
      final exception = DataException(
        code: ErrorCode.notFound,
        technicalMessage: 'Resource not found',
        originalError: originalError,
        stackTrace: stackTrace,
      );

      // Assert
      expect(exception.code, ErrorCode.notFound);
      expect(exception.technicalMessage, 'Resource not found');
      expect(exception.originalError, originalError);
      expect(exception.stackTrace, stackTrace);
      expect(exception, isA<AppException>());
    });

    test('debe crear instancia solo con code', () {
      // Act
      const exception = DataException(code: ErrorCode.alreadyExists);

      // Assert
      expect(exception.code, ErrorCode.alreadyExists);
      expect(exception.technicalMessage, isNull);
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const exception = DataException(
        code: ErrorCode.conflict,
        technicalMessage: 'Data conflict',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('ErrorCode.conflict'));
      expect(result, contains('Data conflict'));
    });
  });

  group('PermissionException', () {
    test('debe crear instancia con todos los parámetros', () {
      // Arrange
      final originalError = Exception('Permission denied');
      final stackTrace = StackTrace.current;

      // Act
      final exception = PermissionException(
        code: ErrorCode.forbidden,
        technicalMessage: 'Access denied',
        originalError: originalError,
        stackTrace: stackTrace,
      );

      // Assert
      expect(exception.code, ErrorCode.forbidden);
      expect(exception.technicalMessage, 'Access denied');
      expect(exception.originalError, originalError);
      expect(exception.stackTrace, stackTrace);
      expect(exception, isA<AppException>());
    });

    test('debe crear instancia solo con code', () {
      // Act
      const exception = PermissionException(
        code: ErrorCode.insufficientPermissions,
      );

      // Assert
      expect(exception.code, ErrorCode.insufficientPermissions);
      expect(exception.technicalMessage, isNull);
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const exception = PermissionException(
        code: ErrorCode.forbidden,
        technicalMessage: 'No access',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('ErrorCode.forbidden'));
      expect(result, contains('No access'));
    });
  });

  group('UnknownException', () {
    test('debe crear instancia con todos los parámetros', () {
      // Arrange
      final originalError = Exception('Unknown error');
      final stackTrace = StackTrace.current;

      // Act
      final exception = UnknownException(
        code: ErrorCode.unknownError,
        technicalMessage: 'Something went wrong',
        originalError: originalError,
        stackTrace: stackTrace,
      );

      // Assert
      expect(exception.code, ErrorCode.unknownError);
      expect(exception.technicalMessage, 'Something went wrong');
      expect(exception.originalError, originalError);
      expect(exception.stackTrace, stackTrace);
      expect(exception, isA<AppException>());
    });

    test('debe crear instancia solo con code', () {
      // Act
      const exception = UnknownException(code: ErrorCode.unknownError);

      // Assert
      expect(exception.code, ErrorCode.unknownError);
      expect(exception.technicalMessage, isNull);
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const exception = UnknownException(
        code: ErrorCode.unknownError,
        technicalMessage: 'Unexpected error',
      );

      // Act
      final result = exception.toString();

      // Assert
      expect(result, contains('ErrorCode.unknownError'));
      expect(result, contains('Unexpected error'));
    });
  });

  group('Jerarquía de excepciones', () {
    test('todas las excepciones deben ser instancias de AppException', () {
      // Arrange & Act
      const network = NetworkException(code: ErrorCode.networkError);
      const server = ServerException(code: ErrorCode.serverError);
      const auth = AuthException(code: ErrorCode.unauthorized);
      const validation = ValidationException(code: ErrorCode.validationError);
      const data = DataException(code: ErrorCode.notFound);
      const permission = PermissionException(code: ErrorCode.forbidden);
      const unknown = UnknownException(code: ErrorCode.unknownError);

      // Assert
      expect(network, isA<AppException>());
      expect(server, isA<AppException>());
      expect(auth, isA<AppException>());
      expect(validation, isA<AppException>());
      expect(data, isA<AppException>());
      expect(permission, isA<AppException>());
      expect(unknown, isA<AppException>());
    });

    test('todas las excepciones deben ser instancias de Exception', () {
      // Arrange & Act
      const network = NetworkException(code: ErrorCode.networkError);
      const server = ServerException(code: ErrorCode.serverError);

      // Assert
      expect(network, isA<Exception>());
      expect(server, isA<Exception>());
    });
  });

  group('Casos de uso reales', () {
    test('NetworkException para timeout', () {
      // Act
      const exception = NetworkException(
        code: ErrorCode.timeoutError,
        technicalMessage: 'Request timeout after 30s',
      );

      // Assert
      expect(exception.code, ErrorCode.timeoutError);
      expect(exception.technicalMessage, contains('30s'));
    });

    test('ServerException con código 429', () {
      // Act
      const exception = ServerException(
        code: ErrorCode.tooManyRequests,
        statusCode: 429,
        technicalMessage: 'Rate limit exceeded',
      );

      // Assert
      expect(exception.statusCode, 429);
      expect(exception.code, ErrorCode.tooManyRequests);
    });

    test('ValidationException con múltiples campos', () {
      // Act
      const exception = ValidationException(
        code: ErrorCode.validationError,
        fieldErrors: {
          'subject': 'Required',
          'content': 'Too long',
          'city': 'Invalid',
        },
      );

      // Assert
      expect(exception.fieldErrors?.length, 3);
      expect(exception.fieldErrors?['subject'], 'Required');
      expect(exception.fieldErrors?['content'], 'Too long');
      expect(exception.fieldErrors?['city'], 'Invalid');
    });

    test('AuthException con error original', () {
      // Arrange
      final originalError = Exception('JWT expired');

      // Act
      final exception = AuthException(
        code: ErrorCode.sessionExpired,
        technicalMessage: 'Session expired',
        originalError: originalError,
      );

      // Assert
      expect(exception.originalError, originalError);
      expect(exception.code, ErrorCode.sessionExpired);
    });
  });
}
