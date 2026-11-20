import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:chismes/features/moderation/domain/entities/review_decision.dart';
import 'package:chismes/features/moderation/domain/usecases/decide_review.dart';
import 'package:chismes/features/moderation/domain/usecases/get_moderation_queue.dart';
import 'package:chismes/features/moderation/presentation/controllers/moderation_queue_controller.dart';
import 'package:chismes/features/moderation/presentation/controllers/review_decision_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../moderation_fixtures.dart';
import 'moderation_controllers_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetModerationQueue>(),
  MockSpec<DecideReview>(),
  MockSpec<AppLogger>(),
])
void main() {
  setUpAll(() {
    provideDummy<Result<Failure, List<ModerationItem>>>(Result.success(const []));
    provideDummy<Result<Failure, void>>(Result.success(null));
  });

  List<ModerationItem> page(int count, {int start = 0}) =>
      [for (var i = start; i < start + count; i++) moderationItem(id: 'q-$i')];

  group('ModerationQueueController', () {
    late MockGetModerationQueue getQueue;
    late ModerationQueueController controller;
    const pending = ModerationQueueStatus.pending;

    void answer(Result<Failure, List<ModerationItem>> result, {int? offset}) {
      when(getQueue(status: anyNamed('status'), offset: offset ?? anyNamed('offset')))
          .thenAnswer((_) async => result);
    }

    setUp(() {
      getQueue = MockGetModerationQueue();
      controller = ModerationQueueController(getQueue, MockAppLogger());
    });

    tearDown(() => controller.dispose());

    test('estado inicial: nada cargado', () {
      final tab = controller.tab(pending);
      expect(tab.loaded, isFalse);
      expect(tab.items, isEmpty);
    });

    test('ensureLoaded carga una sola vez', () async {
      answer(Result.success(page(3)));

      await controller.ensureLoaded(pending);
      await controller.ensureLoaded(pending);

      expect(controller.tab(pending).items, hasLength(3));
      expect(controller.tab(pending).loaded, isTrue);
      expect(controller.tab(pending).hasMore, isFalse);
      verify(getQueue(status: pending)).called(1);
    });

    test('página completa → hasMore; loadMore agrega sin duplicados', () async {
      answer(Result.success(page(GetModerationQueue.pageSize)), offset: 0);
      await controller.refresh(pending);
      expect(controller.tab(pending).hasMore, isTrue);

      // La segunda página repite el último ítem (la cola cambió entre páginas)
      answer(
        Result.success(page(5, start: GetModerationQueue.pageSize - 1)),
        offset: GetModerationQueue.pageSize,
      );
      await controller.loadMore(pending);

      final tab = controller.tab(pending);
      expect(tab.items, hasLength(GetModerationQueue.pageSize + 4));
      expect(tab.items.map((i) => i.id).toSet(), hasLength(tab.items.length));
      expect(tab.hasMore, isFalse);
      expect(tab.isLoadingMore, isFalse);
    });

    test('loadMore no hace nada si no hay más páginas', () async {
      answer(Result.success(page(2)));
      await controller.refresh(pending);

      await controller.loadMore(pending);

      verify(getQueue(status: pending, offset: anyNamed('offset'))).called(1);
    });

    test('error al cargar: guarda el código y permite reintentar', () async {
      answer(Result.failure(const PermissionFailure(code: ErrorCode.forbidden)));
      await controller.refresh(pending);

      expect(controller.tab(pending).errorCode, ErrorCode.forbidden);
      expect(controller.tab(pending).loaded, isTrue);
      expect(controller.tab(pending).isLoading, isFalse);

      answer(Result.success(page(1)));
      await controller.refresh(pending);
      expect(controller.tab(pending).errorCode, isNull);
      expect(controller.tab(pending).items, hasLength(1));
    });

    test('error en loadMore conserva la lista y deja de paginar', () async {
      answer(Result.success(page(GetModerationQueue.pageSize)), offset: 0);
      await controller.refresh(pending);
      answer(
        Result.failure(const ServerFailure(code: ErrorCode.serverError)),
        offset: GetModerationQueue.pageSize,
      );

      await controller.loadMore(pending);

      expect(controller.tab(pending).items, hasLength(GetModerationQueue.pageSize));
      expect(controller.tab(pending).hasMore, isFalse);
    });

    test('onItemDecided saca el ítem de pendientes y resetea el historial', () async {
      answer(Result.success(page(3)));
      await controller.refresh(pending);
      await controller.refresh(ModerationQueueStatus.approved);
      var notified = 0;
      controller.addListener(() => notified++);

      controller.onItemDecided('q-1');

      expect(controller.tab(pending).items.map((i) => i.id), ['q-0', 'q-2']);
      expect(controller.tab(ModerationQueueStatus.approved).loaded, isFalse);
      expect(controller.tab(ModerationQueueStatus.rejected).loaded, isFalse);
      expect(notified, 1);
    });

    test('no notifica después de dispose', () async {
      final local = ModerationQueueController(getQueue, MockAppLogger());
      answer(Result.success(page(1)));
      final future = local.refresh(pending);
      local.dispose();
      await expectLater(future, completes);
    });
  });

  group('ReviewDecisionController', () {
    late MockDecideReview decide;
    late ReviewDecisionController controller;

    setUp(() {
      decide = MockDecideReview();
      controller = ReviewDecisionController(decide);
    });

    tearDown(() => controller.dispose());

    test('approve exitoso → done', () async {
      when(decide(any)).thenAnswer((_) async => Result.success(null));

      expect(await controller.approve('q-1'), DecisionOutcome.done);
      expect(controller.isSubmitting, isFalse);
      verify(decide(const ReviewDecision.approve(queueId: 'q-1'))).called(1);
    });

    test('reject envía gravedad, motivo y nota', () async {
      when(decide(any)).thenAnswer((_) async => Result.success(null));

      final outcome = await controller.reject(
        'q-1',
        severity: ModerationSeverity.medium,
        reason: RejectReason.spam,
        note: 'nota',
      );

      expect(outcome, DecisionOutcome.done);
      verify(decide(const ReviewDecision.reject(
        queueId: 'q-1',
        severity: ModerationSeverity.medium,
        reason: RejectReason.spam,
        note: 'nota',
      ))).called(1);
    });

    for (final code in [ErrorCode.conflict, ErrorCode.notFound]) {
      test('$code → alreadyDecided (sin error)', () async {
        when(decide(any)).thenAnswer((_) async => Result.failure(DataFailure(code: code)));

        expect(await controller.approve('q-1'), DecisionOutcome.alreadyDecided);
        expect(controller.errorCode, isNull);
      });
    }

    test('otro error → failed con el código', () async {
      when(decide(any)).thenAnswer(
        (_) async => Result.failure(const ServerFailure(code: ErrorCode.serverError)),
      );

      expect(await controller.approve('q-1'), DecisionOutcome.failed);
      expect(controller.errorCode, ErrorCode.serverError);
      expect(controller.isSubmitting, isFalse);
    });

    test('no envía dos decisiones a la vez', () async {
      when(decide(any)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        return Result.success(null);
      });

      final first = controller.approve('q-1');
      expect(controller.isSubmitting, isTrue);
      expect(await controller.approve('q-1'), DecisionOutcome.failed);
      expect(await first, DecisionOutcome.done);
      verify(decide(any)).called(1);
    });
  });
}
