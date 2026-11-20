import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:chismes/features/moderation/domain/entities/review_decision.dart';
import 'package:chismes/features/moderation/domain/repositories/moderation_repository.dart';
import 'package:chismes/features/moderation/domain/usecases/decide_review.dart';
import 'package:chismes/features/moderation/domain/usecases/get_moderation_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../moderation_fixtures.dart';
import 'moderation_usecases_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ModerationRepository>()])
void main() {
  late MockModerationRepository repository;

  setUp(() {
    repository = MockModerationRepository();
    provideDummy<Result<Failure, List<ModerationItem>>>(Result.success(const []));
    provideDummy<Result<Failure, void>>(Result.success(null));
  });

  group('GetModerationQueue', () {
    test('pide una página del tamaño fijo con el offset dado', () async {
      final items = [moderationItem()];
      when(repository.getQueue(
        status: anyNamed('status'),
        limit: anyNamed('limit'),
        offset: anyNamed('offset'),
      )).thenAnswer((_) async => Result.success(items));

      final result = await GetModerationQueue(repository)(
        status: ModerationQueueStatus.approved,
        offset: 40,
      );

      expect(result, Result<Failure, List<ModerationItem>>.success(items));
      verify(repository.getQueue(
        status: ModerationQueueStatus.approved,
        limit: GetModerationQueue.pageSize,
        offset: 40,
      )).called(1);
    });
  });

  group('DecideReview', () {
    test('decisión válida → repositorio', () async {
      when(repository.decide(any)).thenAnswer((_) async => Result.success(null));
      const decision = ReviewDecision.approve(queueId: 'q-1');

      final result = await DecideReview(repository)(decision);

      expect(result.isSuccess, isTrue);
      verify(repository.decide(decision)).called(1);
    });

    test('decisión inválida → ValidationFailure sin llamar al repositorio', () async {
      final result = await DecideReview(repository)(const ReviewDecision.approve(queueId: ''));

      result.when(
        onSuccess: (_) => fail('debería fallar'),
        onFailure: (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.code, ErrorCode.missingRequiredField);
        },
      );
      verifyNever(repository.decide(any));
    });
  });
}
