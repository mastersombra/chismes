import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:chismes/features/auth/data/models/user_model.dart';
import 'package:chismes/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'auth_repository_impl_test.mocks.dart';

@GenerateMocks([SupabaseAuthDataSource, AppLogger])
void main() {
  late AuthRepositoryImpl repository;
  late MockSupabaseAuthDataSource mockDataSource;
  late MockAppLogger mockLogger;

  // Provide dummy value for UserModel
  provideDummy<UserModel>(
    UserModel(
      id: 'dummy-id',
      email: 'dummy@test.com',
      emailVerified: true,
      profileCompleted: false,
      createdAt: DateTime(2024, 1, 1),
    ),
  );

  setUp(() {
    mockDataSource = MockSupabaseAuthDataSource();
    mockLogger = MockAppLogger();
    repository = AuthRepositoryImpl(mockDataSource, mockLogger);
  });

  group('AuthRepositoryImpl', () {
    const tEmail = 'test@example.com';
    const tPassword = 'Test123!@';
    final tUserModel = UserModel(
      id: '123',
      email: tEmail,
      emailVerified: true,
      profileCompleted: false,
      createdAt: DateTime(2024, 1, 1),
    );

    group('currentUser getter', () {
      test('debe retornar User cuando hay usuario actual', () {
        // Arrange
        when(mockDataSource.currentUser).thenReturn(tUserModel);

        // Act
        final user = repository.currentUser;

        // Assert
        expect(user, isA<User>());
        expect(user!.email, tEmail);
        verify(mockDataSource.currentUser).called(1);
      });

      test('debe retornar null cuando no hay usuario actual', () {
        // Arrange
        when(mockDataSource.currentUser).thenReturn(null);

        // Act
        final user = repository.currentUser;

        // Assert
        expect(user, isNull);
        verify(mockDataSource.currentUser).called(1);
      });
    });

    group('authStateChanges stream', () {
      test('debe emitir User cuando hay cambio de estado', () async {
        // Arrange
        final stream = Stream<UserModel?>.fromIterable([tUserModel]);
        when(mockDataSource.authStateChanges).thenAnswer((_) => stream);

        // Act
        final result = await repository.authStateChanges.first;

        // Assert
        expect(result, isA<User>());
        expect(result!.email, tEmail);
      });

      test('debe emitir null cuando usuario se desloguea', () async {
        // Arrange
        final stream = Stream<UserModel?>.fromIterable([null]);
        when(mockDataSource.authStateChanges).thenAnswer((_) => stream);

        // Act
        final result = await repository.authStateChanges.first;

        // Assert
        expect(result, isNull);
      });
    });

    group('signInWithEmail', () {
      test('debe retornar usuario cuando sign in es exitoso', () async {
        // Arrange
        when(mockDataSource.checkEmailExistsAndConfirmed(tEmail))
            .thenAnswer((_) async => true);
        when(mockDataSource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => tUserModel);

        // Act
        final result = await repository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user, isA<User>());
            expect(user.email, tEmail);
          },
        );
        verify(mockDataSource.checkEmailExistsAndConfirmed(tEmail)).called(1);
        verify(mockDataSource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
      });

      test('debe retornar AuthFailure cuando credenciales son incorrectas',
          () async {
        // Arrange
        when(mockDataSource.checkEmailExistsAndConfirmed(tEmail))
            .thenAnswer((_) async => true);
        when(mockDataSource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenThrow(
          supabase.AuthException('Invalid login credentials', statusCode: '400'),
        );

        // Act
        final result = await repository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.code, ErrorCode.invalidCredentials);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe manejar excepción genérica', () async {
        // Arrange
        when(mockDataSource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenThrow(Exception('Generic error'));

        // Act
        final result = await repository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(result.isFailure, isTrue);
        verify(mockLogger.e(
          any,
          error: anyNamed('error'),
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context'),
        )).called(1);
      });

      test('debe logear warning cuando hay AuthException', () async {
        // Arrange
        when(mockDataSource.checkEmailExistsAndConfirmed(tEmail))
            .thenAnswer((_) async => true);
        final exception = supabase.AuthException('Invalid login credentials');
        when(mockDataSource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenThrow(exception);

        // Act
        await repository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        verify(mockLogger.w(
          any,
          error: anyNamed('error'),
          context: anyNamed('context'),
        )).called(1);
      });
    });

    group('signUpWithEmail', () {
      test('debe completarse exitosamente cuando sign up funciona', () async {
        // Arrange
        when(mockDataSource.signUpWithEmailOTP(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockDataSource.signUpWithEmailOTP(
          email: tEmail,
          password: tPassword,
        )).called(1);
      });

      test('debe retornar AuthFailure cuando email ya existe', () async {
        // Arrange
        when(mockDataSource.signUpWithEmailOTP(
          email: tEmail,
          password: tPassword,
        )).thenThrow(
          supabase.AuthException('User already registered', statusCode: '400'),
        );

        // Act
        final result = await repository.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.code, ErrorCode.emailAlreadyInUse);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe manejar excepción genérica', () async {
        // Arrange
        when(mockDataSource.signUpWithEmailOTP(
          email: tEmail,
          password: tPassword,
        )).thenThrow(Exception('Generic error'));

        // Act
        final result = await repository.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        expect(result.isFailure, isTrue);
        verify(mockLogger.e(
          any,
          error: anyNamed('error'),
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context'),
        )).called(1);
      });
    });

    group('signInWithGoogle', () {
      test('debe retornar usuario cuando sign in es exitoso', () async {
        // Arrange
        when(mockDataSource.signInWithGoogle())
            .thenAnswer((_) async => tUserModel);

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user, isA<User>());
            expect(user.email, tEmail);
          },
        );
      });

      test('debe retornar AuthFailure cuando OAuth es cancelado', () async {
        // Arrange
        when(mockDataSource.signInWithGoogle()).thenThrow(
          supabase.AuthException('OAuth cancelled'),
        );

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.code, ErrorCode.oauthCancelled);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe manejar excepción genérica', () async {
        // Arrange
        when(mockDataSource.signInWithGoogle())
            .thenThrow(Exception('Generic error'));

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isFailure, isTrue);
      });
    });

    group('signInWithApple', () {
      test('debe retornar usuario cuando sign in es exitoso', () async {
        // Arrange
        when(mockDataSource.signInWithApple())
            .thenAnswer((_) async => tUserModel);

        // Act
        final result = await repository.signInWithApple();

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user, isA<User>());
            expect(user.email, tEmail);
          },
        );
      });

      test('debe retornar AuthFailure cuando OAuth es cancelado', () async {
        // Arrange
        when(mockDataSource.signInWithApple()).thenThrow(
          supabase.AuthException('OAuth canceled'),
        );

        // Act
        final result = await repository.signInWithApple();

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.code, ErrorCode.oauthCancelled);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe manejar excepción genérica', () async {
        // Arrange
        when(mockDataSource.signInWithApple())
            .thenThrow(Exception('Generic error'));

        // Act
        final result = await repository.signInWithApple();

        // Assert
        expect(result.isFailure, isTrue);
      });
    });

    group('signOut', () {
      test('debe retornar success cuando sign out es exitoso', () async {
        // Arrange
        when(mockDataSource.signOut()).thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockDataSource.signOut()).called(1);
      });

      test('debe manejar AuthException', () async {
        // Arrange
        when(mockDataSource.signOut())
            .thenThrow(supabase.AuthException('Session expired'));

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isFailure, isTrue);
      });

      test('debe manejar excepción genérica', () async {
        // Arrange
        when(mockDataSource.signOut()).thenThrow(Exception('Generic error'));

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isFailure, isTrue);
      });
    });

    group('getCurrentUser', () {
      test('debe retornar usuario cuando hay sesión activa', () async {
        // Arrange
        when(mockDataSource.getCurrentUser())
            .thenAnswer((_) async => tUserModel);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user, isA<User>());
            expect(user!.email, tEmail);
          },
        );
      });

      test('debe retornar null cuando no hay sesión activa', () async {
        // Arrange
        when(mockDataSource.getCurrentUser()).thenAnswer((_) async => null);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user, isNull);
          },
        );
      });

      test('debe manejar excepción', () async {
        // Arrange
        when(mockDataSource.getCurrentUser())
            .thenThrow(Exception('Generic error'));

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isFailure, isTrue);
      });
    });

    group('updateProfile', () {
      const tUsername = 'juanperez';
      const tDisplayName = 'Juan Pérez';
      final tUpdatedUserModel = UserModel(
        id: '123',
        email: tEmail,
        emailVerified: true,
        username: tUsername,
        displayName: tDisplayName,
        profileCompleted: true,
        createdAt: DateTime(2024, 1, 1),
      );

      test('debe retornar usuario actualizado cuando update es exitoso',
          () async {
        // Arrange
        when(mockDataSource.updateProfile(
          username: tUsername,
          displayName: tDisplayName,
        )).thenAnswer((_) async => tUpdatedUserModel);

        // Act
        final result = await repository.updateProfile(
          username: tUsername,
          displayName: tDisplayName,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user.username, tUsername);
            expect(user.displayName, tDisplayName);
            expect(user.profileCompleted, isTrue);
          },
        );
      });

      test('debe retornar DataFailure cuando username existe', () async {
        // Arrange
        when(mockDataSource.updateProfile(username: tUsername)).thenThrow(
          supabase.PostgrestException(
            message:
                'duplicate key value violates unique constraint "profiles_username_key"',
            code: '23505',
          ),
        );

        // Act
        final result = await repository.updateProfile(username: tUsername);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<DataFailure>());
            expect(failure.code, ErrorCode.usernameAlreadyTaken);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe manejar otras PostgrestException', () async {
        // Arrange
        when(mockDataSource.updateProfile(username: tUsername)).thenThrow(
          supabase.PostgrestException(
            message: 'Other database error',
            code: '23502',
          ),
        );

        // Act
        final result = await repository.updateProfile(username: tUsername);

        // Assert
        expect(result.isFailure, isTrue);
      });

      test('debe manejar excepción genérica', () async {
        // Arrange
        when(mockDataSource.updateProfile(username: tUsername))
            .thenThrow(Exception('Generic error'));

        // Act
        final result = await repository.updateProfile(username: tUsername);

        // Assert
        expect(result.isFailure, isTrue);
      });
    });

    group('isUsernameAvailable', () {
      const tUsername = 'juanperez';

      test('debe retornar true cuando username está disponible', () async {
        // Arrange
        when(mockDataSource.isUsernameAvailable(tUsername))
            .thenAnswer((_) async => true);

        // Act
        final result = await repository.isUsernameAvailable(tUsername);

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (available) {
            expect(available, isTrue);
          },
        );
      });

      test('debe retornar false cuando username ya está en uso', () async {
        // Arrange
        when(mockDataSource.isUsernameAvailable(tUsername))
            .thenAnswer((_) async => false);

        // Act
        final result = await repository.isUsernameAvailable(tUsername);

        // Assert
        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (available) {
            expect(available, isFalse);
          },
        );
      });

      test('debe manejar excepción', () async {
        // Arrange
        when(mockDataSource.isUsernameAvailable(tUsername))
            .thenThrow(Exception('Generic error'));

        // Act
        final result = await repository.isUsernameAvailable(tUsername);

        // Assert
        expect(result.isFailure, isTrue);
      });
    });

    group('resetPassword', () {
      test('debe retornar success cuando email es enviado', () async {
        // Arrange
        when(mockDataSource.resetPassword(email: tEmail))
            .thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.resetPassword(email: tEmail);

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('debe manejar AuthException', () async {
        // Arrange
        when(mockDataSource.resetPassword(email: tEmail))
            .thenThrow(supabase.AuthException('User not found'));

        // Act
        final result = await repository.resetPassword(email: tEmail);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.code, ErrorCode.userNotFound);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe manejar excepción genérica', () async {
        // Arrange
        when(mockDataSource.resetPassword(email: tEmail))
            .thenThrow(Exception('Generic error'));

        // Act
        final result = await repository.resetPassword(email: tEmail);

        // Assert
        expect(result.isFailure, isTrue);
      });
    });

    group('updatePassword', () {
      const tNewPassword = 'NewSecure123!@';

      test('debe retornar success cuando contraseña es actualizada', () async {
        // Arrange
        when(mockDataSource.updatePassword(newPassword: tNewPassword))
            .thenAnswer((_) async => Future.value());

        // Act
        final result =
            await repository.updatePassword(newPassword: tNewPassword);

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('debe retornar AuthFailure cuando contraseña es débil', () async {
        // Arrange
        when(mockDataSource.updatePassword(newPassword: tNewPassword)).thenThrow(
          supabase.AuthException('Password is too weak'),
        );

        // Act
        final result =
            await repository.updatePassword(newPassword: tNewPassword);

        // Assert
        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<AuthFailure>());
            expect(failure.code, ErrorCode.weakPassword);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe manejar excepción genérica', () async {
        // Arrange
        when(mockDataSource.updatePassword(newPassword: tNewPassword))
            .thenThrow(Exception('Generic error'));

        // Act
        final result =
            await repository.updatePassword(newPassword: tNewPassword);

        // Assert
        expect(result.isFailure, isTrue);
      });
    });

    group('_handleAuthException', () {
      test('debe retornar invalidCredentials para "invalid credentials"',
          () async {
        // Arrange
        when(mockDataSource.checkEmailExistsAndConfirmed(tEmail))
            .thenAnswer((_) async => true);
        when(mockDataSource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenThrow(
          supabase.AuthException('Invalid credentials'),
        );

        // Act
        final result = await repository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        result.when(
          onFailure: (failure) {
            expect(failure.code, ErrorCode.invalidCredentials);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar emailAlreadyInUse para "already registered"',
          () async {
        // Arrange
        when(mockDataSource.signUpWithEmailOTP(
          email: tEmail,
          password: tPassword,
        )).thenThrow(
          supabase.AuthException('Already registered'),
        );

        // Act
        final result = await repository.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        result.when(
          onFailure: (failure) {
            expect(failure.code, ErrorCode.emailAlreadyInUse);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar weakPassword para "password too short"', () async {
        // Arrange
        when(mockDataSource.updatePassword(newPassword: 'weak'))
            .thenThrow(supabase.AuthException('Password is too short'));

        // Act
        final result = await repository.updatePassword(newPassword: 'weak');

        // Assert
        result.when(
          onFailure: (failure) {
            expect(failure.code, ErrorCode.weakPassword);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar sessionExpired para "session expired"', () async {
        // Arrange
        when(mockDataSource.signOut())
            .thenThrow(supabase.AuthException('Session expired'));

        // Act
        final result = await repository.signOut();

        // Assert
        result.when(
          onFailure: (failure) {
            expect(failure.code, ErrorCode.sessionExpired);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar tooManyRequests para statusCode 429', () async {
        // Arrange
        when(mockDataSource.checkEmailExistsAndConfirmed(tEmail))
            .thenAnswer((_) async => true);
        when(mockDataSource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenThrow(
          supabase.AuthException('Rate limit', statusCode: '429'),
        );

        // Act
        final result = await repository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        result.when(
          onFailure: (failure) {
            expect(failure.code, ErrorCode.tooManyRequests);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar tooManyRequests para "too many requests"', () async {
        // Arrange
        when(mockDataSource.checkEmailExistsAndConfirmed(tEmail))
            .thenAnswer((_) async => true);
        when(mockDataSource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenThrow(
          supabase.AuthException('Too many requests'),
        );

        // Act
        final result = await repository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        result.when(
          onFailure: (failure) {
            expect(failure.code, ErrorCode.tooManyRequests);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar emailNotVerified para "email not verified"',
          () async {
        // Arrange
        when(mockDataSource.checkEmailExistsAndConfirmed(tEmail))
            .thenAnswer((_) async => true);
        when(mockDataSource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenThrow(
          supabase.AuthException('Email not verified'),
        );

        // Act
        final result = await repository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        result.when(
          onFailure: (failure) {
            expect(failure.code, ErrorCode.emailNotVerified);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar unknownError para mensajes desconocidos', () async {
        // Arrange
        when(mockDataSource.checkEmailExistsAndConfirmed(tEmail))
            .thenAnswer((_) async => true);
        when(mockDataSource.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenThrow(
          supabase.AuthException('Unknown error message'),
        );

        // Act
        final result = await repository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        // Assert
        result.when(
          onFailure: (failure) {
            expect(failure.code, ErrorCode.unknownError);
            expect(failure.technicalMessage, contains('Unknown error message'));
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });
    });
  });
}
