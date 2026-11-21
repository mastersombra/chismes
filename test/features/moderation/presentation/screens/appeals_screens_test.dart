import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/moderation/domain/entities/account_status.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_appeal.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:chismes/features/moderation/domain/usecases/decide_appeal.dart';
import 'package:chismes/features/moderation/domain/usecases/decide_review.dart';
import 'package:chismes/features/moderation/domain/usecases/get_appeals.dart';
import 'package:chismes/features/moderation/domain/usecases/get_moderation_queue.dart';
import 'package:chismes/features/moderation/presentation/controllers/appeal_decision_controller.dart';
import 'package:chismes/features/moderation/presentation/controllers/appeals_controller.dart';
import 'package:chismes/features/moderation/presentation/controllers/moderation_queue_controller.dart';
import 'package:chismes/features/moderation/presentation/controllers/review_decision_controller.dart';
import 'package:chismes/features/moderation/presentation/screens/appeal_item_screen.dart';
import 'package:chismes/features/moderation/presentation/screens/moderation_queue_screen.dart';
import 'package:chismes/features/moderation/presentation/widgets/appeals_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_app_logger_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import '../../sanctions_fixtures.dart';

void main() {
  late FakeModerationRepository repo;

  setUp(() {
    repo = FakeModerationRepository();
    for (final unregister in [
      () => getIt.isRegistered<AppealDecisionController>() ? getIt.unregister<AppealDecisionController>() : null,
      () => getIt.isRegistered<AppealsController>() ? getIt.unregister<AppealsController>() : null,
      () => getIt.isRegistered<ModerationQueueController>() ? getIt.unregister<ModerationQueueController>() : null,
      () => getIt.isRegistered<ReviewDecisionController>() ? getIt.unregister<ReviewDecisionController>() : null,
    ]) {
      unregister();
    }
    getIt.registerFactory(() => AppealDecisionController(DecideAppeal(repo)));
    getIt.registerFactory(() => AppealsController(GetAppeals(repo), MockAppLogger()));
    getIt.registerFactory(() => ModerationQueueController(GetModerationQueue(repo), MockAppLogger()));
    getIt.registerFactory(() => ReviewDecisionController(DecideReview(repo)));
  });

  tearDown(() {
    getIt.unregister<AppealDecisionController>();
    getIt.unregister<AppealsController>();
    getIt.unregister<ModerationQueueController>();
    getIt.unregister<ReviewDecisionController>();
  });

  group('AppealItemScreen', () {
    /// Abre la pantalla desde una ruta para poder ver el resultado del pop
    Future<List<bool?>> pumpFromRoute(WidgetTester tester, ModerationAppeal appeal) async {
      final results = <bool?>[];
      await tester.pumpWidget(testableWidget(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => AppealItemScreen(appeal: appeal)),
            )),
            child: const Text('abrir'),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return results;
    }

    Future<void> decide(WidgetTester tester, {required bool accept, String? note}) async {
      await tester.tap(find.byKey(Key(accept ? 'acceptAppealButton' : 'rejectAppealButton')));
      await tester.pumpAndSettle();
      if (note != null) await tester.enterText(find.byKey(const Key('appealNoteField')), note);
      await tester.tap(find.byKey(const Key('confirmAppealDecisionButton')));
      await tester.pumpAndSettle();
    }

    testWidgets('pendiente: contenido, mensaje, decisión original, autor anónimo y acciones', (tester) async {
      await pumpFromRoute(tester, moderationAppeal(publishedAnonymously: true));

      expect(find.text('Apelación'), findsOneWidget);
      expect(find.text('Boda en el barrio'), findsOneWidget);
      expect(find.text('No era un insulto, era un chiste'), findsOneWidget);
      expect(find.text('Lo que dice el usuario'), findsOneWidget);
      expect(find.text('Rechazo original'), findsOneWidget);
      expect(find.text('nota del rechazo'), findsOneWidget);
      expect(find.text('3 reportes'), findsOneWidget);
      // SelectableText tiene sus propios Scrollable: arrastrar el ListView
      await tester.dragUntilVisible(find.text('La Chismosa'), find.byType(ListView), const Offset(0, -200));
      expect(find.text('La Chismosa'), findsOneWidget);
      expect(find.byKey(const Key('acceptAppealButton')), findsOneWidget);
      expect(find.byKey(const Key('rejectAppealButton')), findsOneWidget);
      expect(find.text('Decisión de la apelación'), findsNothing);
    });

    testWidgets('aceptar con nota: confirma, envía y sale con true', (tester) async {
      final results = await pumpFromRoute(tester, moderationAppeal());

      await tester.tap(find.byKey(const Key('acceptAppealButton')));
      await tester.pumpAndSettle();
      expect(find.text('¿Aceptar la apelación?'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('appealNoteField')), '  tiene razón  ');
      await tester.tap(find.byKey(const Key('confirmAppealDecisionButton')));
      await tester.pumpAndSettle();

      expect(repo.appealDecisions.single.accept, isTrue);
      expect(repo.appealDecisions.single.note, 'tiene razón');
      expect(results, [true]);
      expect(find.text('Apelación aceptada: falta anulada'), findsOneWidget);
    });

    testWidgets('mantener rechazo sin nota: nota null', (tester) async {
      final results = await pumpFromRoute(tester, moderationAppeal());

      await decide(tester, accept: false);

      expect(repo.appealDecisions.single.accept, isFalse);
      expect(repo.appealDecisions.single.note, isNull);
      expect(results, [true]);
      expect(find.text('Rechazo mantenido'), findsOneWidget);
    });

    testWidgets('cancelar el diálogo no decide', (tester) async {
      await pumpFromRoute(tester, moderationAppeal());

      await tester.tap(find.byKey(const Key('rejectAppealButton')));
      await tester.pumpAndSettle();
      expect(find.text('¿Mantener el rechazo?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.appealDecisions, isEmpty);
      expect(find.byType(AppealItemScreen), findsOneWidget);
    });

    testWidgets('ya decidida por otro: aviso y sale con true', (tester) async {
      repo.decideAppealResult = Result.failure(const DataFailure(code: ErrorCode.conflict));
      final results = await pumpFromRoute(tester, moderationAppeal());

      await decide(tester, accept: true);

      expect(results, [true]);
      expect(find.text('Otro moderador ya decidió esta apelación'), findsOneWidget);
    });

    testWidgets('exige otro moderador: aviso y se queda', (tester) async {
      repo.decideAppealResult = Result.failure(const PermissionFailure(code: ErrorCode.insufficientPermissions));
      final results = await pumpFromRoute(tester, moderationAppeal());

      await decide(tester, accept: true);

      expect(results, isEmpty);
      expect(find.byType(AppealItemScreen), findsOneWidget);
      expect(find.textContaining('otro moderador'), findsOneWidget);
    });

    testWidgets('error: snackbar de error y se queda', (tester) async {
      repo.decideAppealResult = Result.failure(const ServerFailure(code: ErrorCode.serverError));
      final results = await pumpFromRoute(tester, moderationAppeal());

      await decide(tester, accept: false);

      expect(results, isEmpty);
      expect(tester.widget<SnackBar>(find.byType(SnackBar)).backgroundColor, isNotNull);
      expect(find.byKey(const Key('rejectAppealButton')), findsOneWidget);
    });

    testWidgets('decidida: muestra la decisión con nota y sin acciones', (tester) async {
      await pumpFromRoute(
        tester,
        moderationAppeal(
          status: AppealStatus.rejected,
          decisionNote: 'sigue siendo acoso',
          originalSeverity: null,
          originalReason: null,
          originalNote: null,
          originalReasons: const [],
          originalReportCount: 0,
          authorDisplayName: null,
          authorUsername: null,
        ),
      );

      await tester.dragUntilVisible(find.text('sigue siendo acoso'), find.byType(ListView), const Offset(0, -200));
      expect(find.text('Decisión de la apelación'), findsOneWidget);
      expect(find.byKey(const Key('acceptAppealButton')), findsNothing);
    });

    testWidgets('320 px con letra grande: sin overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(testableWidget(
        child: AppealItemScreen(appeal: moderationAppeal(publishedAnonymously: true)),
        useScaffold: false,
        mediaQuery: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.5)),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('ModerationQueueScreen → Apelaciones', () {
    testWidgets('la pestaña carga apelaciones solo al abrirla', (tester) async {
      repo.appealPages[(AppealStatus.pending, 0)] = Result.success([moderationAppeal()]);

      await tester.pumpWidget(testableWidget(child: const ModerationQueueScreen(), useScaffold: false));
      await tester.pumpAndSettle();
      expect(repo.appealCalls, isEmpty);

      await tester.tap(find.text('Apelaciones'));
      await tester.pumpAndSettle();

      expect(repo.appealCalls, [(AppealStatus.pending, 0)]);
      expect(find.byType(AppealCard), findsOneWidget);
    });

    testWidgets('decidir una apelación la saca de la lista y recarga el historial de la cola', (tester) async {
      repo.appealPages[(AppealStatus.pending, 0)] = Result.success([moderationAppeal()]);
      repo.queue[ModerationQueueStatus.rejected] = Result.success(const []);

      await tester.pumpWidget(testableWidget(child: const ModerationQueueScreen(), useScaffold: false));
      await tester.pumpAndSettle();
      // Rechazados ya cargado: aceptar una apelación debe invalidarlo
      await tester.tap(find.text('Rechazados'));
      await tester.pumpAndSettle();
      final rejectedLoads = repo.queueCalls.where((s) => s == ModerationQueueStatus.rejected).length;

      await tester.tap(find.text('Apelaciones'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppealCard));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('acceptAppealButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmAppealDecisionButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AppealItemScreen), findsNothing);
      expect(find.byType(AppealCard), findsNothing);
      expect(find.text('No hay apelaciones pendientes'), findsOneWidget);

      await tester.tap(find.text('Rechazados'));
      await tester.pumpAndSettle();
      expect(
        repo.queueCalls.where((s) => s == ModerationQueueStatus.rejected).length,
        rejectedLoads + 1,
      );
    });

    testWidgets('320 px: las 4 pestañas sin overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repo.queue[ModerationQueueStatus.pending] = Result.success(const <ModerationItem>[]);

      await tester.pumpWidget(testableWidget(child: const ModerationQueueScreen(), useScaffold: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apelaciones'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
