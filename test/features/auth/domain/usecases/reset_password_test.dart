import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/usecases/reset_password.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'reset_password_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late ResetPasswordUseCase useCase;
  late MockAuthRepository mockRepository;

  // Provide dummy values for Mockito
  provideDummy<Result<Failure, void>>(
    Result.success(null),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = ResetPasswordUseCase(mockRepository);
  });

  group('ResetPasswordUseCase', () {
    const tValidEmail = 'test@example.com';

    group('validation failures', () {
      test('debe retornar ValidationFailure cuando email es empty', () async {
        // Act
        final result = await useCase(email: '');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.missingRequiredField);
            expect(error.technicalMessage, 'Email is required');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.resetPassword(email: anyNamed('email')));
      });

      test('debe retornar ValidationFailure cuando formato es inválido - sin @',
          () async {
        // Act
        final result = await useCase(email: 'invalidemail.com');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            expect(error.technicalMessage, 'Email format is invalid');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.resetPassword(email: anyNamed('email')));
      });

      test(
          'debe retornar ValidationFailure cuando formato es inválido - sin dominio',
          () async {
        // Act
        final result = await useCase(email: 'test@');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            expect(error.technicalMessage, 'Email format is invalid');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.resetPassword(email: anyNamed('email')));
      });

      test(
          'debe retornar ValidationFailure cuando formato es inválido - sin extensión',
          () async {
        // Act
        final result = await useCase(email: 'test@example');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            expect(error.technicalMessage, 'Email format is invalid');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.resetPassword(email: anyNamed('email')));
      });

      test(
          'debe retornar ValidationFailure cuando formato es inválido - sin usuario',
          () async {
        // Act
        final result = await useCase(email: '@example.com');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            expect(error.technicalMessage, 'Email format is invalid');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.resetPassword(email: anyNamed('email')));
      });

      test(
          'debe retornar ValidationFailure cuando formato es inválido - espacios',
          () async {
        // Act
        final result = await useCase(email: 'test @example.com');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            expect(error.technicalMessage, 'Email format is invalid');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.resetPassword(email: anyNamed('email')));
      });

      test('debe retornar ValidationFailure cuando email es muy largo (>254)',
          () async {
        // Arrange - Email de 255 caracteres
        final tooLongEmail = '${'a' * 243}@example.com'; // 243 + 12 = 255

        // Act
        final result = await useCase(email: tooLongEmail);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            expect(error.technicalMessage,
                'Email is too long (max 254 characters)');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.resetPassword(email: anyNamed('email')));
      });

      test(
          'debe retornar ValidationFailure cuando formato es inválido - múltiples @',
          () async {
        // Act
        final result = await useCase(email: 'test@@example.com');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.resetPassword(email: anyNamed('email')));
      });

      test(
          'debe retornar ValidationFailure cuando formato es inválido - caracteres especiales no permitidos',
          () async {
        // Act
        final result = await useCase(email: 'test#user@example.com');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.resetPassword(email: anyNamed('email')));
      });
    });

    group('success cases', () {
      test('debe retornar success cuando email es válido y operación exitosa',
          () async {
        // Arrange
        when(mockRepository.resetPassword(email: tValidEmail))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(email: tValidEmail);

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (_) {
            // Success - void return
          },
        );
        verify(mockRepository.resetPassword(email: tValidEmail)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe aceptar email válido con números', () async {
        // Arrange
        const email = 'user123@example.com';
        when(mockRepository.resetPassword(email: email))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(email: email);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.resetPassword(email: email)).called(1);
      });

      test('debe aceptar email válido con puntos', () async {
        // Arrange
        const email = 'user.name@example.com';
        when(mockRepository.resetPassword(email: email))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(email: email);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.resetPassword(email: email)).called(1);
      });

      test('debe aceptar email válido con guiones', () async {
        // Arrange
        const email = 'user-name@example.com';
        when(mockRepository.resetPassword(email: email))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(email: email);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.resetPassword(email: email)).called(1);
      });

      test('debe aceptar email válido con guión bajo', () async {
        // Arrange
        const email = 'user_name@example.com';
        when(mockRepository.resetPassword(email: email))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(email: email);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.resetPassword(email: email)).called(1);
      });

      test('debe aceptar email válido con plus', () async {
        // Arrange
        const email = 'user+tag@example.com';
        when(mockRepository.resetPassword(email: email))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(email: email);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.resetPassword(email: email)).called(1);
      });

      test('debe aceptar email válido con subdominio', () async {
        // Arrange
        const email = 'user@mail.example.com';
        when(mockRepository.resetPassword(email: email))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(email: email);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.resetPassword(email: email)).called(1);
      });

      test('debe aceptar email con longitud máxima válida (254)', () async {
        // Arrange - Email de exactamente 254 caracteres
        final email = '${'a' * 241}@example.com'; // 241 + 12 = 253

        when(mockRepository.resetPassword(email: email))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(email: email);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.resetPassword(email: email)).called(1);
      });

      test('debe aceptar email con dominio corto (.co)', () async {
        // Arrange
        const email = 'user@example.co';
        when(mockRepository.resetPassword(email: email))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(email: email);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.resetPassword(email: email)).called(1);
      });

      test('debe aceptar email con dominio largo (.museum)', () async {
        // Arrange
        const email = 'user@example.museum';
        when(mockRepository.resetPassword(email: email))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result = await useCase(email: email);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.resetPassword(email: email)).called(1);
      });
    });

    group('repository failures', () {
      test('debe propagar AuthFailure (user not found) del repository',
          () async {
        // Arrange
        final failure = AuthFailure(
          code: ErrorCode.userNotFound,
          technicalMessage: 'User not found',
        );
        when(mockRepository.resetPassword(email: tValidEmail))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(email: tValidEmail);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<AuthFailure>());
            expect(error.code, ErrorCode.userNotFound);
            expect(error.technicalMessage, 'User not found');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.resetPassword(email: tValidEmail)).called(1);
      });

      test('debe propagar NetworkFailure del repository', () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        when(mockRepository.resetPassword(email: tValidEmail))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(email: tValidEmail);

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
        verify(mockRepository.resetPassword(email: tValidEmail)).called(1);
      });

      test('debe propagar ServerFailure del repository', () async {
        // Arrange
        final failure = ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: 'Server error',
        );
        when(mockRepository.resetPassword(email: tValidEmail))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(email: tValidEmail);

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
        verify(mockRepository.resetPassword(email: tValidEmail)).called(1);
      });

      test('debe propagar AuthFailure del repository', () async {
        // Arrange
        final failure = AuthFailure(
          code: ErrorCode.unauthorized,
          technicalMessage: 'Auth error',
        );
        when(mockRepository.resetPassword(email: tValidEmail))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(email: tValidEmail);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<AuthFailure>());
            expect(error.code, ErrorCode.unauthorized);
            expect(error.technicalMessage, 'Auth error');
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.resetPassword(email: tValidEmail)).called(1);
      });

      test('debe propagar DataFailure del repository', () async {
        // Arrange
        final failure = DataFailure(
          code: ErrorCode.notFound,
          technicalMessage: 'Data error',
        );
        when(mockRepository.resetPassword(email: tValidEmail))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(email: tValidEmail);

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
        verify(mockRepository.resetPassword(email: tValidEmail)).called(1);
      });
    });

    group('edge cases', () {
      test('no debe llamar al repository si validación falla', () async {
        // Act - Múltiples llamadas con validaciones fallidas
        await useCase(email: '');
        await useCase(email: 'invalid');
        await useCase(email: '@example.com');
        await useCase(email: 'test@');

        // Assert
        verifyNever(mockRepository.resetPassword(email: anyNamed('email')));
      });

      test('debe llamar al repository solo con emails válidos', () async {
        // Arrange
        when(mockRepository.resetPassword(email: anyNamed('email')))
            .thenAnswer((_) async => Result.success(null));

        // Act - Inválidos (no llaman)
        await useCase(email: '');
        await useCase(email: 'invalid');

        // Act - Válido (llama)
        await useCase(email: tValidEmail);

        // Assert
        verify(mockRepository.resetPassword(email: tValidEmail)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe manejar múltiples solicitudes consecutivas', () async {
        // Arrange
        const email1 = 'user1@example.com';
        const email2 = 'user2@example.com';
        const email3 = 'user3@example.com';

        when(mockRepository.resetPassword(email: anyNamed('email')))
            .thenAnswer((_) async => Result.success(null));

        // Act
        await useCase(email: email1);
        await useCase(email: email2);
        await useCase(email: email3);

        // Assert
        verify(mockRepository.resetPassword(email: email1)).called(1);
        verify(mockRepository.resetPassword(email: email2)).called(1);
        verify(mockRepository.resetPassword(email: email3)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe validar email en cada llamada independientemente', () async {
        // Arrange
        when(mockRepository.resetPassword(email: anyNamed('email')))
            .thenAnswer((_) async => Result.success(null));

        // Act
        final result1 = await useCase(email: 'invalid'); // Falla validación
        final result2 = await useCase(email: tValidEmail); // Pasa validación

        // Assert
        expect(result1.isFailure, isTrue);
        expect(result2.isSuccess, isTrue);
        verify(mockRepository.resetPassword(email: tValidEmail)).called(1);
        verifyNever(mockRepository.resetPassword(email: 'invalid'));
      });

      test('debe retornar failure diferente para cada tipo de error de validación',
          () async {
        // Act
        final emptyResult = await useCase(email: '');
        final invalidFormatResult = await useCase(email: 'invalid');
        final tooLongResult =
            await useCase(email: '${'a' * 250}@example.com');

        // Assert
        emptyResult.when(
          onFailure: (error) {
            expect(error.code, ErrorCode.missingRequiredField);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );

        invalidFormatResult.when(
          onFailure: (error) {
            expect(error.code, ErrorCode.invalidInput);
            expect(error.technicalMessage, contains('format'));
          },
          onSuccess: (_) => fail('Should not succeed'),
        );

        tooLongResult.when(
          onFailure: (error) {
            expect(error.code, ErrorCode.invalidInput);
            expect(error.technicalMessage, contains('too long'));
          },
          onSuccess: (_) => fail('Should not succeed'),
        );

        verifyNever(mockRepository.resetPassword(email: anyNamed('email')));
      });
    });
  });
}
