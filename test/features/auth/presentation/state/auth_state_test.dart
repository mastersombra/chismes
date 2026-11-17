import 'package:chismes/core/error/custom_error_keys.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthState', () {
    group('AuthInitial', () {
      test('debe crear instancia', () {
        // Act
        const state = AuthInitial();

        // Assert
        expect(state, isA<AuthState>());
        expect(state, isA<AuthInitial>());
      });

      test('debe ser const', () {
        // Arrange
        const state1 = AuthInitial();
        const state2 = AuthInitial();

        // Assert
        expect(identical(state1, state2), isTrue);
      });
    });

    group('AuthLoading', () {
      test('debe crear instancia', () {
        // Act
        const state = AuthLoading();

        // Assert
        expect(state, isA<AuthState>());
        expect(state, isA<AuthLoading>());
      });

      test('debe ser const', () {
        // Arrange
        const state1 = AuthLoading();
        const state2 = AuthLoading();

        // Assert
        expect(identical(state1, state2), isTrue);
      });
    });

    group('AuthSuccess', () {
      final testUser = User(
        id: '123',
        email: 'test@example.com',
          emailVerified: true,
        username: 'testuser',
        displayName: 'Test User',
        profileCompleted: true,
        createdAt: DateTime(2024, 1, 1),
      );

      test('debe crear instancia con usuario', () {
        // Act
        final state = AuthSuccess(testUser);

        // Assert
        expect(state, isA<AuthState>());
        expect(state, isA<AuthSuccess>());
        expect(state.user, testUser);
      });

      test('debe mantener referencia al usuario', () {
        // Act
        final state = AuthSuccess(testUser);

        // Assert
        expect(state.user.id, '123');
        expect(state.user.email, 'test@example.com');
        expect(state.user.username, 'testuser');
        expect(state.user.displayName, 'Test User');
        expect(state.user.profileCompleted, isTrue);
      });

      test('debe permitir usuario sin username', () {
        // Arrange
        final userWithoutUsername = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime(2024, 1, 1),
        );

        // Act
        final state = AuthSuccess(userWithoutUsername);

        // Assert
        expect(state.user.username, isNull);
      });
    });

    group('AuthError', () {
      test('debe crear instancia con failure', () {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Invalid credentials',
        );

        // Act
        final state = AuthError(failure);

        // Assert
        expect(state, isA<AuthState>());
        expect(state, isA<AuthError>());
        expect(state.errorCode, ErrorCode.invalidCredentials);
        expect(state.customMessageKey, isNull);
      });

      test('debe guardar ErrorCode desde failure', () {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Invalid credentials',
        );

        // Act
        final state = AuthError(failure);

        // Assert - guarda el errorCode, no el mensaje
        expect(state.errorCode, ErrorCode.invalidCredentials);
      });

      test('debe funcionar con diferentes tipos de failure', () {
        // Arrange
        const authFailure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Auth error',
        );
        const networkFailure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        const validationFailure = ValidationFailure(
          code: ErrorCode.invalidInput,
          technicalMessage: 'Validation error',
        );

        // Act
        final state1 = AuthError(authFailure);
        final state2 = AuthError(networkFailure);
        final state3 = AuthError(validationFailure);

        // Assert - debe guardar los códigos correctamente
        expect(state1.errorCode, ErrorCode.invalidCredentials);
        expect(state2.errorCode, ErrorCode.networkError);
        expect(state3.errorCode, ErrorCode.invalidInput);
      });

      test('debe crear instancia con customMessageKey', () {
        // Act
        const state = AuthError.withMessageKey(
            CustomErrorKey.authEmailAlreadyInUseAction);

        // Assert
        expect(state, isA<AuthState>());
        expect(state, isA<AuthError>());
        expect(state.errorCode, isNull);
        expect(
            state.customMessageKey, CustomErrorKey.authEmailAlreadyInUseAction);
      });

      test('withMessageKey debe ser const', () {
        // Arrange
        const state1 = AuthError.withMessageKey(
            CustomErrorKey.authEmailAlreadyInUseAction);
        const state2 = AuthError.withMessageKey(
            CustomErrorKey.authEmailAlreadyInUseAction);

        // Assert
        expect(identical(state1, state2), isTrue);
      });
    });

    group('AuthOtpSent', () {
      test('debe crear instancia con email', () {
        // Act
        const state = AuthOtpSent('test@example.com');

        // Assert
        expect(state, isA<AuthState>());
        expect(state, isA<AuthOtpSent>());
        expect(state.email, equals('test@example.com'));
      });

      test('debe mantener email correcto', () {
        // Act
        const state = AuthOtpSent('user@test.com');

        // Assert
        expect(state.email, equals('user@test.com'));
      });
    });

    group('AuthPasswordUpdated', () {
      test('debe crear instancia', () {
        // Act
        const state = AuthPasswordUpdated();

        // Assert
        expect(state, isA<AuthState>());
        expect(state, isA<AuthPasswordUpdated>());
      });

      test('debe ser const', () {
        // Arrange
        const state1 = AuthPasswordUpdated();
        const state2 = AuthPasswordUpdated();

        // Assert
        expect(identical(state1, state2), isTrue);
      });
    });

    group('AuthUnauthenticated', () {
      test('debe crear instancia', () {
        // Act
        const state = AuthUnauthenticated();

        // Assert
        expect(state, isA<AuthState>());
        expect(state, isA<AuthUnauthenticated>());
      });

      test('debe ser const', () {
        // Arrange
        const state1 = AuthUnauthenticated();
        const state2 = AuthUnauthenticated();

        // Assert
        expect(identical(state1, state2), isTrue);
      });
    });

    group('Herencia de AuthState', () {
      test('todos los estados deben ser subtipos de AuthState', () {
        // Arrange
        const initial = AuthInitial();
        const loading = AuthLoading();
        final success = AuthSuccess(
          User(
            id: '123',
            email: 'test@example.com',
          emailVerified: true,
            profileCompleted: false,
            createdAt: DateTime.now(),
          ),
        );
        final error = AuthError(
          const AuthFailure(
            code: ErrorCode.invalidCredentials,
            technicalMessage: 'Error',
          ),
        );
        const unauthenticated = AuthUnauthenticated();

        // Assert
        expect(initial, isA<AuthState>());
        expect(loading, isA<AuthState>());
        expect(success, isA<AuthState>());
        expect(error, isA<AuthState>());
        expect(unauthenticated, isA<AuthState>());
      });

      test('estados diferentes deben ser tipos diferentes', () {
        // Arrange
        const initial = AuthInitial();
        const loading = AuthLoading();
        const unauthenticated = AuthUnauthenticated();

        // Assert
        expect(initial is AuthLoading, isFalse);
        expect(initial is AuthUnauthenticated, isFalse);
        expect(loading is AuthInitial, isFalse);
        expect(loading is AuthUnauthenticated, isFalse);
        expect(unauthenticated is AuthInitial, isFalse);
        expect(unauthenticated is AuthLoading, isFalse);
      });
    });

    group('Casos de uso comunes', () {
      test('debe poder distinguir entre estados usando type checking', () {
        // Arrange
        const AuthState initialState = AuthInitial();
        const AuthState loadingState = AuthLoading();
        final AuthState successState = AuthSuccess(
          User(
            id: '123',
            email: 'test@example.com',
          emailVerified: true,
            profileCompleted: false,
            createdAt: DateTime.now(),
          ),
        );

        // Assert
        expect(initialState is AuthInitial, isTrue);
        expect(loadingState is AuthLoading, isTrue);
        expect(successState is AuthSuccess, isTrue);
      });

      test('debe poder extraer datos de estados específicos', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime.now(),
        );
        const failure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Error',
        );

        final AuthState successState = AuthSuccess(user);
        final AuthState errorState = AuthError(failure);

        // Act & Assert
        if (successState is AuthSuccess) {
          expect(successState.user, user);
        }

        if (errorState is AuthError) {
          expect(errorState.errorCode, ErrorCode.invalidCredentials);
        }
      });
    });
  });
}
