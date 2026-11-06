import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';

void main() {
  group('Failure', () {
    test('props debe incluir code y technicalMessage', () {
      // Arrange
      const failure = Failure(
        code: ErrorCode.unknownError,
        technicalMessage: 'Test message',
      );

      // Act
      final props = failure.props;

      // Assert
      expect(props, [ErrorCode.unknownError, 'Test message']);
      expect(props.length, 2);
    });

    test('props debe incluir code y null cuando no hay technicalMessage', () {
      // Arrange
      const failure = Failure(code: ErrorCode.unknownError);

      // Act
      final props = failure.props;

      // Assert
      expect(props, [ErrorCode.unknownError, null]);
      expect(props.length, 2);
    });

    test('toString debe incluir code y technicalMessage', () {
      // Arrange
      const failure = Failure(
        code: ErrorCode.unknownError,
        technicalMessage: 'Something went wrong',
      );

      // Act
      final result = failure.toString();

      // Assert
      expect(result, 'Failure: ErrorCode.unknownError - Something went wrong');
      expect(result, contains('ErrorCode.unknownError'));
      expect(result, contains('Something went wrong'));
    });

    test('toString debe incluir solo code cuando no hay technicalMessage', () {
      // Arrange
      const failure = Failure(code: ErrorCode.networkError);

      // Act
      final result = failure.toString();

      // Assert
      expect(result, 'Failure: ErrorCode.networkError');
      expect(result, contains('ErrorCode.networkError'));
      expect(result, isNot(contains(' - ')));
    });

    test('debe ser igual cuando code y technicalMessage son iguales', () {
      // Arrange
      const failure1 = Failure(
        code: ErrorCode.serverError,
        technicalMessage: 'Server timeout',
      );
      const failure2 = Failure(
        code: ErrorCode.serverError,
        technicalMessage: 'Server timeout',
      );

      // Assert
      expect(failure1, equals(failure2));
      expect(failure1.hashCode, equals(failure2.hashCode));
    });

    test('debe ser diferente cuando code es diferente', () {
      // Arrange
      const failure1 = Failure(code: ErrorCode.networkError);
      const failure2 = Failure(code: ErrorCode.serverError);

      // Assert
      expect(failure1, isNot(equals(failure2)));
    });

    test('debe ser diferente cuando technicalMessage es diferente', () {
      // Arrange
      const failure1 = Failure(
        code: ErrorCode.unknownError,
        technicalMessage: 'Message 1',
      );
      const failure2 = Failure(
        code: ErrorCode.unknownError,
        technicalMessage: 'Message 2',
      );

      // Assert
      expect(failure1, isNot(equals(failure2)));
    });
  });

  group('NetworkFailure', () {
    test('debe crear instancia con code y technicalMessage', () {
      // Arrange & Act
      const failure = NetworkFailure(
        code: ErrorCode.networkError,
        technicalMessage: 'Connection timeout',
      );

      // Assert
      expect(failure.code, ErrorCode.networkError);
      expect(failure.technicalMessage, 'Connection timeout');
      expect(failure, isA<Failure>());
    });

    test('debe crear instancia sin technicalMessage', () {
      // Arrange & Act
      const failure = NetworkFailure(code: ErrorCode.networkError);

      // Assert
      expect(failure.code, ErrorCode.networkError);
      expect(failure.technicalMessage, isNull);
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const failure = NetworkFailure(
        code: ErrorCode.networkError,
        technicalMessage: 'No internet',
      );

      // Act
      final result = failure.toString();

      // Assert
      expect(result, contains('ErrorCode.networkError'));
      expect(result, contains('No internet'));
    });
  });

  group('ServerFailure', () {
    test('debe crear instancia con code y technicalMessage', () {
      // Arrange & Act
      const failure = ServerFailure(
        code: ErrorCode.serverError,
        technicalMessage: 'Internal server error',
      );

      // Assert
      expect(failure.code, ErrorCode.serverError);
      expect(failure.technicalMessage, 'Internal server error');
      expect(failure, isA<Failure>());
    });

    test('debe crear instancia sin technicalMessage', () {
      // Arrange & Act
      const failure = ServerFailure(code: ErrorCode.serverError);

      // Assert
      expect(failure.code, ErrorCode.serverError);
      expect(failure.technicalMessage, isNull);
    });

    test('debe crear instancia con message del servidor', () {
      // Arrange & Act
      const failure = ServerFailure(
        code: ErrorCode.tooManyRequests,
        message: 'Has alcanzado el límite de 10 chismes por hora',
        technicalMessage: 'Rate limit exceeded: 10 req/hour',
      );

      // Assert
      expect(failure.code, ErrorCode.tooManyRequests);
      expect(failure.message, 'Has alcanzado el límite de 10 chismes por hora');
      expect(failure.technicalMessage, 'Rate limit exceeded: 10 req/hour');
    });

    test('debe crear instancia solo con message (sin technicalMessage)', () {
      // Arrange & Act
      const failure = ServerFailure(
        code: ErrorCode.serverError,
        message: 'El servidor está temporalmente no disponible',
      );

      // Assert
      expect(failure.code, ErrorCode.serverError);
      expect(failure.message, 'El servidor está temporalmente no disponible');
      expect(failure.technicalMessage, isNull);
    });

    test('message debe ser null si no se proporciona', () {
      // Arrange & Act
      const failure = ServerFailure(
        code: ErrorCode.serverError,
        technicalMessage: 'Internal error',
      );

      // Assert
      expect(failure.message, isNull);
    });

    test('props debe incluir code, technicalMessage y message', () {
      // Arrange
      const failure = ServerFailure(
        code: ErrorCode.tooManyRequests,
        technicalMessage: 'Rate limit',
        message: 'Demasiadas solicitudes',
      );

      // Act
      final props = failure.props;

      // Assert
      expect(props.length, 3);
      expect(props[0], ErrorCode.tooManyRequests);
      expect(props[1], 'Rate limit');
      expect(props[2], 'Demasiadas solicitudes');
    });

    test('debe ser igual cuando code, technicalMessage y message son iguales', () {
      // Arrange
      const failure1 = ServerFailure(
        code: ErrorCode.serverError,
        technicalMessage: 'Tech message',
        message: 'User message',
      );
      const failure2 = ServerFailure(
        code: ErrorCode.serverError,
        technicalMessage: 'Tech message',
        message: 'User message',
      );

      // Assert
      expect(failure1, equals(failure2));
      expect(failure1.hashCode, equals(failure2.hashCode));
    });

    test('debe ser diferente cuando message es diferente', () {
      // Arrange
      const failure1 = ServerFailure(
        code: ErrorCode.serverError,
        message: 'Message 1',
      );
      const failure2 = ServerFailure(
        code: ErrorCode.serverError,
        message: 'Message 2',
      );

      // Assert
      expect(failure1, isNot(equals(failure2)));
    });

    test('debe ser diferente cuando uno tiene message y el otro no', () {
      // Arrange
      const failure1 = ServerFailure(
        code: ErrorCode.serverError,
        message: 'Has a message',
      );
      const failure2 = ServerFailure(
        code: ErrorCode.serverError,
      );

      // Assert
      expect(failure1, isNot(equals(failure2)));
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const failure = ServerFailure(
        code: ErrorCode.serverError,
        technicalMessage: '500 error',
      );

      // Act
      final result = failure.toString();

      // Assert
      expect(result, contains('ErrorCode.serverError'));
      expect(result, contains('500 error'));
    });
  });

  group('AuthFailure', () {
    test('debe crear instancia con code y technicalMessage', () {
      // Arrange & Act
      const failure = AuthFailure(
        code: ErrorCode.unauthorized,
        technicalMessage: 'Invalid credentials',
      );

      // Assert
      expect(failure.code, ErrorCode.unauthorized);
      expect(failure.technicalMessage, 'Invalid credentials');
      expect(failure, isA<Failure>());
    });

    test('debe crear instancia sin technicalMessage', () {
      // Arrange & Act
      const failure = AuthFailure(code: ErrorCode.sessionExpired);

      // Assert
      expect(failure.code, ErrorCode.sessionExpired);
      expect(failure.technicalMessage, isNull);
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const failure = AuthFailure(
        code: ErrorCode.invalidCredentials,
        technicalMessage: 'Token expired',
      );

      // Act
      final result = failure.toString();

      // Assert
      expect(result, contains('ErrorCode.invalidCredentials'));
      expect(result, contains('Token expired'));
    });
  });

  group('DataFailure', () {
    test('debe crear instancia con code y technicalMessage', () {
      // Arrange & Act
      const failure = DataFailure(
        code: ErrorCode.notFound,
        technicalMessage: 'Corrupted data',
      );

      // Assert
      expect(failure.code, ErrorCode.notFound);
      expect(failure.technicalMessage, 'Corrupted data');
      expect(failure, isA<Failure>());
    });

    test('debe crear instancia sin technicalMessage', () {
      // Arrange & Act
      const failure = DataFailure(code: ErrorCode.alreadyExists);

      // Assert
      expect(failure.code, ErrorCode.alreadyExists);
      expect(failure.technicalMessage, isNull);
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const failure = DataFailure(
        code: ErrorCode.conflict,
        technicalMessage: 'Parse error',
      );

      // Act
      final result = failure.toString();

      // Assert
      expect(result, contains('ErrorCode.conflict'));
      expect(result, contains('Parse error'));
    });
  });

  group('PermissionFailure', () {
    test('debe crear instancia con code y technicalMessage', () {
      // Arrange & Act
      const failure = PermissionFailure(
        code: ErrorCode.forbidden,
        technicalMessage: 'Location permission denied',
      );

      // Assert
      expect(failure.code, ErrorCode.forbidden);
      expect(failure.technicalMessage, 'Location permission denied');
      expect(failure, isA<Failure>());
    });

    test('debe crear instancia sin technicalMessage', () {
      // Arrange & Act
      const failure = PermissionFailure(code: ErrorCode.insufficientPermissions);

      // Assert
      expect(failure.code, ErrorCode.insufficientPermissions);
      expect(failure.technicalMessage, isNull);
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const failure = PermissionFailure(
        code: ErrorCode.forbidden,
        technicalMessage: 'Camera access denied',
      );

      // Act
      final result = failure.toString();

      // Assert
      expect(result, contains('ErrorCode.forbidden'));
      expect(result, contains('Camera access denied'));
    });
  });

  group('RateLimitFailure', () {
    test('debe crear instancia con code y technicalMessage', () {
      // Arrange & Act
      const failure = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        technicalMessage: 'Rate limit exceeded',
      );

      // Assert
      expect(failure.code, ErrorCode.rateLimitExceeded);
      expect(failure.technicalMessage, 'Rate limit exceeded');
      expect(failure, isA<Failure>());
    });

    test('debe crear instancia sin technicalMessage', () {
      // Arrange & Act
      const failure = RateLimitFailure(code: ErrorCode.rateLimitExceeded);

      // Assert
      expect(failure.code, ErrorCode.rateLimitExceeded);
      expect(failure.technicalMessage, isNull);
    });

    test('debe crear instancia con message', () {
      // Arrange & Act
      const failure = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        message: 'Has alcanzado el límite de solicitudes',
        technicalMessage: 'Rate limit: 10 req/hour',
      );

      // Assert
      expect(failure.code, ErrorCode.rateLimitExceeded);
      expect(failure.message, 'Has alcanzado el límite de solicitudes');
      expect(failure.technicalMessage, 'Rate limit: 10 req/hour');
    });

    test('debe crear instancia con retryAfter', () {
      // Arrange & Act
      const failure = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        retryAfter: 3600,
        technicalMessage: 'Rate limit exceeded',
      );

      // Assert
      expect(failure.code, ErrorCode.rateLimitExceeded);
      expect(failure.retryAfter, 3600);
      expect(failure.technicalMessage, 'Rate limit exceeded');
    });

    test('debe crear instancia con message y retryAfter', () {
      // Arrange & Act
      const failure = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        message: 'Demasiadas solicitudes, intenta en 1 hora',
        retryAfter: 3600,
        technicalMessage: 'Rate limit: 10 req/hour',
      );

      // Assert
      expect(failure.code, ErrorCode.rateLimitExceeded);
      expect(failure.message, 'Demasiadas solicitudes, intenta en 1 hora');
      expect(failure.retryAfter, 3600);
      expect(failure.technicalMessage, 'Rate limit: 10 req/hour');
    });

    test('message debe ser null si no se proporciona', () {
      // Arrange & Act
      const failure = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        technicalMessage: 'Rate limit',
      );

      // Assert
      expect(failure.message, isNull);
    });

    test('retryAfter debe ser null si no se proporciona', () {
      // Arrange & Act
      const failure = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        technicalMessage: 'Rate limit',
      );

      // Assert
      expect(failure.retryAfter, isNull);
    });

    test('props debe incluir code, technicalMessage, message y retryAfter', () {
      // Arrange
      const failure = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        technicalMessage: 'Rate limit',
        message: 'Too many requests',
        retryAfter: 1800,
      );

      // Act
      final props = failure.props;

      // Assert
      expect(props.length, 4);
      expect(props[0], ErrorCode.rateLimitExceeded);
      expect(props[1], 'Rate limit');
      expect(props[2], 'Too many requests');
      expect(props[3], 1800);
    });

    test('debe ser igual cuando code, technicalMessage, message y retryAfter son iguales', () {
      // Arrange
      const failure1 = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        technicalMessage: 'Tech message',
        message: 'User message',
        retryAfter: 3600,
      );
      const failure2 = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        technicalMessage: 'Tech message',
        message: 'User message',
        retryAfter: 3600,
      );

      // Assert
      expect(failure1, equals(failure2));
      expect(failure1.hashCode, equals(failure2.hashCode));
    });

    test('debe ser diferente cuando message es diferente', () {
      // Arrange
      const failure1 = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        message: 'Message 1',
      );
      const failure2 = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        message: 'Message 2',
      );

      // Assert
      expect(failure1, isNot(equals(failure2)));
    });

    test('debe ser diferente cuando retryAfter es diferente', () {
      // Arrange
      const failure1 = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        retryAfter: 3600,
      );
      const failure2 = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        retryAfter: 1800,
      );

      // Assert
      expect(failure1, isNot(equals(failure2)));
    });

    test('debe ser diferente cuando uno tiene message y el otro no', () {
      // Arrange
      const failure1 = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        message: 'Has a message',
      );
      const failure2 = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
      );

      // Assert
      expect(failure1, isNot(equals(failure2)));
    });

    test('debe ser diferente cuando uno tiene retryAfter y el otro no', () {
      // Arrange
      const failure1 = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        retryAfter: 3600,
      );
      const failure2 = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
      );

      // Assert
      expect(failure1, isNot(equals(failure2)));
    });

    test('toString debe funcionar correctamente', () {
      // Arrange
      const failure = RateLimitFailure(
        code: ErrorCode.rateLimitExceeded,
        technicalMessage: 'Rate limit exceeded',
      );

      // Act
      final result = failure.toString();

      // Assert
      expect(result, contains('ErrorCode.rateLimitExceeded'));
      expect(result, contains('Rate limit exceeded'));
    });
  });

  group('ValidationFailure', () {
    test('debe tener igualdad estructural en fieldErrors', () {
      final errors1 = ValidationFailure(
        code: ErrorCode.validationError,
        fieldErrors: {
          'subject': 'too long',
          'content': 'required',
        },
      );

      final errors2 = ValidationFailure(
        code: ErrorCode.validationError,
        fieldErrors: {
          'subject': 'too long',
          'content': 'required',
        },
      );

      // Con UnmodifiableMapView, los mapas con el mismo contenido deben ser iguales
      expect(errors1, equals(errors2));
      expect(errors1.hashCode, equals(errors2.hashCode));
    });

    test('debe ser diferente si fieldErrors tienen contenido diferente', () {
      final errors1 = ValidationFailure(
        code: ErrorCode.validationError,
        fieldErrors: {
          'subject': 'too long',
          'content': 'required',
        },
      );

      final errors2 = ValidationFailure(
        code: ErrorCode.validationError,
        fieldErrors: {
          'subject': 'too short',
          'content': 'required',
        },
      );

      expect(errors1, isNot(equals(errors2)));
    });

    test('debe ser diferente si uno tiene fieldErrors y el otro no', () {
      final errors1 = ValidationFailure(
        code: ErrorCode.validationError,
        fieldErrors: {
          'subject': 'too long',
        },
      );

      final errors2 = ValidationFailure(
        code: ErrorCode.validationError,
      );

      expect(errors1, isNot(equals(errors2)));
    });

    test('debe ser igual si ambos tienen null en fieldErrors', () {
      final errors1 = ValidationFailure(
        code: ErrorCode.validationError,
      );

      final errors2 = ValidationFailure(
        code: ErrorCode.validationError,
      );

      expect(errors1, equals(errors2));
    });

    test('props debe incluir code, technicalMessage y fieldErrors', () {
      // Arrange
      const failure = ValidationFailure(
        code: ErrorCode.validationError,
        technicalMessage: 'Validation failed',
        fieldErrors: {'field': 'error'},
      );

      // Act
      final props = failure.props;

      // Assert
      expect(props.length, 3);
      expect(props[0], ErrorCode.validationError);
      expect(props[1], 'Validation failed');
      expect(props[2], isNotNull);
    });

    test('toString debe incluir technicalMessage', () {
      // Arrange
      const failure = ValidationFailure(
        code: ErrorCode.validationError,
        technicalMessage: 'Form validation failed',
      );

      // Act
      final result = failure.toString();

      // Assert
      expect(result, contains('ErrorCode.validationError'));
      expect(result, contains('Form validation failed'));
    });

    test('debe ser una subclase de Failure', () {
      // Arrange & Act
      const failure = ValidationFailure(code: ErrorCode.validationError);

      // Assert
      expect(failure, isA<Failure>());
    });
  });

  group('Failure Equatable', () {
    test('debe comparar correctamente instancias con mismos valores', () {
      // Arrange
      const failure1 = Failure(
        code: ErrorCode.unknownError,
        technicalMessage: 'Test',
      );
      const failure2 = Failure(
        code: ErrorCode.unknownError,
        technicalMessage: 'Test',
      );

      // Assert
      expect(failure1, equals(failure2));
      expect(failure1 == failure2, isTrue);
    });

    test('hashCode debe ser igual para instancias iguales', () {
      // Arrange
      const failure1 = Failure(code: ErrorCode.networkError);
      const failure2 = Failure(code: ErrorCode.networkError);

      // Assert
      expect(failure1.hashCode, equals(failure2.hashCode));
    });

    test('hashCode debe ser diferente para instancias diferentes', () {
      // Arrange
      const failure1 = Failure(code: ErrorCode.networkError);
      const failure2 = Failure(code: ErrorCode.serverError);

      // Assert
      expect(failure1.hashCode, isNot(equals(failure2.hashCode)));
    });
  });

  group('Failure Type Hierarchy', () {
    test('todos los tipos específicos deben extender Failure', () {
      // Arrange & Assert
      expect(const NetworkFailure(code: ErrorCode.networkError), isA<Failure>());
      expect(const ServerFailure(code: ErrorCode.serverError), isA<Failure>());
      expect(const AuthFailure(code: ErrorCode.unauthorized), isA<Failure>());
      expect(const ValidationFailure(code: ErrorCode.validationError), isA<Failure>());
      expect(const DataFailure(code: ErrorCode.notFound), isA<Failure>());
      expect(const PermissionFailure(code: ErrorCode.forbidden), isA<Failure>());
      expect(const RateLimitFailure(code: ErrorCode.rateLimitExceeded), isA<Failure>());
    });

    test('NetworkFailure no debe ser ServerFailure', () {
      // Arrange
      const networkFailure = NetworkFailure(code: ErrorCode.networkError);

      // Assert
      expect(networkFailure, isNot(isA<ServerFailure>()));
      expect(networkFailure, isNot(isA<AuthFailure>()));
    });

    test('ServerFailure no debe ser NetworkFailure', () {
      // Arrange
      const serverFailure = ServerFailure(code: ErrorCode.serverError);

      // Assert
      expect(serverFailure, isNot(isA<NetworkFailure>()));
      expect(serverFailure, isNot(isA<ValidationFailure>()));
    });
  });

  group('Failure Edge Cases', () {
    test('debe permitir technicalMessage vacío', () {
      // Arrange & Act
      const failure = Failure(
        code: ErrorCode.unknownError,
        technicalMessage: '',
      );

      // Assert
      expect(failure.technicalMessage, '');
      expect(failure.toString(), contains(' - '));
    });

    test('ValidationFailure con fieldErrors vacío debe ser válido', () {
      // Arrange & Act
      const failure = ValidationFailure(
        code: ErrorCode.validationError,
        fieldErrors: {},
      );

      // Assert
      expect(failure.fieldErrors, isEmpty);
      expect(failure.props.length, 3);
    });

    test('ValidationFailure con múltiples fieldErrors debe mantener todos', () {
      // Arrange
      final errors = {
        'subject': 'Demasiado largo',
        'content': 'Requerido',
        'cityId': 'Inválido',
        'imageUrl': 'Formato incorrecto',
      };

      // Act
      final failure = ValidationFailure(
        code: ErrorCode.validationError,
        fieldErrors: errors,
      );

      // Assert
      expect(failure.fieldErrors, equals(errors));
      expect(failure.fieldErrors?.length, 4);
    });

    test('ServerFailure message puede ser string largo', () {
      // Arrange
      const longMessage = 'Este es un mensaje muy largo del servidor que '
          'contiene muchos detalles sobre el error que ocurrió y '
          'proporciona información útil al usuario sobre cómo resolverlo';

      // Act
      const failure = ServerFailure(
        code: ErrorCode.serverError,
        message: longMessage,
      );

      // Assert
      expect(failure.message, longMessage);
      expect(failure.message?.length, greaterThan(100));
    });

    test('Failure con technicalMessage null debe tener props con null', () {
      // Arrange
      const failure = Failure(code: ErrorCode.networkError);

      // Act
      final props = failure.props;

      // Assert
      expect(props, [ErrorCode.networkError, null]);
      expect(props.contains(null), isTrue);
    });

    test('diferentes tipos de Failure con mismo code no deben ser iguales', () {
      // Arrange
      const network = NetworkFailure(code: ErrorCode.unknownError);
      const server = ServerFailure(code: ErrorCode.unknownError);
      const auth = AuthFailure(code: ErrorCode.unknownError);

      // Assert
      expect(network, isNot(equals(server)));
      expect(server, isNot(equals(auth)));
      expect(network, isNot(equals(auth)));
    });

    test('toString debe manejar caracteres especiales en technicalMessage', () {
      // Arrange
      const failure = Failure(
        code: ErrorCode.unknownError,
        technicalMessage: 'Error with "quotes" and \'apostrophes\' and\nnewlines',
      );

      // Act
      final result = failure.toString();

      // Assert
      expect(result, contains('Error with'));
      expect(result, contains('"quotes"'));
      expect(result, contains('\'apostrophes\''));
    });
  });
}
