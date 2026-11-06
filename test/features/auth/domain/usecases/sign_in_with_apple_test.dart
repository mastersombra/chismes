import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sign_in_with_apple_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignInWithAppleUseCase useCase;
  late MockAuthRepository mockRepository;

  // Provide dummy values for Mockito
  provideDummy<Result<Failure, User>>(
    Result.success(
      User(
        id: 'test-id',
        email: 'test@example.com',
          emailVerified: true,
        username: 'testuser',
        displayName: 'Test User',
        bio: null,
        avatarUrl: null,
        profileCompleted: true,
        createdAt: DateTime(2024),
        updatedAt: null,
      ),
    ),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithAppleUseCase(mockRepository);
  });

  group('SignInWithAppleUseCase', () {
    final tUser = User(
      id: 'user-123',
      email: 'apple.user@example.com',
          emailVerified: true,
      username: 'appleuser',
      displayName: 'Apple User',
      bio: null,
      avatarUrl: 'https://example.com/avatar.jpg',
      profileCompleted: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    group('success cases', () {
      test('debe retornar User cuando el sign in con Apple es exitoso',
          () async {
        // Arrange
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user, equals(tUser));
            expect(user.id, 'user-123');
            expect(user.email, 'apple.user@example.com');
            expect(user.username, 'appleuser');
            expect(user.displayName, 'Apple User');
            expect(user.profileCompleted, isTrue);
          },
        );
        verify(mockRepository.signInWithApple()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe retornar User con datos mínimos requeridos', () async {
        // Arrange
        final minimalUser = User(
          id: 'min-id',
          email: 'min@example.com',
          emailVerified: true,
          username: 'minuser',
          displayName: 'Min',
          bio: null,
          avatarUrl: null,
          profileCompleted: false,
          createdAt: DateTime(2024),
          updatedAt: null,
        );

        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.success(minimalUser));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user, equals(minimalUser));
            expect(user.bio, isNull);
            expect(user.avatarUrl, isNull);
            expect(user.profileCompleted, isFalse);
          },
        );
        verify(mockRepository.signInWithApple()).called(1);
      });
    });

    group('repository failures', () {
      test('debe propagar AuthFailure (OAuth cancelled) del repository',
          () async {
        // Arrange
        final failure = AuthFailure(
          code: ErrorCode.oauthCancelled,
          technicalMessage: 'User cancelled OAuth',
        );
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<AuthFailure>());
            expect(error.code, ErrorCode.oauthCancelled);
            expect(error.technicalMessage, 'User cancelled OAuth');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.signInWithApple()).called(1);
      });

      test('debe propagar AuthFailure (OAuth provider error) del repository',
          () async {
        // Arrange
        final failure = AuthFailure(
          code: ErrorCode.oauthProviderError,
          technicalMessage: 'Apple OAuth error',
        );
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<AuthFailure>());
            expect(error.code, ErrorCode.oauthProviderError);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.signInWithApple()).called(1);
      });

      test('debe propagar NetworkFailure del repository', () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<NetworkFailure>());
            expect(error.code, ErrorCode.networkError);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.signInWithApple()).called(1);
      });

      test('debe propagar ServerFailure del repository', () async {
        // Arrange
        final failure = ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: 'Server error',
        );
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ServerFailure>());
            expect(error.code, ErrorCode.serverError);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.signInWithApple()).called(1);
      });

      test('debe propagar AuthFailure (invalid credentials) del repository',
          () async {
        // Arrange
        final failure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Invalid credentials',
        );
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<AuthFailure>());
            expect(error.code, ErrorCode.invalidCredentials);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.signInWithApple()).called(1);
      });

      test('debe propagar NetworkFailure (no internet) del repository',
          () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.noInternetConnection,
          technicalMessage: 'No internet',
        );
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<NetworkFailure>());
            expect(error.code, ErrorCode.noInternetConnection);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.signInWithApple()).called(1);
      });

      test('debe propagar NetworkFailure (timeout) del repository', () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.timeoutError,
          technicalMessage: 'Timeout',
        );
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<NetworkFailure>());
            expect(error.code, ErrorCode.timeoutError);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.signInWithApple()).called(1);
      });
    });

    group('edge cases', () {
      test('debe manejar múltiples intentos de sign in consecutivos', () async {
        // Arrange
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.success(tUser));

        // Act
        await useCase();
        await useCase();
        await useCase();

        // Assert
        verify(mockRepository.signInWithApple()).called(3);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe manejar alternancia entre success y failure', () async {
        // Arrange
        final failure = AuthFailure(
          code: ErrorCode.oauthCancelled,
          technicalMessage: 'Cancelled',
        );

        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.success(tUser));

        // Act & Assert - Primera llamada exitosa
        final result1 = await useCase();
        expect(result1.isSuccess, isTrue);

        // Cambiar comportamiento para simular cancelación
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.failure(failure));

        // Act & Assert - Segunda llamada fallida
        final result2 = await useCase();
        expect(result2.isFailure, isTrue);

        // Verificar llamadas
        verify(mockRepository.signInWithApple()).called(2);
      });

      test('debe retornar resultado independiente en cada llamada', () async {
        // Arrange
        final user1 = User(
          id: 'user-1',
          email: 'user1@example.com',
          emailVerified: true,
          username: 'user1',
          displayName: 'User 1',
          bio: null,
          avatarUrl: null,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
          updatedAt: null,
        );

        final user2 = User(
          id: 'user-2',
          email: 'user2@example.com',
          emailVerified: true,
          username: 'user2',
          displayName: 'User 2',
          bio: null,
          avatarUrl: null,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 2),
          updatedAt: null,
        );

        // Configurar respuestas diferentes
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.success(user1));

        // Act - Primera llamada
        final result1 = await useCase();

        // Cambiar respuesta
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.success(user2));

        // Act - Segunda llamada
        final result2 = await useCase();

        // Assert
        result1.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) => expect(user.id, 'user-1'),
        );

        result2.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) => expect(user.id, 'user-2'),
        );

        verify(mockRepository.signInWithApple()).called(2);
      });

      test('debe llamar al repository sin parámetros', () async {
        // Arrange
        when(mockRepository.signInWithApple())
            .thenAnswer((_) async => Result.success(tUser));

        // Act
        await useCase();

        // Assert - Verificar que se llamó sin argumentos
        verify(mockRepository.signInWithApple()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });
    });
  });
}
