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
        expect(errorState.failure, tFailure);
      });
    });

    group('signInWithGoogle', () {
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
    });

    group('signInWithApple', () {
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
    });
  });
}
