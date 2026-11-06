import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/usecases/get_current_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_current_user_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late GetCurrentUserUseCase useCase;
  late MockAuthRepository mockRepository;

  // Provide dummy values for Mockito
  provideDummy<Result<Failure, User?>>(
    Result.success(null),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(mockRepository);
  });

  group('GetCurrentUserUseCase', () {
    final tUser = User(
      id: 'test-id-123',
      email: 'test@example.com',
          emailVerified: true,
      username: 'testuser',
      displayName: 'Test User',
      profileCompleted: true,
      createdAt: DateTime(2024, 1, 1),
    );

    group('call', () {
      test('debe retornar User cuando hay usuario autenticado', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user, isNotNull);
            expect(user, tUser);
            expect(user?.id, tUser.id);
            expect(user?.email, tUser.email);
            expect(user?.username, tUser.username);
          },
        );
        verify(mockRepository.getCurrentUser()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe retornar null cuando no hay usuario autenticado', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user, isNull);
          },
        );
        verify(mockRepository.getCurrentUser()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe retornar NetworkFailure cuando hay error de red', () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<NetworkFailure>());
            expect(error.code, ErrorCode.networkError);
            expect(error.technicalMessage, 'Network error');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.getCurrentUser()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe retornar AuthFailure cuando hay error de autenticación',
          () async {
        // Arrange
        final failure = AuthFailure(
          code: ErrorCode.invalidToken,
          technicalMessage: 'Invalid token',
        );
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<AuthFailure>());
            expect(error.code, ErrorCode.invalidToken);
            expect(error.technicalMessage, 'Invalid token');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('debe retornar ServerFailure cuando hay error del servidor',
          () async {
        // Arrange
        final failure = ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: 'Server error',
        );
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ServerFailure>());
            expect(error.code, ErrorCode.serverError);
            expect(error.technicalMessage, 'Server error');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('debe retornar DataFailure cuando hay error de datos', () async {
        // Arrange
        final failure = DataFailure(
          code: ErrorCode.notFound,
          technicalMessage: 'Data error',
        );
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<DataFailure>());
            expect(error.code, ErrorCode.notFound);
            expect(error.technicalMessage, 'Data error');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.getCurrentUser()).called(1);
      });

      test('debe llamar al repository solo una vez', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => Result.success(tUser));

        // Act
        await useCase();

        // Assert
        verify(mockRepository.getCurrentUser()).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe propagar Result correctamente sin modificarlo', () async {
        // Arrange
        final expectedResult = Result<Failure, User?>.success(tUser);
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => expectedResult);

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, expectedResult.isSuccess);
        expect(result.isFailure, expectedResult.isFailure);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expectedResult.when(
              onFailure: (_) {},
              onSuccess: (expectedUser) {
                expect(user, expectedUser);
              },
            );
          },
        );
      });

      test('debe funcionar con múltiples llamadas consecutivas', () async {
        // Arrange
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => Result.success(tUser));

        // Act
        final result1 = await useCase();
        final result2 = await useCase();
        final result3 = await useCase();

        // Assert
        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        expect(result3.isSuccess, isTrue);
        verify(mockRepository.getCurrentUser()).called(3);
      });

      test('debe manejar cambios de estado entre llamadas', () async {
        // Arrange - Primera llamada: usuario autenticado
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => Result.success(tUser));

        // Act
        final result1 = await useCase();

        // Assert
        expect(result1.isSuccess, isTrue);
        result1.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) => expect(user, isNotNull),
        );

        // Arrange - Segunda llamada: usuario deslogueado
        when(mockRepository.getCurrentUser())
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result2 = await useCase();

        // Assert
        expect(result2.isSuccess, isTrue);
        result2.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) => expect(user, isNull),
        );

        verify(mockRepository.getCurrentUser()).called(2);
      });
    });
  });
}
