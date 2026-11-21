import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/moderation/domain/entities/account_status.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_appeal.dart';
import 'package:chismes/features/moderation/domain/repositories/account_status_repository.dart';
import 'package:chismes/features/moderation/domain/usecases/decide_appeal.dart';
import 'package:chismes/features/moderation/domain/usecases/get_account_status.dart';
import 'package:chismes/features/moderation/domain/usecases/get_appeals.dart';
import 'package:chismes/features/moderation/domain/usecases/submit_appeal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'moderation_usecases_test.mocks.dart';

/// Repositorio falso escrito a mano (sin build_runner)
class FakeAccountStatusRepository implements AccountStatusRepository {
  Result<Failure, AccountStatus>? statusResult;
  Result<Failure, AccountAppeal>? appealResult;
  final List<(String, String)> appealCalls = [];

  @override
  Future<Result<Failure, AccountStatus>> getStatus() async => statusResult!;

  @override
  Future<Result<Failure, AccountAppeal>> submitAppeal({
    required String queueId,
    required String message,
  }) async {
    appealCalls.add((queueId, message));
    return appealResult!;
  }
}

AccountStatus _status() => AccountStatus(
      state: AccountState.ok,
      activePoints: 0,
      strikeCount: 0,
      expiryDays: 90,
      appealWindowDays: 14,
      thresholds: const SanctionThresholds(restrictionShort: 3, restrictionLong: 6, suspension: 10),
      rejections: const [],
    );

final _appeal = AccountAppeal(
  id: 'ap-1',
  status: AppealStatus.pending,
  message: 'No era un insulto',
  createdAt: DateTime.utc(2026, 11, 20),
);

void main() {
  setUpAll(() {
    provideDummy<Result<Failure, List<ModerationAppeal>>>(Result.success(const []));
    provideDummy<Result<Failure, void>>(Result.success(null));
  });

  group('GetAccountStatus', () {
    test('devuelve lo del repositorio', () async {
      final repo = FakeAccountStatusRepository()..statusResult = Result.success(_status());

      final result = await GetAccountStatus(repo)();

      expect(result.isSuccess, isTrue);
    });
  });

  group('SubmitAppeal', () {
    test('válida: recorta el mensaje y llama al repositorio', () async {
      final repo = FakeAccountStatusRepository()..appealResult = Result.success(_appeal);

      final result = await SubmitAppeal(repo)(queueId: 'q-1', message: '  No era un insulto  ');

      expect(result, Result<Failure, AccountAppeal>.success(_appeal));
      expect(repo.appealCalls, [('q-1', 'No era un insulto')]);
    });

    test('inválida: ValidationFailure sin llamar al repositorio', () async {
      final repo = FakeAccountStatusRepository();

      final result = await SubmitAppeal(repo)(queueId: 'q-1', message: 'corto');

      result.when(
        onSuccess: (_) => fail('debería fallar'),
        onFailure: (f) => expect(f, isA<ValidationFailure>()),
      );
      expect(repo.appealCalls, isEmpty);
    });
  });

  group('GetAppeals', () {
    test('pide la página con el tamaño fijo', () async {
      final repo = MockModerationRepository();
      when(repo.getAppeals(status: anyNamed('status'), limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => Result.success(const []));

      await GetAppeals(repo)(status: AppealStatus.accepted, offset: 40);

      verify(repo.getAppeals(status: AppealStatus.accepted, limit: GetAppeals.pageSize, offset: 40)).called(1);
    });
  });

  group('DecideAppeal', () {
    test('válida: delega al repositorio', () async {
      final repo = MockModerationRepository();
      const decision = AppealDecision(appealId: 'ap-1', accept: true, note: 'ok');
      when(repo.decideAppeal(any)).thenAnswer((_) async => Result.success(null));

      final result = await DecideAppeal(repo)(decision);

      expect(result.isSuccess, isTrue);
      verify(repo.decideAppeal(decision)).called(1);
    });

    test('inválida: no llama al repositorio', () async {
      final repo = MockModerationRepository();

      final result = await DecideAppeal(repo)(const AppealDecision(appealId: '', accept: false));

      result.when(
        onSuccess: (_) => fail('debería fallar'),
        onFailure: (f) => expect(f.code, ErrorCode.missingRequiredField),
      );
      verifyNever(repo.decideAppeal(any));
    });
  });
}
