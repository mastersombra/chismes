import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/moderation/data/datasources/moderation_remote_data_source.dart';
import 'package:chismes/features/moderation/data/models/moderation_item_model.dart';
import 'package:chismes/features/moderation/data/repositories/moderation_repository_impl.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:chismes/features/moderation/domain/entities/review_decision.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../moderation_fixtures.dart';
import 'moderation_repository_impl_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ModerationRemoteDataSource>(),
  MockSpec<AppLogger>(),
])
void main() {
  late MockModerationRemoteDataSource remote;
  late MockAppLogger logger;
  late ModerationRepositoryImpl repository;

  setUp(() {
    remote = MockModerationRemoteDataSource();
    logger = MockAppLogger();
    repository = ModerationRepositoryImpl(remote, logger);
  });

  group('getQueue', () {
    test('éxito: convierte los modelos en entidades', () async {
      when(remote.getQueue(
        status: anyNamed('status'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => [ModerationItemModel.fromJson(queueItemJson())]);

      final result = await repository.getQueue(
        status: ModerationQueueStatus.rejected,
        limit: 20,
        offset: 20,
      );

      result.when(
        onSuccess: (items) => expect(items.single.id, 'q-1'),
        onFailure: (f) => fail('no debería fallar: $f'),
      );
      verify(remote.getQueue(status: 'rejected', limit: 20, offset: 20)).called(1);
    });

    test('Failure del datasource → Result.failure con el mismo Failure', () async {
      const failure = PermissionFailure(code: ErrorCode.forbidden);
      when(remote.getQueue(
        status: anyNamed('status'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenThrow(failure);

      final result = await repository.getQueue(status: ModerationQueueStatus.pending, limit: 20);

      result.when(
        onSuccess: (_) => fail('debería fallar'),
        onFailure: (f) => expect(f, failure),
      );
      verify(logger.e(any, error: anyNamed('error'), stackTrace: anyNamed('stackTrace'), context: anyNamed('context')))
          .called(1);
    });
  });

  group('decide', () {
    const decision = ReviewDecision.approve(queueId: 'q-1');

    test('éxito', () async {
      when(remote.decide(any)).thenAnswer((_) => Future.value());

      final result = await repository.decide(decision);

      expect(result.isSuccess, isTrue);
      verify(remote.decide(decision)).called(1);
    });

    test('ya decidido (conflict): failure con warning, no error', () async {
      when(remote.decide(any)).thenThrow(const DataFailure(code: ErrorCode.conflict));

      final result = await repository.decide(decision);

      expect(result.isFailure, isTrue);
      verify(logger.w(any, context: anyNamed('context'))).called(1);
      verifyNever(logger.e(any, error: anyNamed('error'), stackTrace: anyNamed('stackTrace'), context: anyNamed('context')));
    });

    test('error inesperado: failure con log de error', () async {
      when(remote.decide(any)).thenThrow(Exception('boom'));

      final result = await repository.decide(decision);

      expect(result.isFailure, isTrue);
      verify(logger.e(any, error: anyNamed('error'), stackTrace: anyNamed('stackTrace'), context: anyNamed('context')))
          .called(1);
    });
  });
}
