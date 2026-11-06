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
        const state = AuthError(failure);

        // Assert
        expect(state, isA<AuthState>());
        expect(state, isA<AuthError>());
        expect(state.failure, failure);
      });

      test('debe retornar mensaje traducido desde ErrorMessages', () {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Invalid credentials',
        );

        // Act
        const state = AuthError(failure);

        // Assert - debe retornar mensaje traducido, no technicalMessage
        expect(state.message, 'Email o contraseña incorrectos. Por favor, verifica tus datos e intenta nuevamente.');
      });

      test('debe retornar mensaje traducido incluso sin technicalMessage', () {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.invalidCredentials,
        );

        // Act
        const state = AuthError(failure);

        // Assert - debe retornar mensaje traducido basado en el código
        expect(state.message, 'Email o contraseña incorrectos. Por favor, verifica tus datos e intenta nuevamente.');
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
        const state1 = AuthError(authFailure);
        const state2 = AuthError(networkFailure);
        const state3 = AuthError(validationFailure);

        // Assert - debe retornar mensajes traducidos basados en los códigos
        expect(state1.message, 'Email o contraseña incorrectos. Por favor, verifica tus datos e intenta nuevamente.');
        expect(state2.message, 'Error de conexión. Por favor verifica tu internet.');
        expect(state3.message, 'Dato inválido. Verifica el formato.');
      });

      test('debe exponer el failure original', () {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Invalid credentials',
        );

        // Act
        const state = AuthError(failure);

        // Assert
        expect(state.failure, isA<AuthFailure>());
        expect(state.failure!.code, ErrorCode.invalidCredentials);
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
        const error = AuthError(
          AuthFailure(
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
        const AuthState errorState = AuthError(failure);

        // Act & Assert
        if (successState is AuthSuccess) {
          expect(successState.user, user);
        }

        if (errorState is AuthError) {
          expect(errorState.failure, failure);
          expect(errorState.message, 'Email o contraseña incorrectos. Por favor, verifica tus datos e intenta nuevamente.');
        }
      });
    });
  });
}
