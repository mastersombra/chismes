import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'update_password_usecase_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late UpdatePasswordUseCase useCase;
  late MockAuthRepository mockRepository;

  // Provide dummy values for Mockito
  provideDummy<Result<Failure, void>>(Result.success(null));

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = UpdatePasswordUseCase(mockRepository);
  });

  group('UpdatePasswordUseCase', () {
    const validPassword = 'ValidPass123!';

    group('password validation failures', () {
      test('debe retornar ValidationFailure cuando password es vacío', () async {
        // Act
        final result = await useCase(newPassword: '');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.missingRequiredField);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.updatePassword(
          newPassword: anyNamed('newPassword'),
        ));
      });

      test('debe retornar ValidationFailure cuando password es muy corto', () async {
        // Act
        final result = await useCase(newPassword: 'Short1!');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.weakPassword);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.updatePassword(
          newPassword: anyNamed('newPassword'),
        ));
      });

      test('debe retornar ValidationFailure cuando password es muy largo', () async {
        // Act
        final result = await useCase(newPassword: 'A' * 129 + '1!');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.updatePassword(
          newPassword: anyNamed('newPassword'),
        ));
      });

      test('debe retornar ValidationFailure cuando no tiene minúscula', () async {
        // Act
        final result = await useCase(newPassword: 'PASSWORD123!');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.weakPassword);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure cuando no tiene mayúscula', () async {
        // Act
        final result = await useCase(newPassword: 'password123!');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.weakPassword);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure cuando no tiene número', () async {
        // Act
        final result = await useCase(newPassword: 'Password!');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.weakPassword);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure cuando no tiene carácter especial', () async {
        // Act
        final result = await useCase(newPassword: 'Password123');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.weakPassword);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });
    });

    group('success cases', () {
      test('debe actualizar password cuando es válido', () async {
        // Arrange
        when(mockRepository.updatePassword(
          newPassword: validPassword,
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(newPassword: validPassword);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updatePassword(
          newPassword: validPassword,
        )).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe aceptar password con longitud mínima (8)', () async {
        // Arrange
        const minPassword = 'Pass123!';
        when(mockRepository.updatePassword(
          newPassword: minPassword,
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(newPassword: minPassword);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updatePassword(
          newPassword: minPassword,
        )).called(1);
      });

      test('debe aceptar password con longitud máxima (128)', () async {
        // Arrange
        final maxPassword = 'Aa' * 63 + '1!'; // 128 caracteres con mayúsculas, minúsculas, número y especial
        when(mockRepository.updatePassword(
          newPassword: maxPassword,
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(newPassword: maxPassword);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updatePassword(
          newPassword: maxPassword,
        )).called(1);
      });

      test('debe aceptar password con múltiples caracteres especiales', () async {
        // Arrange
        const password = 'Pass123!@#\$';
        when(mockRepository.updatePassword(
          newPassword: password,
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(newPassword: password);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updatePassword(
          newPassword: password,
        )).called(1);
      });

      test('debe aceptar password con espacios', () async {
        // Arrange
        const password = 'Pass 123 !';
        when(mockRepository.updatePassword(
          newPassword: password,
        )).thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(newPassword: password);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updatePassword(
          newPassword: password,
        )).called(1);
      });
    });

    group('repository failures', () {
      test('debe propagar WeakPasswordFailure del repository', () async {
        // Arrange
        final failure = AuthFailure(
          code: ErrorCode.weakPassword,
          technicalMessage: 'Weak password',
        );
        when(mockRepository.updatePassword(
          newPassword: validPassword,
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(newPassword: validPassword);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<AuthFailure>());
            expect(error.code, ErrorCode.weakPassword);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.updatePassword(
          newPassword: validPassword,
        )).called(1);
      });

      test('debe propagar NetworkFailure del repository', () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        when(mockRepository.updatePassword(
          newPassword: validPassword,
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(newPassword: validPassword);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<NetworkFailure>());
            expect(error.code, ErrorCode.networkError);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe propagar ServerFailure del repository', () async {
        // Arrange
        final failure = ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: 'Server error',
        );
        when(mockRepository.updatePassword(
          newPassword: validPassword,
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(newPassword: validPassword);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ServerFailure>());
            expect(error.code, ErrorCode.serverError);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });
    });

    group('edge cases', () {
      test('no debe llamar al repository si validación falla', () async {
        // Act
        await useCase(newPassword: '');
        await useCase(newPassword: 'short');
        await useCase(newPassword: 'nouppercaseornumber!');

        // Assert
        verifyNever(mockRepository.updatePassword(
          newPassword: anyNamed('newPassword'),
        ));
      });

      test('debe manejar múltiples actualizaciones consecutivas', () async {
        // Arrange
        when(mockRepository.updatePassword(
          newPassword: anyNamed('newPassword'),
        )).thenAnswer((_) async => Result.success(null));

        // Act
        await useCase(newPassword: 'Password1!');
        await useCase(newPassword: 'Password2!');
        await useCase(newPassword: 'Password3!');

        // Assert
        verify(mockRepository.updatePassword(
          newPassword: anyNamed('newPassword'),
        )).called(3);
      });
    });
  });
}
