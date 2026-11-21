import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/moderation/domain/entities/account_status.dart';
import 'package:chismes/features/moderation/domain/usecases/decide_appeal.dart';
import 'package:chismes/features/moderation/domain/usecases/get_account_status.dart';
import 'package:chismes/features/moderation/domain/usecases/get_appeals.dart';
import 'package:chismes/features/moderation/domain/usecases/submit_appeal.dart';
import 'package:chismes/features/moderation/presentation/controllers/account_status_controller.dart';
import 'package:chismes/features/moderation/presentation/controllers/appeal_decision_controller.dart';
import 'package:chismes/features/moderation/presentation/controllers/appeals_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_app_logger_helper.dart';
import '../../sanctions_fixtures.dart';

void main() {
  group('AccountStatusController', () {
    late FakeAccountStatusRepository repo;
    late AccountStatusController controller;

    setUp(() {
      repo = FakeAccountStatusRepository();
      controller = AccountStatusController(GetAccountStatus(repo), SubmitAppeal(repo), MockAppLogger());
    });

    test('load: éxito guarda el estado y notifica carga', () async {
      repo.statusResults.add(Result.success(accountStatus(activePoints: 2)));
      final loadingStates = <bool>[];
      controller.addListener(() => loadingStates.add(controller.isLoading));

      await controller.load();

      expect(controller.status?.activePoints, 2);
      expect(controller.errorCode, isNull);
      expect(loadingStates, [true, false]);
    });

    test('load: error guarda el código y conserva el estado anterior', () async {
      repo.statusResults
        ..add(Result.success(accountStatus()))
        ..add(Result.failure(const ServerFailure(code: ErrorCode.serverError)));

      await controller.load();
      await controller.load();

      expect(controller.errorCode, ErrorCode.serverError);
      expect(controller.status, isNotNull);
    });

    test('load: ignora llamadas mientras carga', () async {
      repo.statusResults.add(Result.success(accountStatus()));
      final first = controller.load();
      final second = controller.load();
      await Future.wait([first, second]);
      expect(repo.statusCalls, 1);
    });

    test('submitAppeal done: envía el mensaje recortado y recarga', () async {
      repo.statusResults.add(Result.success(accountStatus()));
      final outcome = await controller.submitAppeal(queueId: 'q-1', message: '  Fue un malentendido  ');

      expect(outcome, AppealOutcome.done);
      expect(repo.appeals.single, ('q-1', 'Fue un malentendido'));
      expect(repo.statusCalls, 1);
      expect(controller.submittingQueueId, isNull);
      expect(controller.appealErrorCode, isNull);
    });

    for (final code in [ErrorCode.conflict, ErrorCode.notFound]) {
      test('submitAppeal $code → notAllowed y recarga', () async {
        repo.statusResults.add(Result.success(accountStatus()));
        repo.appealResult = Result.failure(DataFailure(code: code));

        final outcome = await controller.submitAppeal(queueId: 'q-1', message: 'Fue un malentendido');

        expect(outcome, AppealOutcome.notAllowed);
        expect(repo.statusCalls, 1);
      });
    }

    test('submitAppeal error → failed con código, sin recargar', () async {
      repo.appealResult = Result.failure(const ServerFailure(code: ErrorCode.serverError));

      final outcome = await controller.submitAppeal(queueId: 'q-1', message: 'Fue un malentendido');

      expect(outcome, AppealOutcome.failed);
      expect(controller.appealErrorCode, ErrorCode.serverError);
      expect(repo.statusCalls, 0);
    });

    test('submitAppeal: mensaje corto falla por validación de dominio sin llamar al repo', () async {
      final outcome = await controller.submitAppeal(queueId: 'q-1', message: 'corto');

      expect(outcome, AppealOutcome.failed);
      expect(controller.appealErrorCode, ErrorCode.invalidInput);
      expect(repo.appeals, isEmpty);
    });

    test('submitAppeal: una a la vez', () async {
      repo.statusResults.add(Result.success(accountStatus()));
      final submitting = <String?>[];
      controller.addListener(() => submitting.add(controller.submittingQueueId));

      final first = controller.submitAppeal(queueId: 'q-1', message: 'Fue un malentendido');
      final second = await controller.submitAppeal(queueId: 'q-2', message: 'Fue un malentendido');
      await first;

      expect(second, AppealOutcome.failed);
      expect(repo.appeals.length, 1);
      expect(submitting.first, 'q-1');
    });

    test('dispose: no notifica después', () async {
      repo.statusResults.add(Result.success(accountStatus()));
      final future = controller.load();
      controller.dispose();
      await future;
    });
  });

  group('AppealsController', () {
    late FakeModerationRepository repo;
    late AppealsController controller;

    setUp(() {
      repo = FakeModerationRepository();
      controller = AppealsController(GetAppeals(repo), MockAppLogger());
    });

    test('estado inicial: pendientes sin cargar', () {
      expect(controller.selected, AppealStatus.pending);
      expect(controller.current.loaded, isFalse);
      expect(controller.current.hasMore, isTrue);
    });

    test('select carga la lista una sola vez', () async {
      repo.appealPages[(AppealStatus.pending, 0)] = Result.success([moderationAppeal()]);

      await controller.select(AppealStatus.pending);
      await controller.select(AppealStatus.pending);

      expect(controller.current.items.length, 1);
      expect(controller.current.loaded, isTrue);
      expect(controller.current.hasMore, isFalse);
      expect(repo.appealCalls, [(AppealStatus.pending, 0)]);
    });

    test('select cambia la lista elegida', () async {
      await controller.select(AppealStatus.accepted);
      expect(controller.selected, AppealStatus.accepted);
      expect(controller.list(AppealStatus.accepted).loaded, isTrue);
      expect(controller.list(AppealStatus.pending).loaded, isFalse);
    });

    test('refresh con error guarda el código', () async {
      repo.appealPages[(AppealStatus.pending, 0)] =
          Result.failure(const PermissionFailure(code: ErrorCode.forbidden));

      await controller.refresh(AppealStatus.pending);

      expect(controller.current.errorCode, ErrorCode.forbidden);
      expect(controller.current.loaded, isTrue);
      expect(controller.current.isLoading, isFalse);
    });

    test('refresh ignora mientras carga', () async {
      final a = controller.refresh(AppealStatus.pending);
      final b = controller.refresh(AppealStatus.pending);
      await Future.wait([a, b]);
      expect(repo.appealCalls.length, 1);
    });

    test('loadMore: pagina, sin duplicados y hasMore según tamaño', () async {
      final page = [for (var i = 0; i < GetAppeals.pageSize; i++) moderationAppeal(id: 'a-$i')];
      repo.appealPages[(AppealStatus.pending, 0)] = Result.success(page);
      repo.appealPages[(AppealStatus.pending, GetAppeals.pageSize)] =
          Result.success([moderationAppeal(id: 'a-0'), moderationAppeal(id: 'a-extra')]);

      await controller.select(AppealStatus.pending);
      expect(controller.current.hasMore, isTrue);
      await controller.loadMore(AppealStatus.pending);

      expect(controller.current.items.length, GetAppeals.pageSize + 1);
      expect(controller.current.items.last.id, 'a-extra');
      expect(controller.current.hasMore, isFalse);

      await controller.loadMore(AppealStatus.pending);
      expect(repo.appealCalls.length, 2);
    });

    test('loadMore: no carga si la lista no se cargó', () async {
      await controller.loadMore(AppealStatus.pending);
      expect(repo.appealCalls, isEmpty);
    });

    test('loadMore con error conserva la lista y corta el scroll', () async {
      final page = [for (var i = 0; i < GetAppeals.pageSize; i++) moderationAppeal(id: 'a-$i')];
      repo.appealPages[(AppealStatus.pending, 0)] = Result.success(page);
      repo.appealPages[(AppealStatus.pending, GetAppeals.pageSize)] =
          Result.failure(const ServerFailure(code: ErrorCode.serverError));

      await controller.select(AppealStatus.pending);
      await controller.loadMore(AppealStatus.pending);

      expect(controller.current.items.length, GetAppeals.pageSize);
      expect(controller.current.hasMore, isFalse);
      expect(controller.current.isLoadingMore, isFalse);
    });

    test('onAppealDecided saca la apelación y vacía el historial', () async {
      repo.appealPages[(AppealStatus.pending, 0)] =
          Result.success([moderationAppeal(id: 'a-1'), moderationAppeal(id: 'a-2')]);
      await controller.select(AppealStatus.accepted);
      await controller.select(AppealStatus.pending);

      controller.onAppealDecided('a-1');

      expect(controller.current.items.map((a) => a.id), ['a-2']);
      expect(controller.list(AppealStatus.accepted).loaded, isFalse);
      expect(controller.list(AppealStatus.rejected).loaded, isFalse);
    });

    test('AppealsListState.copyWith conserva y reemplaza campos', () {
      const base = AppealsListState(loaded: true, errorCode: ErrorCode.serverError);
      final copy = base.copyWith(isLoading: true);
      expect(copy.loaded, isTrue);
      expect(copy.errorCode, ErrorCode.serverError);
      expect(copy.copyWith(errorCode: () => null).errorCode, isNull);
    });

    test('dispose: no notifica después', () async {
      final future = controller.refresh(AppealStatus.pending);
      controller.dispose();
      await future;
    });
  });

  group('AppealDecisionController', () {
    late FakeModerationRepository repo;
    late AppealDecisionController controller;

    setUp(() {
      repo = FakeModerationRepository();
      controller = AppealDecisionController(DecideAppeal(repo));
    });

    test('done: envía decisión y nota', () async {
      final outcome = await controller.decide('ap-1', accept: true, note: 'ok');

      expect(outcome, AppealDecisionOutcome.done);
      expect(repo.appealDecisions.single.accept, isTrue);
      expect(repo.appealDecisions.single.note, 'ok');
      expect(controller.isSubmitting, isFalse);
    });

    final cases = <ErrorCode, AppealDecisionOutcome>{
      ErrorCode.conflict: AppealDecisionOutcome.alreadyDecided,
      ErrorCode.notFound: AppealDecisionOutcome.alreadyDecided,
      ErrorCode.insufficientPermissions: AppealDecisionOutcome.needsAnotherModerator,
      ErrorCode.serverError: AppealDecisionOutcome.failed,
    };
    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value}', () async {
        repo.decideAppealResult = Result.failure(Failure(code: entry.key));
        final outcome = await controller.decide('ap-1', accept: false);
        expect(outcome, entry.value);
        expect(controller.errorCode, entry.value == AppealDecisionOutcome.failed ? entry.key : isNull);
      });
    }

    test('nota demasiado larga: falla en el dominio sin llamar al repo', () async {
      final outcome = await controller.decide('ap-1', accept: true, note: 'x' * 1001);
      expect(outcome, AppealDecisionOutcome.failed);
      expect(controller.errorCode, ErrorCode.invalidInput);
      expect(repo.appealDecisions, isEmpty);
    });

    test('una a la vez', () async {
      final first = controller.decide('ap-1', accept: true);
      final second = await controller.decide('ap-1', accept: false);
      await first;
      expect(second, AppealDecisionOutcome.failed);
      expect(repo.appealDecisions.length, 1);
    });

    test('dispose: no notifica después', () async {
      final future = controller.decide('ap-1', accept: true);
      controller.dispose();
      await future;
    });
  });
}
