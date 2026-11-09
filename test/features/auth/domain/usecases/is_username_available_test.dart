import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/usecases/is_username_available.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'is_username_available_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late IsUsernameAvailableUseCase useCase;
  late MockAuthRepository mockRepository;

  // Provide dummy values for Mockito
  provideDummy<Result<Failure, bool>>(
    Result.success(true),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = IsUsernameAvailableUseCase(mockRepository);
  });

  group('IsUsernameAvailableUseCase', () {
    const tValidUsername = 'validuser';

    group('validation failures', () {
      test('debe retornar ValidationFailure cuando username es empty',
          () async {
        // Act
        final result = await useCase('');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.missingRequiredField);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.isUsernameAvailable(any));
      });

      test('debe retornar ValidationFailure cuando username es muy corto',
          () async {
        // Act
        final result = await useCase('ab'); // Solo 2 caracteres

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.isUsernameAvailable(any));
      });

      test('debe retornar ValidationFailure cuando username es muy largo',
          () async {
        // Act
        final result = await useCase('a' * 31); // 31 caracteres

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.isUsernameAvailable(any));
      });

      test('debe retornar ValidationFailure cuando contiene mayúsculas',
          () async {
        // Act
        final result = await useCase('UserName');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.isUsernameAvailable(any));
      });

      test('debe retornar ValidationFailure cuando contiene espacios',
          () async {
        // Act
        final result = await useCase('user name');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.isUsernameAvailable(any));
      });

      test('debe retornar ValidationFailure cuando contiene símbolos', () async {
        // Act
        final result = await useCase('user@name');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.isUsernameAvailable(any));
      });

      test('debe retornar ValidationFailure cuando empieza con número',
          () async {
        // Act
        final result = await useCase('123user');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.isUsernameAvailable(any));
      });

      test('debe retornar ValidationFailure cuando empieza con underscore',
          () async {
        // Act
        final result = await useCase('_username');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.isUsernameAvailable(any));
      });

      test('debe retornar ValidationFailure cuando termina con underscore',
          () async {
        // Act
        final result = await useCase('username_');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.isUsernameAvailable(any));
      });

      test('debe retornar ValidationFailure para palabra reservada: admin',
          () async {
        // Act
        final result = await useCase('admin');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.isUsernameAvailable(any));
      });

      test('debe retornar ValidationFailure para palabra reservada: root',
          () async {
        // Act
        final result = await useCase('root');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure para palabra reservada: system',
          () async {
        // Act
        final result = await useCase('system');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure para palabra reservada: chismes',
          () async {
        // Act
        final result = await useCase('chismes');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure para palabra reservada: support',
          () async {
        // Act
        final result = await useCase('support');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure para palabra reservada: help',
          () async {
        // Act
        final result = await useCase('help');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure para palabra reservada: anonymous',
          () async {
        // Act
        final result = await useCase('anonymous');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure para palabra reservada: user',
          () async {
        // Act
        final result = await useCase('user');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure para palabra reservada: guest',
          () async {
        // Act
        final result = await useCase('guest');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.invalidInput);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });
    });

    group('success cases', () {
      test('debe retornar true cuando username está disponible', () async {
        // Arrange
        when(mockRepository.isUsernameAvailable(tValidUsername))
            .thenAnswer((_) async => Result.success(true));

        // Act
        final result = await useCase(tValidUsername);

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (available) {
            expect(available, isTrue);
          },
        );
        verify(mockRepository.isUsernameAvailable(tValidUsername)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe retornar false cuando username ya está en uso', () async {
        // Arrange
        when(mockRepository.isUsernameAvailable(tValidUsername))
            .thenAnswer((_) async => Result.success(false));

        // Act
        final result = await useCase(tValidUsername);

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (available) {
            expect(available, isFalse);
          },
        );
        verify(mockRepository.isUsernameAvailable(tValidUsername)).called(1);
      });

      test('debe aceptar username válido con números', () async {
        // Arrange
        const username = 'user123';
        when(mockRepository.isUsernameAvailable(username))
            .thenAnswer((_) async => Result.success(true));

        // Act
        final result = await useCase(username);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.isUsernameAvailable(username)).called(1);
      });

      test('debe aceptar username válido con underscores en medio', () async {
        // Arrange
        const username = 'user_name';
        when(mockRepository.isUsernameAvailable(username))
            .thenAnswer((_) async => Result.success(true));

        // Act
        final result = await useCase(username);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.isUsernameAvailable(username)).called(1);
      });

      test('debe aceptar username con longitud mínima (3)', () async {
        // Arrange
        const username = 'abc';
        when(mockRepository.isUsernameAvailable(username))
            .thenAnswer((_) async => Result.success(true));

        // Act
        final result = await useCase(username);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.isUsernameAvailable(username)).called(1);
      });

      test('debe aceptar username con longitud máxima (30)', () async {
        // Arrange
        final username = 'a' * 30;
        when(mockRepository.isUsernameAvailable(username))
            .thenAnswer((_) async => Result.success(true));

        // Act
        final result = await useCase(username);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.isUsernameAvailable(username)).called(1);
      });
    });

    group('repository failures', () {
      test('debe propagar NetworkFailure del repository', () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        when(mockRepository.isUsernameAvailable(tValidUsername))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tValidUsername);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<NetworkFailure>());
            expect(error.code, ErrorCode.networkError);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.isUsernameAvailable(tValidUsername)).called(1);
      });

      test('debe propagar ServerFailure del repository', () async {
        // Arrange
        final failure = ServerFailure(
          code: ErrorCode.serverError,
          technicalMessage: 'Server error',
        );
        when(mockRepository.isUsernameAvailable(tValidUsername))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tValidUsername);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ServerFailure>());
            expect(error.code, ErrorCode.serverError);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.isUsernameAvailable(tValidUsername)).called(1);
      });

      test('debe propagar DataFailure del repository', () async {
        // Arrange
        final failure = DataFailure(
          code: ErrorCode.notFound,
          technicalMessage: 'Data error',
        );
        when(mockRepository.isUsernameAvailable(tValidUsername))
            .thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(tValidUsername);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<DataFailure>());
            expect(error.code, ErrorCode.notFound);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.isUsernameAvailable(tValidUsername)).called(1);
      });
    });

    group('edge cases', () {
      test('no debe llamar al repository si validación falla', () async {
        // Act
        await useCase('');
        await useCase('ab');
        await useCase('UPPER');
        await useCase('admin');

        // Assert
        verifyNever(mockRepository.isUsernameAvailable(any));
      });

      test('debe llamar al repository solo con usernames válidos', () async {
        // Arrange
        when(mockRepository.isUsernameAvailable(any))
            .thenAnswer((_) async => Result.success(true));

        // Act - Inválidos (no llaman)
        await useCase('');
        await useCase('ab');

        // Act - Válido (llama)
        await useCase(tValidUsername);

        // Assert
        verify(mockRepository.isUsernameAvailable(tValidUsername)).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe manejar múltiples consultas consecutivas', () async {
        // Arrange
        when(mockRepository.isUsernameAvailable(any))
            .thenAnswer((_) async => Result.success(true));

        // Act
        await useCase('user1');
        await useCase('user2');
        await useCase('user3');

        // Assert
        verify(mockRepository.isUsernameAvailable('user1')).called(1);
        verify(mockRepository.isUsernameAvailable('user2')).called(1);
        verify(mockRepository.isUsernameAvailable('user3')).called(1);
      });
    });
  });
}
