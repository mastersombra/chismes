import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/usecases/sign_up_with_email.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'sign_up_with_email_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late SignUpWithEmailUseCase useCase;
  late MockAuthRepository mockRepository;

  provideDummy<Result<Failure, void>>(Result.success(null));
  provideDummy<Result<Failure, bool>>(Result.success(false));

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignUpWithEmailUseCase(mockRepository);
  });

  group('SignUpWithEmailUseCase', () {
    const tEmail = 'test@example.com';
    const tPassword = 'SecurePass123!';

    group('validaciones', () {
      test('debe retornar ValidationFailure cuando email es empty', () async {
        final result = await useCase(email: '', password: tPassword);

        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure cuando password es empty', () async {
        final result = await useCase(email: tEmail, password: '');

        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure cuando email es inválido', () async {
        final result = await useCase(email: 'invalid-email', password: tPassword);

        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });

      test('debe retornar ValidationFailure cuando password es muy corto', () async {
        final result = await useCase(email: tEmail, password: 'short');

        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<ValidationFailure>());
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
      });
    });

    group('registro exitoso', () {
      test('debe completarse exitosamente cuando credenciales son válidas', () async {
        when(mockRepository.checkEmailExistsAndConfirmed(tEmail))
            .thenAnswer((_) async => Result.success(false));
        when(mockRepository.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Result.success(null));

        final result = await useCase(email: tEmail, password: tPassword);

        expect(result.isSuccess, isTrue);
        verify(mockRepository.checkEmailExistsAndConfirmed(tEmail)).called(1);
        verify(mockRepository.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
      });
    });

    group('email ya existe', () {
      test('debe retornar AuthFailure cuando email ya existe y está confirmado', () async {
        when(mockRepository.checkEmailExistsAndConfirmed(tEmail))
            .thenAnswer((_) async => Result.success(true));

        final result = await useCase(email: tEmail, password: tPassword);

        expect(result.isFailure, isTrue);
        result.when(
          onFailure: (error) {
            expect(error, isA<AuthFailure>());
            expect(error.code, ErrorCode.emailAlreadyInUse);
          },
          onSuccess: (_) => fail('Should not succeed'),
        );
        verify(mockRepository.checkEmailExistsAndConfirmed(tEmail)).called(1);
        verifyNever(mockRepository.signUpWithEmail(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ));
      });
    });
  });
}
