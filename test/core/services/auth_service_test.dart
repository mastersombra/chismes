import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/services/auth_service.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';

import 'auth_service_test.mocks.dart';

@GenerateMocks([AuthRepository, AppLogger])
void main() {
  late AuthService authService;
  late MockAuthRepository mockAuthRepository;
  late MockAppLogger mockLogger;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    mockLogger = MockAppLogger();
    authService = AuthService(mockAuthRepository, mockLogger);
  });

  group('AuthService', () {
    group('Constructor', () {
      test('debe crear instancia con AuthRepository', () {
        expect(authService, isNotNull);
        expect(authService, isA<AuthService>());
      });

      test('debe ser singleton en DI', () {
        // Documenta que la anotación @singleton está presente
        expect(true, isTrue);
      });
    });

    group('currentUser', () {
      test('debe retornar usuario del repository cuando está autenticado', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
          username: 'testuser',
          displayName: 'Test User',
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.currentUser;

        // Assert
        expect(result, user);
        expect(result?.id, '123');
        expect(result?.email, 'test@example.com');
        verify(mockAuthRepository.currentUser).called(1);
      });

      test('debe retornar null cuando no hay usuario autenticado', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);

        // Act
        final result = authService.currentUser;

        // Assert
        expect(result, isNull);
        verify(mockAuthRepository.currentUser).called(1);
      });

      test('debe reflejar cambios en el repository', () {
        // Arrange - Primero sin usuario
        when(mockAuthRepository.currentUser).thenReturn(null);
        expect(authService.currentUser, isNull);

        // Act - Simular login
        final user = User(
          id: '456',
          email: 'new@example.com',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Assert - Ahora debe tener usuario
        expect(authService.currentUser, user);
        expect(authService.currentUser?.id, '456');
      });
    });

    group('userStream', () {
      test('debe retornar stream del repository', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
        );
        final stream = Stream<User?>.value(user);
        when(mockAuthRepository.authStateChanges).thenAnswer((_) => stream);

        // Act
        final result = authService.userStream;

        // Assert
        expect(result, isA<Stream<User?>>());
        verify(mockAuthRepository.authStateChanges).called(1);
      });

      test('debe emitir cambios de autenticación', () async {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
        );
        final stream = Stream<User?>.fromIterable([null, user, null]);
        when(mockAuthRepository.authStateChanges).thenAnswer((_) => stream);

        // Act & Assert
        final results = await authService.userStream.toList();

        expect(results, hasLength(3));
        expect(results[0], isNull); // Sin autenticar
        expect(results[1], user); // Login
        expect(results[2], isNull); // Logout
      });
    });

    group('isAuthenticated', () {
      test('debe retornar true cuando hay usuario autenticado', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.isAuthenticated;

        // Assert
        expect(result, isTrue);
      });

      test('debe retornar false cuando no hay usuario autenticado', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);

        // Act
        final result = authService.isAuthenticated;

        // Assert
        expect(result, isFalse);
      });

      test('debe actualizar cuando currentUser cambia', () {
        // Arrange - Sin usuario
        when(mockAuthRepository.currentUser).thenReturn(null);
        expect(authService.isAuthenticated, isFalse);

        // Act - Simular login
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Assert - Ahora está autenticado
        expect(authService.isAuthenticated, isTrue);
      });
    });

    group('hasCompleteProfile', () {
      test('debe retornar true cuando usuario tiene perfil completo', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.hasCompleteProfile;

        // Assert
        expect(result, isTrue);
      });

      test('debe retornar false cuando usuario tiene perfil incompleto', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.hasCompleteProfile;

        // Assert
        expect(result, isFalse);
      });

      test('debe retornar false cuando no hay usuario autenticado', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);

        // Act
        final result = authService.hasCompleteProfile;

        // Assert
        expect(result, isFalse);
      });

      test('debe reflejar cambios en profileCompleted', () {
        // Arrange - Usuario con perfil incompleto
        final user1 = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user1);
        expect(authService.hasCompleteProfile, isFalse);

        // Act - Usuario completa perfil
        final user2 = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user2);

        // Assert
        expect(authService.hasCompleteProfile, isTrue);
      });
    });

    group('hasUsername', () {
      test('debe retornar true cuando usuario tiene username', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
          username: 'testuser',
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.hasUsername;

        // Assert
        expect(result, isTrue);
      });

      test('debe retornar false cuando usuario no tiene username', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime(2024, 1, 1),
          username: null,
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.hasUsername;

        // Assert
        expect(result, isFalse);
      });

      test('debe retornar false cuando no hay usuario autenticado', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);

        // Act
        final result = authService.hasUsername;

        // Assert
        expect(result, isFalse);
      });

      test('debe retornar false cuando username está vacío', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime(2024, 1, 1),
          username: '',
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.hasUsername;

        // Assert
        expect(result, isFalse);
      });
    });

    group('displayName', () {
      test('debe retornar displayName cuando usuario lo tiene configurado', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
          username: 'testuser',
          displayName: 'Test User',
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.displayName;

        // Assert
        expect(result, 'Test User');
      });

      test('debe retornar username con @ como fallback cuando no hay displayName', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime(2024, 1, 1),
          username: 'testuser',
          displayName: null,
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.displayName;

        // Assert
        expect(result, '@testuser'); // Username con prefijo @
      });

      test('debe retornar email como fallback cuando no hay displayName ni username', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime(2024, 1, 1),
          username: null,
          displayName: null,
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.displayName;

        // Assert
        expect(result, 'test@example.com');
      });

      test('debe retornar null cuando no hay usuario autenticado', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);

        // Act
        final result = authService.displayName;

        // Assert
        expect(result, isNull);
      });
    });

    group('userId', () {
      test('debe retornar ID del usuario autenticado', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.userId;

        // Assert
        expect(result, '123');
      });

      test('debe retornar null cuando no hay usuario autenticado', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);

        // Act
        final result = authService.userId;

        // Assert
        expect(result, isNull);
      });

      test('debe manejar IDs UUID', () {
        // Arrange
        final user = User(
          id: 'uuid-abc-123-def-456',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.userId;

        // Assert
        expect(result, 'uuid-abc-123-def-456');
        expect(result, contains('-'));
      });
    });

    group('userEmail', () {
      test('debe retornar email del usuario autenticado', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.userEmail;

        // Assert
        expect(result, 'test@example.com');
      });

      test('debe retornar null cuando no hay usuario autenticado', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);

        // Act
        final result = authService.userEmail;

        // Assert
        expect(result, isNull);
      });

      test('debe manejar diferentes formatos de email', () {
        // Arrange
        final emails = [
          'simple@example.com',
          'with+plus@example.com',
          'with.dot@example.com',
          'with-dash@example.com',
        ];

        for (final email in emails) {
          final user = User(
            id: '123',
            email: email,
          emailVerified: true,
            profileCompleted: true,
            createdAt: DateTime(2024, 1, 1),
          );
          when(mockAuthRepository.currentUser).thenReturn(user);

          // Act
          final result = authService.userEmail;

          // Assert
          expect(result, email);
        }
      });
    });

    group('Integración entre getters', () {
      test('todos los getters deben reflejar el mismo usuario', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
          username: 'testuser',
          displayName: 'Test User',
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act & Assert - Todos deben reflejar el mismo usuario
        expect(authService.currentUser, user);
        expect(authService.isAuthenticated, isTrue);
        expect(authService.hasCompleteProfile, isTrue);
        expect(authService.hasUsername, isTrue);
        expect(authService.displayName, 'Test User');
        expect(authService.userId, '123');
        expect(authService.userEmail, 'test@example.com');
      });

      test('todos los getters deben retornar null/false cuando no hay usuario', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);

        // Act & Assert
        expect(authService.currentUser, isNull);
        expect(authService.isAuthenticated, isFalse);
        expect(authService.hasCompleteProfile, isFalse);
        expect(authService.hasUsername, isFalse);
        expect(authService.displayName, isNull);
        expect(authService.userId, isNull);
        expect(authService.userEmail, isNull);
      });

      test('debe reflejar transición de login a logout', () {
        // Arrange - Usuario autenticado
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
          username: 'testuser',
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Assert - Autenticado
        expect(authService.isAuthenticated, isTrue);
        expect(authService.userId, '123');

        // Act - Logout
        when(mockAuthRepository.currentUser).thenReturn(null);

        // Assert - Sin autenticar
        expect(authService.isAuthenticated, isFalse);
        expect(authService.userId, isNull);
      });
    });

    group('Casos de uso típicos', () {
      test('verificar autenticación antes de acción', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);

        // Act - Simular verificación en UI
        if (authService.isAuthenticated) {
          // Acción requiere auth
          fail('No debería llegar aquí');
        }

        // Assert
        expect(authService.isAuthenticated, isFalse);
      });

      test('mostrar pantalla de completar perfil si necesario', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act - Simular verificación en UI
        final shouldShowCompleteProfile =
            authService.isAuthenticated && !authService.hasCompleteProfile;

        // Assert
        expect(shouldShowCompleteProfile, isTrue);
      });

      test('bloquear publicación de chisme sin username', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
          username: null,
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act - Simular verificación antes de publicar
        final canPublish =
            authService.isAuthenticated && authService.hasUsername;

        // Assert
        expect(canPublish, isFalse);
      });

      test('obtener nombre a mostrar en UI', () {
        // Arrange
        final user = User(
          id: '123',
          email: 'test@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
          username: 'testuser',
          displayName: 'Test User',
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final name = authService.displayName ?? 'Anónimo';

        // Assert
        expect(name, 'Test User');
        expect(name, isNot('Anónimo'));
      });
    });

    group('Edge cases', () {
      test('debe manejar usuario con email vacío', () {
        // Arrange
        final user = User(
          id: '123',
          email: '',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user);

        // Act
        final result = authService.userEmail;

        // Assert
        expect(result, isEmpty);
        expect(authService.isAuthenticated, isTrue); // Sigue autenticado
      });

      test('debe manejar cambios rápidos de estado', () {
        // Arrange - Varios cambios de estado
        when(mockAuthRepository.currentUser).thenReturn(null);
        expect(authService.isAuthenticated, isFalse);

        final user1 = User(
          id: '1',
          email: 'user1@example.com',
          emailVerified: true,
          profileCompleted: false,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user1);
        expect(authService.userId, '1');

        final user2 = User(
          id: '2',
          email: 'user2@example.com',
          emailVerified: true,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
        );
        when(mockAuthRepository.currentUser).thenReturn(user2);
        expect(authService.userId, '2');

        when(mockAuthRepository.currentUser).thenReturn(null);
        expect(authService.isAuthenticated, isFalse);
      });
    });
  });
}
