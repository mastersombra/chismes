import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/profile/domain/repositories/profile_repository.dart';
import 'package:chismes/features/profile/domain/usecases/delete_account.dart';

import 'delete_account_test.mocks.dart';

@GenerateMocks([ProfileRepository])
void main() {
  setUpAll(() {
    provideDummy<Result<Failure, void>>(Result.success(null));
  });

  late DeleteAccount useCase;
  late MockProfileRepository mockRepository;

  setUp(() {
    mockRepository = MockProfileRepository();
    useCase = DeleteAccount(mockRepository);
  });

  test('delega en el repositorio y retorna success', () async {
    when(mockRepository.deleteAccount()).thenAnswer((_) async => Result.success(null));

    final result = await useCase();

    expect(result.isSuccess, isTrue);
    verify(mockRepository.deleteAccount()).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('propaga el failure del repositorio', () async {
    when(mockRepository.deleteAccount()).thenAnswer(
      (_) async => Result.failure(const ServerFailure(code: ErrorCode.serverError)),
    );

    final result = await useCase();

    expect(result.isFailure, isTrue);
  });
}
