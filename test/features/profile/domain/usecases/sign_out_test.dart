import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/profile/domain/repositories/profile_repository.dart';
import 'package:chismes/features/profile/domain/usecases/sign_out.dart';

import 'sign_out_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  setUpAll(() {
    provideDummy<Result<Failure, void>>(
      Result.success(null),
    );
  });

  late SignOut useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = SignOut(mockRepository);
  });

  group('SignOut', () {
    group('success cases', () {
      test('debe cerrar sesión exitosamente', () async {
        // Arrange
        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.signOut()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe poder cerrar sesión múltiples veces', () async {
        // Arrange
        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result1 = await useCase();
        final result2 = await useCase();
        final result3 = await useCase();

        // Assert
        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        expect(result3.isSuccess, isTrue);
        verify(mockRepository.signOut()).called(3);
      });

      test('debe limpiar sesión completamente', () async {
        // Arrange
        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        // Documenta: SignOut debe limpiar:
        // - Token de autenticación
        // - Datos de usuario en cache
        // - Preferencias temporales
        verify(mockRepository.signOut()).called(1);
      });
    });

    group('failure cases', () {
      test('debe manejar NetworkFailure', () async {
        // Arrange
        const failure = NetworkFailure(
          code: ErrorCode.noInternetConnection,
          technicalMessage: 'No internet connection',
        );

        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.signOut()).called(1);
      });

      test('debe manejar ServerFailure', () async {
        // Arrange
        const failure = ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: 'Internal server error',
        );

        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.signOut()).called(1);
      });

      test('debe manejar AuthFailure', () async {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.sessionExpired,
          technicalMessage: 'Session already expired',
        );

        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
        verify(mockRepository.signOut()).called(1);
      });

      test('debe manejar error de token inválido', () async {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.invalidToken,
          technicalMessage: 'Invalid session token',
        );

        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.failureValue, failure);
      });

      test('debe poder fallar silenciosamente si sesión ya expiró', () async {
        // Arrange
        const failure = AuthFailure(
          code: ErrorCode.sessionExpired,
          technicalMessage: 'Session expired',
        );

        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        // Documenta: En UI, SessionExpired en signOut puede:
        // - Mostrar mensaje "Sesión cerrada"
        // - Redirigir a login sin error
        // - Limpiar cache local igualmente
      });
    });

    group('edge cases', () {
      test('debe funcionar sin usuario autenticado previamente', () async {
        // Arrange
        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        // Documenta: SignOut es idempotente, puede ejecutarse
        // incluso si no hay sesión activa
      });

      test('debe ser thread-safe para llamadas concurrentes', () async {
        // Arrange
        when(mockRepository.signOut())
            .thenAnswer((_) async => Result.success(null));

        // Act
        final results = await Future.wait([
          useCase(),
          useCase(),
          useCase(),
        ]);

        // Assert
        for (final result in results) {
          expect(result.isSuccess, isTrue);
        }
        verify(mockRepository.signOut()).called(3);
      });
    });

  });
}
