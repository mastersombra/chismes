import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/usecases/sign_in_with_email.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sign_in_with_email_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignInWithEmailUseCase useCase;
  late MockAuthRepository mockRepository;

  provideDummy<Result<Failure, User>>(
    Result.failure(const ValidationFailure(code: ErrorCode.invalidInput)),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithEmailUseCase(mockRepository);
  });

  group('SignInWithEmailUseCase', () {
    const tEmail = 'test@example.com';
    const tPassword = 'Test123!@';
    final tUser = User(
      id: '123',
      email: tEmail,
      emailVerified: true,
      profileCompleted: false,
      createdAt: DateTime(2024, 1, 1),
    );

    group('validaciones', () {
      test('debe validar email antes de llamar repository', () async {
        const invalidEmail = 'invalid-email';

        final result = await useCase(
          email: invalidEmail,
          password: tPassword,
        );

        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<ValidationFailure>());
            expect(failure.code, ErrorCode.invalidInput);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.signInWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });

      test('debe validar password antes de llamar repository', () async {
        const invalidPassword = 'short';

        final result = await useCase(
          email: tEmail,
          password: invalidPassword,
        );

        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<ValidationFailure>());
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verifyNever(mockRepository.signInWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });

      test('debe validar email vacío', () async {
        final result = await useCase(
          email: '',
          password: tPassword,
        );

        expect(result.isFailure, isTrue);
        verifyNever(mockRepository.signInWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });

      test('debe validar password vacío', () async {
        final result = await useCase(
          email: tEmail,
          password: '',
        );

        expect(result.isFailure, isTrue);
        verifyNever(mockRepository.signInWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });
    });

    group('login exitoso', () {
      test('debe retornar User cuando credenciales son válidas', () async {
        when(mockRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.success(tUser));

        final result = await useCase(
          email: tEmail,
          password: tPassword,
        );

        expect(result.isSuccess, isTrue);
        result.when(
          onFailure: (_) => fail('Should not fail'),
          onSuccess: (user) {
            expect(user, tUser);
            expect(user.email, tEmail);
            expect(user.emailVerified, true);
          },
        );
        verify(mockRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
      });
    });

    group('login fallido', () {
      test('debe retornar AuthFailure cuando credenciales son inválidas', () async {
        const tFailure = AuthFailure(
          code: ErrorCode.invalidCredentials,
          technicalMessage: 'Invalid credentials',
        );

        when(mockRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(tFailure));

        final result = await useCase(
          email: tEmail,
          password: tPassword,
        );

        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, tFailure);
            expect(failure.code, ErrorCode.invalidCredentials);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar NetworkFailure cuando hay error de red', () async {
        const tFailure = NetworkFailure(
          code: ErrorCode.networkError,
          technicalMessage: 'Network error',
        );

        when(mockRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.failure(tFailure));

        final result = await useCase(
          email: tEmail,
          password: tPassword,
        );

        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (failure) {
            expect(failure, isA<NetworkFailure>());
            expect(failure.code, ErrorCode.networkError);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });
    });
  });
}
