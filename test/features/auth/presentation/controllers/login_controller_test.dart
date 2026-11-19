import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/auth/domain/usecases/reset_password.dart';
import 'package:chismes/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:chismes/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:chismes/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:chismes/features/auth/presentation/controllers/login_controller.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'login_controller_test.mocks.dart';

@GenerateMocks([
  SignInWithEmailUseCase,
  SignInWithGoogleUseCase,
  SignInWithAppleUseCase,
  ResetPasswordUseCase,
  AppLogger,
])
void main() {
  late LoginController controller;
  late MockSignInWithEmailUseCase mockSignInWithEmail;
  late MockSignInWithGoogleUseCase mockSignInWithGoogle;
  late MockSignInWithAppleUseCase mockSignInWithApple;
  late MockResetPasswordUseCase mockResetPassword;
  late MockAppLogger mockLogger;

  provideDummy<Result<Failure, User>>(
    Result.failure(const AuthFailure(code: ErrorCode.unauthorized)),
  );

  provideDummy<Result<Failure, void>>(
    Result.failure(const AuthFailure(code: ErrorCode.unauthorized)),
  );

  setUp(() {
    mockSignInWithEmail = MockSignInWithEmailUseCase();
    mockSignInWithGoogle = MockSignInWithGoogleUseCase();
    mockSignInWithApple = MockSignInWithAppleUseCase();
    mockResetPassword = MockResetPasswordUseCase();
    mockLogger = MockAppLogger();

    controller = LoginController(
      mockSignInWithEmail,
      mockSignInWithGoogle,
      mockSignInWithApple,
      mockResetPassword,
      mockLogger,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('LoginController', () {
    const tEmail = 'test@example.com';
    const tPassword = 'Test123!@';
    final tUser = User(
      id: '123',
      email: tEmail,
      emailVerified: true,
      profileCompleted: false,
      createdAt: DateTime(2024, 1, 1),
    );

    test('debe inicializar con estado AuthInitial', () {
      expect(controller.state, isA<AuthInitial>());
    });

    test('debe notificar listeners cuando estado cambia', () async {
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount++;
      });

      when(mockSignInWithEmail(
        email: tEmail,
        password: tPassword,
      )).thenAnswer((_) async => Result.success(tUser));

      await controller.signInWithEmail(
        email: tEmail,
        password: tPassword,
      );

      expect(notificationCount, greaterThanOrEqualTo(2));
    });

    group('signInWithEmail', () {
      test('debe cambiar estado a loading al iniciar login', () async {
        when(mockSignInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.success(tUser));

        final future = controller.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        expect(controller.state, isA<AuthLoading>());
        await future;
      });

      test('debe cambiar estado a authenticated cuando login es exitoso', () async {
        when(mockSignInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.success(tUser));

        await controller.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        expect(controller.state, isA<AuthSuccess>());
        final authState = controller.state as AuthSuccess;
        expect(authState.user, tUser);
      });

      test('debe cambiar estado a error cuando login falla', () async {
        const tFailure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Invalid credentials',
        );

        when(mockSignInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(tFailure));

        await controller.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.errorCode, tFailure.code);
      });

      test('debe logear intento y éxito de login', () async {
        when(mockSignInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.success(tUser));

        await controller.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        verify(mockLogger.i(
          'Login attempt with email',
          context: {'email': tEmail},
        )).called(1);
        verify(mockLogger.i(
          'Login successful',
          context: {'userId': tUser.id, 'email': tUser.email},
        )).called(1);
      });

      test('debe logear error cuando login falla', () async {
        const tFailure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Invalid credentials',
        );
        when(mockSignInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(tFailure));

        await controller.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        verify(mockLogger.w(
          'Login failed',
          error: tFailure,
          context: {'email': tEmail, 'code': ErrorCode.invalidCredentials},
        )).called(1);
      });

      test('debe manejar errores de red', () async {
        const tFailure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'No internet connection',
        );
        when(mockSignInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(tFailure));

        await controller.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.errorCode, ErrorCode.networkError);
      });

      test('debe manejar errores de validación', () async {
        const tFailure = ValidationFailure(
          code: ErrorCode.invalidInput,
          technicalMessage: 'Invalid email format',
        );
        when(mockSignInWithEmail(
          email: 'invalid-email',
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(tFailure));

        await controller.signInWithEmail(
          email: 'invalid-email',
          password: tPassword,
        );

        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.errorCode, ErrorCode.invalidInput);
      });
    });

    group('signInWithGoogle', () {
      test('debe cambiar estado a loading al iniciar', () async {
        when(mockSignInWithGoogle()).thenAnswer((_) async => Result.success(tUser));

        final future = controller.signInWithGoogle();

        expect(controller.state, isA<AuthLoading>());
        await future;
      });

      test('debe cambiar estado a authenticated cuando login es exitoso', () async {
        when(mockSignInWithGoogle()).thenAnswer((_) async => Result.success(tUser));

        await controller.signInWithGoogle();

        expect(controller.state, isA<AuthSuccess>());
      });

      test('debe cambiar estado a error cuando login falla', () async {
        const tFailure = AuthFailure(
          code: ErrorCode.unauthorized,
          technicalMessage: 'Google sign in failed',
        );

        when(mockSignInWithGoogle()).thenAnswer((_) async => Result.failure(tFailure));

        await controller.signInWithGoogle();

        expect(controller.state, isA<AuthError>());
      });

      test('debe volver a estado initial cuando usuario cancela OAuth', () async {
        const tFailure = AuthFailure(
          code: ErrorCode.oauthCancelled,
          technicalMessage: 'User cancelled',
        );

        when(mockSignInWithGoogle()).thenAnswer((_) async => Result.failure(tFailure));

        await controller.signInWithGoogle();

        expect(controller.state, isA<AuthInitial>());
      });

      test('debe logear intento y éxito de Google login', () async {
        when(mockSignInWithGoogle()).thenAnswer((_) async => Result.success(tUser));

        await controller.signInWithGoogle();

        verify(mockLogger.i('Google login attempt')).called(1);
        verify(mockLogger.i(
          'Google login successful',
          context: {'userId': tUser.id, 'email': tUser.email},
        )).called(1);
      });

      test('debe logear cuando usuario cancela Google login', () async {
        const tFailure = AuthFailure(
          code: ErrorCode.oauthCancelled,
          technicalMessage: 'User cancelled',
        );
        when(mockSignInWithGoogle()).thenAnswer((_) async => Result.failure(tFailure));

        await controller.signInWithGoogle();

        verify(mockLogger.i('Google login cancelled by user')).called(1);
      });

      test('debe logear error cuando Google login falla', () async {
        const tFailure = AuthFailure(
          code: ErrorCode.unauthorized,
          technicalMessage: 'Google sign in failed',
        );
        when(mockSignInWithGoogle()).thenAnswer((_) async => Result.failure(tFailure));

        await controller.signInWithGoogle();

        verify(mockLogger.w(
          'Google login failed',
          error: tFailure,
          context: {'code': ErrorCode.unauthorized},
        )).called(1);
      });
    });

    group('signInWithApple', () {
      test('debe cambiar estado a loading al iniciar', () async {
        when(mockSignInWithApple()).thenAnswer((_) async => Result.success(tUser));

        final future = controller.signInWithApple();

        expect(controller.state, isA<AuthLoading>());
        await future;
      });

      test('debe cambiar estado a authenticated cuando login es exitoso', () async {
        when(mockSignInWithApple()).thenAnswer((_) async => Result.success(tUser));

        await controller.signInWithApple();

        expect(controller.state, isA<AuthSuccess>());
      });

      test('debe cambiar estado a error cuando login falla', () async {
        const tFailure = AuthFailure(
          code: ErrorCode.unauthorized,
          technicalMessage: 'Apple sign in failed',
        );

        when(mockSignInWithApple()).thenAnswer((_) async => Result.failure(tFailure));

        await controller.signInWithApple();

        expect(controller.state, isA<AuthError>());
      });

      test('debe logear intento y éxito de Apple login', () async {
        when(mockSignInWithApple()).thenAnswer((_) async => Result.success(tUser));

        await controller.signInWithApple();

        verify(mockLogger.i('Apple login attempt')).called(1);
        verify(mockLogger.i(
          'Apple login successful',
          context: {'userId': tUser.id, 'email': tUser.email},
        )).called(1);
      });

      test('debe logear error cuando Apple login falla', () async {
        const tFailure = AuthFailure(
          code: ErrorCode.unauthorized,
          technicalMessage: 'Apple sign in failed',
        );
        when(mockSignInWithApple()).thenAnswer((_) async => Result.failure(tFailure));

        await controller.signInWithApple();

        verify(mockLogger.w(
          'Apple login failed',
          error: tFailure,
          context: {'code': ErrorCode.unauthorized},
        )).called(1);
      });
    });

    group('resetPassword', () {
      test('debe cambiar estado a loading al iniciar', () async {
        when(mockResetPassword(email: tEmail))
            .thenAnswer((_) async => Result.success(null));

        final future = controller.resetPassword(email: tEmail);

        expect(controller.state, isA<AuthLoading>());
        await future;
      });

      test('debe cambiar estado a AuthOtpSent cuando es exitoso', () async {
        when(mockResetPassword(email: tEmail))
            .thenAnswer((_) async => Result.success(null));

        await controller.resetPassword(email: tEmail);

        expect(controller.state, isA<AuthOtpSent>());
        final otpState = controller.state as AuthOtpSent;
        expect(otpState.email, tEmail);
      });

      test('debe cambiar estado a error cuando falla', () async {
        const tFailure = AuthFailure(
          code: ErrorCode.userNotFound,
          technicalMessage: 'User not found',
        );
        when(mockResetPassword(email: tEmail))
            .thenAnswer((_) async => Result.failure(tFailure));

        await controller.resetPassword(email: tEmail);

        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.errorCode, ErrorCode.userNotFound);
      });

      test('debe logear intento y éxito de reset password', () async {
        when(mockResetPassword(email: tEmail))
            .thenAnswer((_) async => Result.success(null));

        await controller.resetPassword(email: tEmail);

        verify(mockLogger.i(
          'Reset password request',
          context: {'email': tEmail},
        )).called(1);
        verify(mockLogger.i(
          'Reset password OTP sent',
          context: {'email': tEmail},
        )).called(1);
      });

      test('debe logear error cuando reset password falla', () async {
        const tFailure = AuthFailure(
          code: ErrorCode.userNotFound,
          technicalMessage: 'User not found',
        );
        when(mockResetPassword(email: tEmail))
            .thenAnswer((_) async => Result.failure(tFailure));

        await controller.resetPassword(email: tEmail);

        verify(mockLogger.w(
          'Reset password failed',
          error: tFailure,
          context: {'email': tEmail, 'code': ErrorCode.userNotFound},
        )).called(1);
      });

      test('debe manejar errores de red', () async {
        const tFailure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'No internet connection',
        );
        when(mockResetPassword(email: tEmail))
            .thenAnswer((_) async => Result.failure(tFailure));

        await controller.resetPassword(email: tEmail);

        expect(controller.state, isA<AuthError>());
        final errorState = controller.state as AuthError;
        expect(errorState.errorCode, ErrorCode.networkError);
      });

      test('debe llamar al usecase con email correcto', () async {
        when(mockResetPassword(email: tEmail))
            .thenAnswer((_) async => Result.success(null));

        await controller.resetPassword(email: tEmail);

        verify(mockResetPassword(email: tEmail)).called(1);
      });
    });

    group('resetState', () {
      test('debe cambiar estado a initial', () async {
        when(mockSignInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(
          const AuthFailure(
            code: ErrorCode.invalidCredentials,
            technicalMessage: 'Invalid credentials',
          ),
        ));

        await controller.signInWithEmail(
          email: tEmail,
          password: tPassword,
        );

        controller.resetState();

        expect(controller.state, isA<AuthInitial>());
      });

      test('debe notificar listeners al resetear', () {
        var notificationCount = 0;
        controller.addListener(() {
          notificationCount++;
        });

        controller.resetState();

        expect(notificationCount, 1);
      });
    });
  });
}
