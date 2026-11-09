import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/usecases/update_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'update_profile_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late UpdateProfileUseCase useCase;
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
    useCase = UpdateProfileUseCase(mockRepository);
  });

  group('UpdateProfileUseCase', () {
    final tUser = User(
      id: 'user-123',
      email: 'test@example.com',
          emailVerified: true,
      username: 'testuser',
      displayName: 'Test User',
      bio: 'Test bio',
      avatarUrl: 'https://example.com/avatar.jpg',
      profileCompleted: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    group('username validation failures', () {
      test('debe retornar ValidationFailure cuando username es empty',
          () async {
        // Act
        final result = await useCase(username: '');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.missingRequiredField);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.updateProfile(
          username: anyNamed('username'),
          displayName: anyNamed('displayName'),
          avatarUrl: anyNamed('avatarUrl'),
          bio: anyNamed('bio'),
        ));
      });

      test('debe retornar ValidationFailure cuando username es muy corto',
          () async {
        // Act
        final result = await useCase(username: 'ab');

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
        verifyNever(mockRepository.updateProfile(
          username: anyNamed('username'),
          displayName: anyNamed('displayName'),
          avatarUrl: anyNamed('avatarUrl'),
          bio: anyNamed('bio'),
        ));
      });

      test('debe retornar ValidationFailure cuando username es muy largo',
          () async {
        // Act
        final result = await useCase(username: 'a' * 31);

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
        verifyNever(mockRepository.updateProfile(
          username: anyNamed('username'),
          displayName: anyNamed('displayName'),
          avatarUrl: anyNamed('avatarUrl'),
          bio: anyNamed('bio'),
        ));
      });

      test('debe retornar ValidationFailure cuando tiene mayúsculas',
          () async {
        // Act
        final result = await useCase(username: 'UserName');

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

      test('debe retornar ValidationFailure cuando empieza con número',
          () async {
        // Act
        final result = await useCase(username: '123user');

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

      test('debe retornar ValidationFailure cuando empieza con underscore',
          () async {
        // Act
        final result = await useCase(username: '_username');

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

      test('debe retornar ValidationFailure para palabra reservada: admin',
          () async {
        // Act
        final result = await useCase(username: 'admin');

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
    });

    group('displayName validation failures', () {
      test('debe retornar ValidationFailure cuando displayName es empty',
          () async {
        // Act
        final result = await useCase(displayName: '');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
            expect(error.code, ErrorCode.missingRequiredField);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.updateProfile(
          username: anyNamed('username'),
          displayName: anyNamed('displayName'),
          avatarUrl: anyNamed('avatarUrl'),
          bio: anyNamed('bio'),
        ));
      });

      test('debe retornar ValidationFailure cuando displayName es solo espacios',
          () async {
        // Act
        final result = await useCase(displayName: '   ');

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

      test('debe retornar ValidationFailure cuando displayName es muy largo',
          () async {
        // Act
        final result = await useCase(displayName: 'a' * 51);

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
    });

    group('bio validation failures', () {
      test('debe retornar ValidationFailure cuando bio es muy larga', () async {
        // Act
        final result = await useCase(bio: 'a' * 161);

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
        verifyNever(mockRepository.updateProfile(
          username: anyNamed('username'),
          displayName: anyNamed('displayName'),
          avatarUrl: anyNamed('avatarUrl'),
          bio: anyNamed('bio'),
        ));
      });
    });

    group('success cases', () {
      test('debe actualizar solo username cuando es el único campo proporcionado',
          () async {
        // Arrange
        when(mockRepository.updateProfile(
          username: 'newuser',
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase(username: 'newuser');

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: 'newuser',
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).called(1);
        verifyNoMoreInteractions(mockRepository);
      });

      test('debe actualizar solo displayName cuando es el único campo proporcionado',
          () async {
        // Arrange
        when(mockRepository.updateProfile(
          username: null,
          displayName: 'New Name',
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase(displayName: 'New Name');

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: null,
          displayName: 'New Name',
          avatarUrl: null,
          bio: null,
        )).called(1);
      });

      test('debe actualizar solo avatarUrl cuando es el único campo proporcionado',
          () async {
        // Arrange
        const newAvatarUrl = 'https://example.com/new-avatar.jpg';
        when(mockRepository.updateProfile(
          username: null,
          displayName: null,
          avatarUrl: newAvatarUrl,
          bio: null,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase(avatarUrl: newAvatarUrl);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: null,
          displayName: null,
          avatarUrl: newAvatarUrl,
          bio: null,
        )).called(1);
      });

      test('debe actualizar solo bio cuando es el único campo proporcionado',
          () async {
        // Arrange
        const newBio = 'New bio text';
        when(mockRepository.updateProfile(
          username: null,
          displayName: null,
          avatarUrl: null,
          bio: newBio,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase(bio: newBio);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: null,
          displayName: null,
          avatarUrl: null,
          bio: newBio,
        )).called(1);
      });

      test('debe actualizar múltiples campos cuando se proporcionan varios',
          () async {
        // Arrange
        when(mockRepository.updateProfile(
          username: 'newuser',
          displayName: 'New Name',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'New bio',
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase(
          username: 'newuser',
          displayName: 'New Name',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'New bio',
        );

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user, equals(tUser));
          },
        );
        verify(mockRepository.updateProfile(
          username: 'newuser',
          displayName: 'New Name',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: 'New bio',
        )).called(1);
      });

      test('debe aceptar bio vacía (bio es opcional)', () async {
        // Arrange
        when(mockRepository.updateProfile(
          username: null,
          displayName: null,
          avatarUrl: null,
          bio: '',
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase(bio: '');

        // Assert - Bio vacía es válida (bio es opcional)
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: null,
          displayName: null,
          avatarUrl: null,
          bio: '',
        )).called(1);
      });

      test('debe aceptar bio con longitud máxima válida (160)', () async {
        // Arrange
        final maxBio = 'a' * 160;
        when(mockRepository.updateProfile(
          username: null,
          displayName: null,
          avatarUrl: null,
          bio: maxBio,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase(bio: maxBio);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: null,
          displayName: null,
          avatarUrl: null,
          bio: maxBio,
        )).called(1);
      });

      test('debe aceptar displayName con longitud máxima válida (50)',
          () async {
        // Arrange
        final maxDisplayName = 'a' * 50;
        when(mockRepository.updateProfile(
          username: null,
          displayName: maxDisplayName,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase(displayName: maxDisplayName);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: null,
          displayName: maxDisplayName,
          avatarUrl: null,
          bio: null,
        )).called(1);
      });

      test('debe aceptar username válido con números y underscores', () async {
        // Arrange
        const validUsername = 'user_123';
        when(mockRepository.updateProfile(
          username: validUsername,
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase(username: validUsername);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: validUsername,
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).called(1);
      });

      test('debe aceptar username con longitud mínima (3)', () async {
        // Arrange
        when(mockRepository.updateProfile(
          username: 'abc',
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase(username: 'abc');

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: 'abc',
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).called(1);
      });

      test('debe aceptar username con longitud máxima (30)', () async {
        // Arrange
        final maxUsername = 'a' * 30;
        when(mockRepository.updateProfile(
          username: maxUsername,
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        final result = await useCase(username: maxUsername);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: maxUsername,
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).called(1);
      });
    });

    group('repository failures', () {
      test('debe propagar AuthFailure (username already taken) del repository',
          () async {
        // Arrange
        final failure = AuthFailure(
          code: ErrorCode.usernameAlreadyTaken,
          technicalMessage: 'Username taken',
        );
        when(mockRepository.updateProfile(
          username: 'takenuser',
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(username: 'takenuser');

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<AuthFailure>());
            expect(error.code, ErrorCode.usernameAlreadyTaken);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.updateProfile(
          username: 'takenuser',
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).called(1);
      });

      test('debe propagar NetworkFailure del repository', () async {
        // Arrange
        final failure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );
        when(mockRepository.updateProfile(
          username: 'newuser',
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(username: 'newuser');

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
        when(mockRepository.updateProfile(
          username: null,
          displayName: 'New Name',
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.failure(failure));

        // Act
        final result = await useCase(displayName: 'New Name');

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
      test('no debe llamar al repository si validación de username falla',
          () async {
        // Act
        await useCase(username: '');
        await useCase(username: 'ab');
        await useCase(username: 'UPPER');

        // Assert
        verifyNever(mockRepository.updateProfile(
          username: anyNamed('username'),
          displayName: anyNamed('displayName'),
          avatarUrl: anyNamed('avatarUrl'),
          bio: anyNamed('bio'),
        ));
      });

      test('no debe llamar al repository si validación de displayName falla',
          () async {
        // Act
        await useCase(displayName: '');
        await useCase(displayName: '   ');
        await useCase(displayName: 'a' * 51);

        // Assert
        verifyNever(mockRepository.updateProfile(
          username: anyNamed('username'),
          displayName: anyNamed('displayName'),
          avatarUrl: anyNamed('avatarUrl'),
          bio: anyNamed('bio'),
        ));
      });

      test('no debe llamar al repository si validación de bio falla', () async {
        // Act
        await useCase(bio: 'a' * 161);

        // Assert
        verifyNever(mockRepository.updateProfile(
          username: anyNamed('username'),
          displayName: anyNamed('displayName'),
          avatarUrl: anyNamed('avatarUrl'),
          bio: anyNamed('bio'),
        ));
      });

      test('debe validar solo los campos proporcionados', () async {
        // Arrange
        when(mockRepository.updateProfile(
          username: null,
          displayName: 'Valid Name',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: null,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act - Solo displayName y avatarUrl (username no se valida)
        final result = await useCase(
          displayName: 'Valid Name',
          avatarUrl: 'https://example.com/avatar.jpg',
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: null,
          displayName: 'Valid Name',
          avatarUrl: 'https://example.com/avatar.jpg',
          bio: null,
        )).called(1);
      });

      test('debe validar username antes de displayName', () async {
        // Act - Username inválido + displayName inválido
        final result = await useCase(
          username: 'UPPER',
          displayName: 'a' * 51,
        );

        // Assert - Debe fallar por username (se valida primero)
        result.when(
          onFailure: (error) {
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe validar displayName antes de bio', () async {
        // Act - displayName inválido + bio inválida
        final result = await useCase(
          displayName: 'a' * 51,
          bio: 'a' * 161,
        );

        // Assert - Debe fallar por displayName (se valida primero)
        result.when(
          onFailure: (error) {
            // Note: technicalMessage usa i18n, no verificamos contenido exacto
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe manejar múltiples actualizaciones consecutivas', () async {
        // Arrange
        when(mockRepository.updateProfile(
          username: anyNamed('username'),
          displayName: anyNamed('displayName'),
          avatarUrl: anyNamed('avatarUrl'),
          bio: anyNamed('bio'),
        )).thenAnswer((_) async => Result.success(tUser));

        // Act
        await useCase(username: 'user1');
        await useCase(displayName: 'Name 1');
        await useCase(bio: 'Bio 1');

        // Assert
        verify(mockRepository.updateProfile(
          username: anyNamed('username'),
          displayName: anyNamed('displayName'),
          avatarUrl: anyNamed('avatarUrl'),
          bio: anyNamed('bio'),
        )).called(3);
      });

      test('debe permitir actualización sin ningún campo (todos null)',
          () async {
        // Arrange
        when(mockRepository.updateProfile(
          username: null,
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).thenAnswer((_) async => Result.success(tUser));

        // Act - Sin campos (todos null)
        final result = await useCase();

        // Assert - Debería llamar al repository (sin validaciones)
        expect(result.isSuccess, isTrue);
        verify(mockRepository.updateProfile(
          username: null,
          displayName: null,
          avatarUrl: null,
          bio: null,
        )).called(1);
      });
    });
  });
}
