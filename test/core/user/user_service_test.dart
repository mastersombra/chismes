import 'package:chismes/core/user/user_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserService', () {
    late UserService userService;

    setUp(() {
      userService = UserService();
      // Limpiar estado entre tests
      userService.logout();
    });

    group('Singleton', () {
      test('debe retornar la misma instancia', () {
        // Arrange & Act
        final instance1 = UserService();
        final instance2 = UserService();

        // Assert
        expect(instance1, same(instance2));
      });

      test('debe mantener estado entre instancias', () {
        // Arrange
        final instance1 = UserService();
        instance1.setCurrentUser('user-123');

        // Act
        final instance2 = UserService();
        final user = instance2.getCurrentUser();

        // Assert
        expect(user, equals('user-123'));

        // Cleanup
        instance1.logout();
      });
    });

    group('getCurrentUser', () {
      test('debe retornar null cuando no hay usuario autenticado', () {
        // Act
        final user = userService.getCurrentUser();

        // Assert
        expect(user, isNull);
      });

      test('debe retornar el usuario después de setCurrentUser', () {
        // Arrange
        const userId = 'user-123';
        userService.setCurrentUser(userId);

        // Act
        final user = userService.getCurrentUser();

        // Assert
        expect(user, equals(userId));
      });

      test('debe retornar null después de logout', () {
        // Arrange
        userService.setCurrentUser('user-123');
        userService.logout();

        // Act
        final user = userService.getCurrentUser();

        // Assert
        expect(user, isNull);
      });
    });

    group('setCurrentUser', () {
      test('debe establecer el usuario correctamente', () {
        // Arrange
        const userId = 'user-abc-123';

        // Act
        userService.setCurrentUser(userId);

        // Assert
        expect(userService.getCurrentUser(), equals(userId));
      });

      test('debe sobrescribir el usuario anterior', () {
        // Arrange
        userService.setCurrentUser('user-old');

        // Act
        userService.setCurrentUser('user-new');

        // Assert
        expect(userService.getCurrentUser(), equals('user-new'));
      });

      test('debe lanzar ArgumentError cuando userId está vacío', () {
        // Act & Assert
        expect(
          () => userService.setCurrentUser(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('debe incluir mensaje de error cuando userId está vacío', () {
        // Act & Assert
        expect(
          () => userService.setCurrentUser(''),
          throwsA(
            predicate(
              (e) =>
                  e is ArgumentError &&
                  e.message.toString().contains('userId no puede estar vacío'),
            ),
          ),
        );
      });

      test('debe aceptar userId con espacios', () {
        // Arrange
        const userId = 'user with spaces';

        // Act
        userService.setCurrentUser(userId);

        // Assert
        expect(userService.getCurrentUser(), equals(userId));
      });

      test('debe aceptar userId con caracteres especiales', () {
        // Arrange
        const userId = 'user-123_abc@domain.com';

        // Act
        userService.setCurrentUser(userId);

        // Assert
        expect(userService.getCurrentUser(), equals(userId));
      });
    });

    group('logout', () {
      test('debe limpiar el usuario actual', () {
        // Arrange
        userService.setCurrentUser('user-123');

        // Act
        userService.logout();

        // Assert
        expect(userService.getCurrentUser(), isNull);
      });

      test('debe ser idempotente', () {
        // Arrange
        userService.setCurrentUser('user-123');

        // Act
        userService.logout();
        userService.logout(); // Llamar dos veces

        // Assert
        expect(userService.getCurrentUser(), isNull);
      });

      test('debe funcionar cuando no hay usuario autenticado', () {
        // Act & Assert - no debe lanzar excepción
        expect(() => userService.logout(), returnsNormally);
        expect(userService.getCurrentUser(), isNull);
      });
    });

    group('isAuthenticated', () {
      test('debe retornar false cuando no hay usuario', () {
        // Act
        final isAuth = userService.isAuthenticated();

        // Assert
        expect(isAuth, isFalse);
      });

      test('debe retornar true cuando hay usuario autenticado', () {
        // Arrange
        userService.setCurrentUser('user-123');

        // Act
        final isAuth = userService.isAuthenticated();

        // Assert
        expect(isAuth, isTrue);
      });

      test('debe retornar false después de logout', () {
        // Arrange
        userService.setCurrentUser('user-123');
        userService.logout();

        // Act
        final isAuth = userService.isAuthenticated();

        // Assert
        expect(isAuth, isFalse);
      });
    });

    group('Flujo completo', () {
      test('debe manejar ciclo completo de autenticación', () {
        // Arrange & Act
        expect(userService.isAuthenticated(), isFalse);
        expect(userService.getCurrentUser(), isNull);

        // Login
        userService.setCurrentUser('user-abc');
        expect(userService.isAuthenticated(), isTrue);
        expect(userService.getCurrentUser(), equals('user-abc'));

        // Change user
        userService.setCurrentUser('user-xyz');
        expect(userService.isAuthenticated(), isTrue);
        expect(userService.getCurrentUser(), equals('user-xyz'));

        // Logout
        userService.logout();
        expect(userService.isAuthenticated(), isFalse);
        expect(userService.getCurrentUser(), isNull);
      });
    });
  });
}
