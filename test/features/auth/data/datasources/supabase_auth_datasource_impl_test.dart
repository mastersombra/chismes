import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/auth/data/datasources/supabase_auth_datasource_impl.dart';

import 'supabase_auth_datasource_impl_test.mocks.dart';

@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  User,
  Session,
  AppLogger,
])
void main() {
  late SupabaseAuthDataSourceImpl dataSource;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockAppLogger mockLogger;
  late MockUser mockUser;
  late MockSession mockSession;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockLogger = MockAppLogger();
    mockUser = MockUser();
    mockSession = MockSession();

    // Configurar auth mock básico
    when(mockSupabase.auth).thenReturn(mockAuth);

    dataSource = SupabaseAuthDataSourceImpl(mockSupabase, mockLogger);
  });

  group('SupabaseAuthDataSourceImpl', () {
    // NOTA: Los tests de getCurrentUser, isUsernameAvailable, updateProfile, etc. son omitidos
    // debido a la complejidad de mockear la cadena de builders de Postgrest
    // (SupabaseQueryBuilder -> PostgrestFilterBuilder -> PostgrestTransformBuilder).
    // Estos están cubiertos por integration tests o tests end-to-end.

    group('currentUser getter', () {
      test('debe retornar UserModel cuando hay usuario autenticado', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockUser.email).thenReturn('test@example.com');
        when(mockUser.emailConfirmedAt).thenReturn(DateTime(2024, 1, 1).toIso8601String());
        when(mockUser.createdAt).thenReturn(DateTime(2024, 1, 1).toIso8601String());

        // Act
        final result = dataSource.currentUser;

        // Assert
        expect(result, isNotNull);
        expect(result!.id, 'user-123');
        expect(result.email, 'test@example.com');
      });

      test('debe retornar null cuando no hay usuario autenticado', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = dataSource.currentUser;

        // Assert
        expect(result, isNull);
      });
    });

    group('signOut', () {
      test('debe completarse exitosamente cuando sign out funciona', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockAuth.signOut()).thenAnswer((_) async => {});

        // Act
        await dataSource.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
        verify(mockLogger.i('Signing out', context: {'userId': 'user-123'})).called(1);
        verify(mockLogger.i('Sign out successful', context: {'userId': 'user-123'})).called(1);
      });

      test('debe lanzar AuthException cuando sign out falla', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockAuth.signOut()).thenThrow(const AuthException('Sign out failed'));

        // Act & Assert
        expect(
          () => dataSource.signOut(),
          throwsA(isA<AuthException>()),
        );
      });

      test('debe logear cuando sign out es exitoso con usuario null', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);
        when(mockAuth.signOut()).thenAnswer((_) async => {});

        // Act
        await dataSource.signOut();

        // Assert
        verify(mockLogger.i('Signing out', context: {'userId': null})).called(1);
      });
    });

    group('resetPassword', () {
      const tEmail = 'test@example.com';

      test('debe completarse exitosamente cuando email es enviado', () async {
        // Arrange
        when(mockAuth.signInWithOtp(
          email: tEmail,
          shouldCreateUser: false,
        )).thenAnswer((_) async => AuthResponse(user: null, session: null));

        // Act
        await dataSource.resetPassword(email: tEmail);

        // Assert
        verify(mockAuth.signInWithOtp(
          email: tEmail,
          shouldCreateUser: false,
        )).called(1);
        verify(mockLogger.i('Sending password reset OTP', context: {'email': tEmail})).called(1);
        verify(mockLogger.i('Password reset OTP sent', context: {'email': tEmail})).called(1);
      });

      test('debe lanzar AuthException cuando email no existe', () async {
        // Arrange
        when(mockAuth.signInWithOtp(
          email: anyNamed('email'),
          shouldCreateUser: anyNamed('shouldCreateUser'),
        )).thenThrow(const AuthException('User not found'));

        // Act & Assert
        expect(
          () => dataSource.resetPassword(email: tEmail),
          throwsA(isA<AuthException>()),
        );
      });

      test('debe logear warning cuando hay AuthException', () async {
        // Arrange
        const exception = AuthException('User not found', statusCode: '404');

        when(mockAuth.signInWithOtp(
          email: anyNamed('email'),
          shouldCreateUser: anyNamed('shouldCreateUser'),
        )).thenThrow(exception);

        // Act & Assert
        try {
          await dataSource.resetPassword(email: tEmail);
        } catch (_) {}

        verify(mockLogger.w(
          'Reset password failed (AuthException)',
          error: exception,
          context: {'code': '404', 'message': 'User not found'},
        )).called(1);
      });
    });

    group('updatePassword', () {
      const tNewPassword = 'NewTest123!@';

      test('debe lanzar AuthException cuando password es débil', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockAuth.updateUser(any)).thenThrow(const AuthException('Password too weak'));

        // Act & Assert
        expect(
          () => dataSource.updatePassword(newPassword: tNewPassword),
          throwsA(isA<AuthException>()),
        );
      });

      test('debe logear intento de actualización', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockAuth.updateUser(any)).thenThrow(const AuthException('Password too weak'));

        // Act & Assert
        try {
          await dataSource.updatePassword(newPassword: tNewPassword);
        } catch (_) {}

        verify(mockLogger.i('Updating password', context: {'userId': 'user-123'})).called(1);
      });
    });

    group('signUpWithEmailOTP', () {
      const tEmail = 'test@example.com';
      const tPassword = 'Test123!@';

      test('debe completarse exitosamente cuando sign up funciona', () async {
        // Arrange
        when(mockAuth.signUp(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => AuthResponse(user: mockUser, session: null));

        // Act
        await dataSource.signUpWithEmailOTP(email: tEmail, password: tPassword);

        // Assert
        verify(mockAuth.signUp(email: tEmail, password: tPassword)).called(1);
        verify(mockLogger.i('Signing up with email OTP', context: {'email': tEmail})).called(1);
        verify(mockLogger.i('Sign up OTP sent', context: {'email': tEmail})).called(1);
      });

      test('debe lanzar AuthException cuando email ya está registrado', () async {
        // Arrange
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(const AuthException('Email already registered'));

        // Act & Assert
        expect(
          () => dataSource.signUpWithEmailOTP(email: tEmail, password: tPassword),
          throwsA(isA<AuthException>()),
        );
      });

      test('debe logear error cuando falla', () async {
        // Arrange
        final exception = Exception('Network error');

        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(exception);

        // Act & Assert
        try {
          await dataSource.signUpWithEmailOTP(email: tEmail, password: tPassword);
        } catch (_) {}

        verify(mockLogger.e(
          'Sign up OTP failed',
          error: exception,
          stackTrace: anyNamed('stackTrace'),
          context: {'email': tEmail},
        )).called(1);
      });
    });

    group('resendOTP', () {
      const tEmail = 'test@example.com';

      test('debe completarse exitosamente cuando OTP es reenviado', () async {
        // Arrange
        when(mockAuth.resend(
          type: OtpType.signup,
          email: tEmail,
        )).thenAnswer((_) async => ResendResponse());

        // Act
        await dataSource.resendOTP(email: tEmail);

        // Assert
        verify(mockAuth.resend(type: OtpType.signup, email: tEmail)).called(1);
        verify(mockLogger.i('Resending OTP', context: {'email': tEmail})).called(1);
        verify(mockLogger.i('OTP resent successfully', context: {'email': tEmail})).called(1);
      });

      test('debe lanzar AuthException cuando hay demasiadas solicitudes', () async {
        // Arrange
        when(mockAuth.resend(
          type: anyNamed('type'),
          email: anyNamed('email'),
        )).thenThrow(const AuthException('Too many requests'));

        // Act & Assert
        expect(
          () => dataSource.resendOTP(email: tEmail),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('resendVerificationEmail', () {
      test('debe completarse exitosamente cuando email es reenviado', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn('test@example.com');
        when(mockAuth.resend(
          type: OtpType.signup,
          email: 'test@example.com',
        )).thenAnswer((_) async => ResendResponse());

        // Act
        await dataSource.resendVerificationEmail();

        // Assert
        verify(mockAuth.resend(type: OtpType.signup, email: 'test@example.com')).called(1);
      });

      test('debe lanzar Exception cuando no hay usuario autenticado', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => dataSource.resendVerificationEmail(),
          throwsA(isA<Exception>()),
        );
      });

      test('debe lanzar Exception cuando usuario no tiene email', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.email).thenReturn(null);

        // Act & Assert
        expect(
          () => dataSource.resendVerificationEmail(),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Logging', () {
      test('debe logear errores genéricos correctamente', () async {
        // Arrange
        final exception = Exception('Generic error');

        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.id).thenReturn('user-123');
        when(mockAuth.signOut()).thenThrow(exception);

        // Act & Assert
        try {
          await dataSource.signOut();
        } catch (_) {}

        verify(mockLogger.e(
          'Sign out failed',
          error: exception,
          stackTrace: anyNamed('stackTrace'),
        )).called(1);
      });

      test('debe logear context cuando hay datos relevantes', () async {
        // Arrange
        when(mockAuth.signInWithOtp(
          email: anyNamed('email'),
          shouldCreateUser: anyNamed('shouldCreateUser'),
        )).thenAnswer((_) async => AuthResponse(user: null, session: null));

        // Act
        await dataSource.resetPassword(email: 'test@example.com');

        // Assert
        verify(mockLogger.i(
          'Sending password reset OTP',
          context: {'email': 'test@example.com'},
        )).called(1);
      });
    });
  });
}
