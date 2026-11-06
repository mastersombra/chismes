import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/usecases/sign_out.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sign_out_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignOutUseCase useCase;
  late MockAuthRepository mockRepository;

  // Provide dummy values for Mockito
  provideDummy<Result<Failure, void>>(
    Result.success(null),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignOutUseCase(mockRepository);
  });

  group('SignOutUseCase', () {
    group('success cases', () {
      test('debe retornar success cuando el sign out es exitoso', () async {
        // Arrange
        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (_) {
            // Success - void return
          },
        );
        verify(mockRepository.signOut()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });
    });

    group('repository failures', () {
      test('debe propagar NetworkFailure del repository', () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        when(mockRepository.signOut())
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
        verify(mockRepository.signOut()).called(1);
      });

      test('debe propagar ServerFailure del repository', () async {
        // Arrange
        final failure = ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: 'Server error',
        );
        when(mockRepository.signOut())
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
        verify(mockRepository.signOut()).called(1);
      });

      test('debe propagar AuthFailure del repository', () async {
        // Arrange
        final failure = AuthFailure(
          code: ErrorCode.sessionExpired,
          technicalMessage: 'Session expired',
        );
        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<AuthFailure>());
            expect(error.code, ErrorCode.sessionExpired);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.signOut()).called(1);
      });

      test('debe propagar NetworkFailure (no internet) del repository',
          () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.noInternetConnection,
          technicalMessage: 'No internet',
        );
        when(mockRepository.signOut())
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
        verify(mockRepository.signOut()).called(1);
      });

      test('debe propagar NetworkFailure (timeout) del repository', () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.timeoutError,
          technicalMessage: 'Timeout',
        );
        when(mockRepository.signOut())
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
        verify(mockRepository.signOut()).called(1);
      });
    });

    group('edge cases', () {
      test('debe manejar múltiples intentos de sign out consecutivos',
          () async {
        // Arrange
        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.success(null));

        // Act
        await useCase();
        await useCase();
        await useCase();

        // Assert
        verify(mockRepository.signOut()).called(3);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe manejar alternancia entre success y failure', () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );

        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.success(null));

        // Act & Assert - Primera llamada exitosa
        final result1 = await useCase();
        expect(result1.isSuccess, isTrue);

        // Cambiar comportamiento para simular error
        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.failure(failure));

        // Act & Assert - Segunda llamada fallida
        final result2 = await useCase();
        expect(result2.isFailure, isTrue);

        // Verificar llamadas
        verify(mockRepository.signOut()).called(2);
      });

      test('debe llamar al repository sin parámetros', () async {
        // Arrange
        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.success(null));

        // Act
        await useCase();

        // Assert - Verificar que se llamó sin argumentos
        verify(mockRepository.signOut()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe retornar resultado independiente en cada llamada', () async {
        // Arrange
        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result1 = await useCase();
        final result2 = await useCase();

        // Assert - Ambas llamadas exitosas e independientes
        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        verify(mockRepository.signOut()).called(2);
      });
    });
  });
}
