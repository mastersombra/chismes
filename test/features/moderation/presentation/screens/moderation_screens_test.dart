import 'package:chismes/core/di/injection_container.dart';
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
import 'package:chismes/features/moderation/presentation/screens/moderation_item_screen.dart';
import 'package:chismes/features/moderation/presentation/screens/moderation_queue_screen.dart';
import 'package:chismes/features/moderation/presentation/widgets/moderation_item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/fake_network_image.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import '../../moderation_fixtures.dart';
import 'moderation_screens_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GetModerationQueue>(),
  MockSpec<DecideReview>(),
  MockSpec<AppLogger>(),
])
void main() {
  late MockGetModerationQueue getQueue;
  late MockDecideReview decide;

  setUpAll(() {
    provideDummy<Result<Failure, List<ModerationItem>>>(Result.success(const []));
    provideDummy<Result<Failure, void>>(Result.success(null));
  });

  setUp(() {
    getQueue = MockGetModerationQueue();
    decide = MockDecideReview();
    if (getIt.isRegistered<ModerationQueueController>()) getIt.unregister<ModerationQueueController>();
    if (getIt.isRegistered<ReviewDecisionController>()) getIt.unregister<ReviewDecisionController>();
    getIt.registerFactory(() => ModerationQueueController(getQueue, MockAppLogger()));
    getIt.registerFactory(() => ReviewDecisionController(decide));
  });

  tearDown(() {
    getIt.unregister<ModerationQueueController>();
    getIt.unregister<ReviewDecisionController>();
  });

  void queueAnswers(Map<ModerationQueueStatus, Result<Failure, List<ModerationItem>>> answers) {
    for (final entry in answers.entries) {
      when(getQueue(status: entry.key, offset: anyNamed('offset'))).thenAnswer((_) async => entry.value);
    }
  }

  group('ModerationQueueScreen', () {
    testWidgets('carga pendientes; las otras pestañas al abrirlas', (tester) async {
      queueAnswers({
        ModerationQueueStatus.pending: Result.success([moderationItem(), moderationItem(id: 'q-2')]),
        ModerationQueueStatus.approved: Result.success(const []),
      });

      await tester.pumpWidget(testableWidget(child: const ModerationQueueScreen(), useScaffold: false));
      await tester.pumpAndSettle();

      expect(find.byType(ModerationItemCard), findsNWidgets(2));
      verifyNever(getQueue(status: ModerationQueueStatus.approved, offset: anyNamed('offset')));

      await tester.tap(find.text('Aprobados'));
      await tester.pumpAndSettle();

      expect(find.text('Todavía no hay decisiones aquí'), findsOneWidget);
      verify(getQueue(status: ModerationQueueStatus.approved, offset: anyNamed('offset'))).called(1);
    });

    testWidgets('cola vacía', (tester) async {
      queueAnswers({ModerationQueueStatus.pending: Result.success(const [])});

      await tester.pumpWidget(testableWidget(child: const ModerationQueueScreen(), useScaffold: false));
      await tester.pumpAndSettle();

      expect(find.text('No hay nada pendiente'), findsOneWidget);
    });

    testWidgets('403: sin permisos y sin botón de reintentar', (tester) async {
      queueAnswers({
        ModerationQueueStatus.pending: Result.failure(const PermissionFailure(code: ErrorCode.forbidden)),
      });

      await tester.pumpWidget(testableWidget(child: const ModerationQueueScreen(), useScaffold: false));
      await tester.pumpAndSettle();

      expect(find.text('Tu cuenta no tiene permisos de moderación'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('error de red: reintentar vuelve a pedir', (tester) async {
      queueAnswers({
        ModerationQueueStatus.pending: Result.failure(const ServerFailure(code: ErrorCode.serverError)),
      });

      await tester.pumpWidget(testableWidget(child: const ModerationQueueScreen(), useScaffold: false));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo cargar la cola'), findsOneWidget);

      queueAnswers({ModerationQueueStatus.pending: Result.success([moderationItem()])});
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(ModerationItemCard), findsOneWidget);
    });

    testWidgets('scroll al final pide la siguiente página', (tester) async {
      final firstPage = [
        for (var i = 0; i < GetModerationQueue.pageSize; i++) moderationItem(id: 'q-$i'),
      ];
      when(getQueue(status: ModerationQueueStatus.pending, offset: 0))
          .thenAnswer((_) async => Result.success(firstPage));
      when(getQueue(status: ModerationQueueStatus.pending, offset: GetModerationQueue.pageSize))
          .thenAnswer((_) async => Result.success([moderationItem(id: 'q-extra')]));

      await tester.pumpWidget(testableWidget(child: const ModerationQueueScreen(), useScaffold: false));
      await tester.pumpAndSettle();
      await tester.fling(find.byType(ListView), const Offset(0, -20000), 5000);
      await tester.pumpAndSettle();

      verify(getQueue(status: ModerationQueueStatus.pending, offset: GetModerationQueue.pageSize)).called(1);
    });

    testWidgets('al aprobar en el detalle el ítem sale de pendientes', (tester) async {
      queueAnswers({ModerationQueueStatus.pending: Result.success([moderationItem()])});
      when(decide(any)).thenAnswer((_) async => Result.success(null));

      await tester.pumpWidget(testableWidget(child: const ModerationQueueScreen(), useScaffold: false));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ModerationItemCard));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('approveButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmApproveButton')));
      await tester.pumpAndSettle();

      expect(find.byType(ModerationQueueScreen), findsOneWidget);
      expect(find.byType(ModerationItemCard), findsNothing);
      expect(find.text('Aprobado y publicado'), findsOneWidget);
    });
  });

  group('ModerationItemScreen', () {
    Future<void> pumpItem(WidgetTester tester, ModerationItem item) async {
      await tester.pumpWidget(testableWidget(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<bool>(builder: (_) => ModerationItemScreen(item: item)),
            ),
            child: const Text('abrir'),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    testWidgets('pendiente: contenido, razones, autor real de anónimo y acciones', (tester) async {
      useFakeNetworkImages(addTearDown);
      await pumpItem(tester, moderationItem(
        publishedAnonymously: true,
        highPriority: true,
        autoHidden: true,
        reasons: const ['term:malparido', 'potential_personal_data'],
        reportCount: 4,
        imagePreviewUrl: 'https://signed/x.jpg',
        hasAudio: true,
      ));

      expect(find.text('Boda en el barrio'), findsOneWidget);
      expect(find.text('Término: malparido'), findsOneWidget);
      expect(find.text('Posibles datos personales'), findsOneWidget);
      expect(find.text('4 reportes'), findsOneWidget);
      expect(find.text('La Chismosa'), findsOneWidget);
      expect(find.textContaining('Publicado como anónimo'), findsOneWidget);
      expect(find.textContaining('Tiene audio'), findsOneWidget);
      expect(find.byKey(const Key('approveButton')), findsOneWidget);
      expect(find.byKey(const Key('rejectButton')), findsOneWidget);
    });

    testWidgets('rechazar: hoja → decisión con gravedad → vuelve', (tester) async {
      when(decide(any)).thenAnswer((_) async => Result.success(null));
      await pumpItem(tester, moderationItem());

      await tester.tap(find.byKey(const Key('rejectButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crítica'));
      await tester.pump();
      final confirm = find.byKey(const Key('confirmRejectButton'));
      await tester.ensureVisible(confirm);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      verify(decide(const ReviewDecision.reject(queueId: 'q-1', severity: ModerationSeverity.critical)))
          .called(1);
      expect(find.byType(ModerationItemScreen), findsNothing);
      expect(find.text('Rechazado: el chisme quedó oculto'), findsOneWidget);
    });

    testWidgets('cancelar la confirmación de aprobar no decide', (tester) async {
      await pumpItem(tester, moderationItem());

      await tester.tap(find.byKey(const Key('approveButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(decide(any));
      expect(find.byType(ModerationItemScreen), findsOneWidget);
    });

    testWidgets('ya decidido por otro: aviso y vuelve', (tester) async {
      when(decide(any)).thenAnswer((_) async => Result.failure(const DataFailure(code: ErrorCode.conflict)));
      await pumpItem(tester, moderationItem());

      await tester.tap(find.byKey(const Key('approveButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmApproveButton')));
      await tester.pumpAndSettle();

      expect(find.byType(ModerationItemScreen), findsNothing);
      expect(find.text('Ya no está pendiente: otro moderador lo decidió'), findsOneWidget);
    });

    testWidgets('error: se queda en la pantalla con aviso', (tester) async {
      when(decide(any)).thenAnswer(
        (_) async => Result.failure(const ServerFailure(code: ErrorCode.serverError)),
      );
      await pumpItem(tester, moderationItem());

      await tester.tap(find.byKey(const Key('approveButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirmApproveButton')));
      await tester.pumpAndSettle();

      expect(find.byType(ModerationItemScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('decidido: muestra la decisión y no las acciones', (tester) async {
      await pumpItem(tester, moderationItem(
        status: ModerationQueueStatus.rejected,
        decidedAt: DateTime.utc(2026, 11, 20, 8),
        decisionSeverity: ModerationSeverity.high,
        decisionReason: 'harassment',
        decisionNote: 'Reincidente',
        authorDisplayName: null,
        authorUsername: null,
      ));

      expect(find.text('Rechazados'), findsOneWidget);
      expect(find.text('Gravedad: Grave'), findsOneWidget);
      expect(find.textContaining('Motivo: '), findsOneWidget);
      expect(find.text('Reincidente'), findsOneWidget);
      expect(find.textContaining('Decidido el'), findsOneWidget);
      expect(find.text('Sin nombre de perfil'), findsOneWidget);
      expect(find.byKey(const Key('approveButton')), findsNothing);
    });

    testWidgets('aprobado: icono de aprobado', (tester) async {
      await pumpItem(tester, moderationItem(
        status: ModerationQueueStatus.approved,
        decidedAt: DateTime.utc(2026, 11, 20, 8),
      ));

      expect(find.text('Aprobados'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });
}
