import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/moderation/data/datasources/account_status_remote_data_source.dart';
import 'package:chismes/features/moderation/data/models/moderation_appeal_model.dart';
import 'package:chismes/features/moderation/data/repositories/account_status_repository_impl.dart';
import 'package:chismes/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:chismes/features/moderation/domain/entities/account_status.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_appeal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../sanctions_json_fixtures.dart';
import 'moderation_repository_impl_test.mocks.dart';

/// Datasource falso escrito a mano (sin build_runner)
class FakeAccountStatusRemote implements AccountStatusRemoteDataSource {
  Object? error;
  AccountStatus? status;
  AccountAppeal? appeal;

  @override
  Future<AccountStatus> getStatus() async {
    if (error != null) throw error!;
    return status!;
  }

  @override
  Future<AccountAppeal> submitAppeal({required String queueId, required String message}) async {
    if (error != null) throw error!;
    return appeal!;
  }
}

void main() {
  group('AccountStatusRepositoryImpl', () {
    late FakeAccountStatusRemote remote;
    late MockAppLogger logger;
    late AccountStatusRepositoryImpl repository;

    setUp(() {
      remote = FakeAccountStatusRemote();
      logger = MockAppLogger();
      repository = AccountStatusRepositoryImpl(remote, logger);
    });

    final status = AccountStatus(
      state: AccountState.ok,
      activePoints: 0,
      strikeCount: 0,
      expiryDays: 90,
      appealWindowDays: 14,
      thresholds: const SanctionThresholds(restrictionShort: 3, restrictionLong: 6, suspension: 10),
      rejections: const [],
    );
    final appeal = AccountAppeal(
      id: 'ap-1',
      status: AppealStatus.pending,
      message: 'mensaje largo',
      createdAt: DateTime.utc(2026, 11, 20),
    );

    test('getStatus éxito', () async {
      remote.status = status;

      expect(await repository.getStatus(), Result<Failure, AccountStatus>.success(status));
    });

    test('getStatus error → Result.failure y log de error', () async {
      const failure = ServerFailure(code: ErrorCode.serverError);
      remote.error = failure;

      final result = await repository.getStatus();

      expect(result, Result<Failure, AccountStatus>.failure(failure));
      verify(logger.e(any, error: anyNamed('error'), stackTrace: anyNamed('stackTrace'))).called(1);
    });

    test('submitAppeal éxito', () async {
      remote.appeal = appeal;

      expect(
        await repository.submitAppeal(queueId: 'q-1', message: 'mensaje largo'),
        Result<Failure, AccountAppeal>.success(appeal),
      );
    });

    test('submitAppeal conflict → warning, no error', () async {
      remote.error = const DataFailure(code: ErrorCode.conflict);

      final result = await repository.submitAppeal(queueId: 'q-1', message: 'mensaje largo');

      expect(result.isSuccess, isFalse);
      verify(logger.w(any, context: anyNamed('context'))).called(1);
      verifyNever(logger.e(any,
          error: anyNamed('error'), stackTrace: anyNamed('stackTrace'), context: anyNamed('context')));
    });

    test('submitAppeal otro error → log de error', () async {
      remote.error = const ServerFailure(code: ErrorCode.serverError);

      await repository.submitAppeal(queueId: 'q-1', message: 'mensaje largo');

      verify(logger.e(any,
              error: anyNamed('error'), stackTrace: anyNamed('stackTrace'), context: anyNamed('context')))
          .called(1);
    });
  });

  group('ModerationRepositoryImpl apelaciones', () {
    late MockModerationRemoteDataSource remote;
    late MockAppLogger logger;
    late ModerationRepositoryImpl repository;

    setUp(() {
      remote = MockModerationRemoteDataSource();
      logger = MockAppLogger();
      repository = ModerationRepositoryImpl(remote, logger);
    });

    test('getAppeals convierte modelos y pasa el status como valor', () async {
      when(remote.getAppeals(status: anyNamed('status'), limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenAnswer((_) async => [ModerationAppealModel.fromJson(moderationAppealJson())]);

      final result = await repository.getAppeals(status: AppealStatus.rejected, limit: 20, offset: 40);

      result.when(
        onSuccess: (items) => expect(items.single.id, 'ap-1'),
        onFailure: (f) => fail('no debería fallar: $f'),
      );
      verify(remote.getAppeals(status: 'rejected', limit: 20, offset: 40)).called(1);
    });

    test('getAppeals error → Result.failure', () async {
      const failure = PermissionFailure(code: ErrorCode.forbidden);
      when(remote.getAppeals(status: anyNamed('status'), limit: anyNamed('limit'), offset: anyNamed('offset')))
          .thenThrow(failure);

      expect(
        await repository.getAppeals(status: AppealStatus.pending, limit: 20),
        Result<Failure, List<ModerationAppeal>>.failure(failure),
      );
    });

    test('decideAppeal éxito', () async {
      const decision = AppealDecision(appealId: 'ap-1', accept: true);
      when(remote.decideAppeal(any)).thenAnswer((_) async {});

      final result = await repository.decideAppeal(decision);

      expect(result.isSuccess, isTrue);
      verify(remote.decideAppeal(decision)).called(1);
    });

    for (final code in [ErrorCode.conflict, ErrorCode.insufficientPermissions]) {
      test('decideAppeal ${code.name} → warning, no error', () async {
        when(remote.decideAppeal(any)).thenThrow(PermissionFailure(code: code));

        final result = await repository.decideAppeal(const AppealDecision(appealId: 'ap-1', accept: true));

        result.when(onSuccess: (_) => fail('debería fallar'), onFailure: (f) => expect(f.code, code));
        verify(logger.w(any, context: anyNamed('context'))).called(1);
      });
    }

    test('decideAppeal otro error → log de error', () async {
      when(remote.decideAppeal(any)).thenThrow(const ServerFailure(code: ErrorCode.serverError));

      await repository.decideAppeal(const AppealDecision(appealId: 'ap-1', accept: false));

      verify(logger.e(any,
              error: anyNamed('error'), stackTrace: anyNamed('stackTrace'), context: anyNamed('context')))
          .called(1);
    });
  });
}
