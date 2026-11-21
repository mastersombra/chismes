import 'dart:async';

import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/moderation/domain/entities/account_status.dart';
import 'package:chismes/features/moderation/domain/usecases/get_account_status.dart';
import 'package:chismes/features/moderation/domain/usecases/submit_appeal.dart';
import 'package:chismes/features/moderation/presentation/controllers/account_status_controller.dart';
import 'package:chismes/features/moderation/presentation/screens/account_status_screen.dart';
import 'package:chismes/features/moderation/presentation/widgets/account_rejection_card.dart';
import 'package:chismes/features/moderation/presentation/widgets/appeal_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_app_logger_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import '../../sanctions_fixtures.dart';

void main() {
  late FakeAccountStatusRepository repo;

  setUp(() {
    repo = FakeAccountStatusRepository();
    if (getIt.isRegistered<AccountStatusController>()) getIt.unregister<AccountStatusController>();
    getIt.registerFactory(
      () => AccountStatusController(GetAccountStatus(repo), SubmitAppeal(repo), MockAppLogger()),
    );
  });

  tearDown(() => getIt.unregister<AccountStatusController>());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(testableWidget(child: const AccountStatusScreen(), useScaffold: false));
    await tester.pumpAndSettle();
  }

  testWidgets('cargando: spinner', (tester) async {
    repo.statusGate = Completer<void>();
    repo.statusResults.add(Result.success(accountStatus()));

    await tester.pumpWidget(testableWidget(child: const AccountStatusScreen(), useScaffold: false));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repo.statusGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accountState_ok')), findsOneWidget);
  });

  testWidgets('error: mensaje y reintentar', (tester) async {
    repo.statusResults
      ..add(Result.failure(const ServerFailure(code: ErrorCode.serverError)))
      ..add(Result.success(accountStatus()));

    await pumpScreen(tester);
    expect(find.text('No se pudo cargar el estado de tu cuenta'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('accountState_ok')), findsOneWidget);
    expect(repo.statusCalls, 2);
  });

  testWidgets('en orden: encabezado, puntos y sin rechazos', (tester) async {
    repo.statusResults.add(Result.success(accountStatus()));
    await pumpScreen(tester);

    expect(find.byKey(const Key('accountState_ok')), findsOneWidget);
    expect(find.text('Tu cuenta está en orden'), findsOneWidget);
    expect(find.text('0 de 10'), findsOneWidget);
    expect(find.textContaining('vencen a los 90 días'), findsOneWidget);
    expect(find.text('No tienes contenido rechazado.'), findsOneWidget);
    expect(find.text('Faltas de una cuenta anterior'), findsNothing);
  });

  testWidgets('restringida con fecha, apelación pendiente y faltas heredadas', (tester) async {
    repo.statusResults.add(Result.success(accountStatus(
      state: AccountState.restricted,
      restrictedUntil: DateTime.utc(2026, 11, 22, 10),
      activePoints: 12,
      inherited: InheritedStrikes(
        points: 6,
        occurredAt: DateTime.utc(2026, 11, 1),
        expiresAt: DateTime.utc(2027, 1, 30),
        sanction: SanctionKind.restriction,
      ),
      rejections: [
        accountRejection(canAppeal: false, appeal: accountAppeal()),
      ],
    )));
    await pumpScreen(tester);

    expect(find.byKey(const Key('accountState_restricted')), findsOneWidget);
    expect(find.textContaining('Sin publicar hasta el'), findsOneWidget);
    expect(find.text('Tienes una apelación en revisión.'), findsOneWidget);
    expect(find.text('12 de 10'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, 1.0);
    expect(find.text('Faltas de una cuenta anterior'), findsOneWidget);
    expect(find.textContaining('6 puntos'), findsOneWidget);
  });

  testWidgets('restringida sin fecha', (tester) async {
    repo.statusResults.add(Result.success(accountStatus(state: AccountState.restricted)));
    await pumpScreen(tester);
    expect(find.text('Tu cuenta está restringida'), findsOneWidget);
  });

  testWidgets('suspendida', (tester) async {
    repo.statusResults.add(Result.success(accountStatus(state: AccountState.suspended, activePoints: 10)));
    await pumpScreen(tester);

    expect(find.byKey(const Key('accountState_suspended')), findsOneWidget);
    expect(find.text('Tu cuenta está suspendida'), findsOneWidget);
  });

  testWidgets('lista de rechazos: estados de apelación, anulado y plazo vencido', (tester) async {
    repo.statusResults.add(Result.success(accountStatus(rejections: [
      accountRejection(queueId: 'q-1'),
      accountRejection(queueId: 'q-2', canAppeal: false, appeal: accountAppeal(status: AppealStatus.accepted)),
      accountRejection(queueId: 'q-3', canAppeal: false, appeal: accountAppeal(status: AppealStatus.rejected)),
      accountRejection(queueId: 'q-4', canAppeal: false, overturned: true, points: null, sanction: null),
      accountRejection(queueId: 'q-5', canAppeal: false),
    ])));
    await pumpScreen(tester);

    expect(find.byType(AccountRejectionCard), findsWidgets);
    expect(find.byKey(const Key('appealButton_q-1')), findsOneWidget);
    // La lista es perezosa: se verifica cada uno al hacerlo visible
    for (final text in [
      'Apelación aceptada',
      'Apelación rechazada',
      'Anulado por apelación',
      'El plazo para apelar venció',
    ]) {
      await tester.scrollUntilVisible(find.text(text), 200);
      expect(find.text(text), findsOneWidget);
    }
  });

  group('apelar', () {
    Future<void> appeal(WidgetTester tester, String message) async {
      await tester.tap(find.byKey(const Key('appealButton_q-1')));
      await tester.pumpAndSettle();
      expect(find.byType(AppealSheet), findsOneWidget);
      await tester.enterText(find.byKey(const Key('appealMessageField')), message);
      await tester.tap(find.byKey(const Key('submitAppealButton')));
      await tester.pumpAndSettle();
    }

    testWidgets('enviada: snackbar y recarga con la apelación', (tester) async {
      repo.statusResults
        ..add(Result.success(accountStatus(rejections: [accountRejection()])))
        ..add(Result.success(accountStatus(rejections: [
          accountRejection(canAppeal: false, appeal: accountAppeal()),
        ])));
      await pumpScreen(tester);

      await appeal(tester, 'Era un chiste entre amigos');

      expect(repo.appeals.single, ('q-1', 'Era un chiste entre amigos'));
      expect(find.text('Apelación enviada. Te avisaremos aquí cuando se revise.'), findsOneWidget);
      expect(find.text('Apelación en revisión'), findsOneWidget);
      expect(find.byKey(const Key('appealButton_q-1')), findsNothing);
    });

    testWidgets('no permitida (409): snackbar', (tester) async {
      repo.statusResults.add(Result.success(accountStatus(rejections: [accountRejection()])));
      repo.appealResult = Result.failure(const DataFailure(code: ErrorCode.conflict));
      await pumpScreen(tester);

      await appeal(tester, 'Era un chiste entre amigos');

      expect(find.text('Este rechazo ya no se puede apelar'), findsOneWidget);
    });

    testWidgets('error: snackbar de error', (tester) async {
      repo.statusResults.add(Result.success(accountStatus(rejections: [accountRejection()])));
      repo.appealResult = Result.failure(const ServerFailure(code: ErrorCode.serverError));
      await pumpScreen(tester);

      await appeal(tester, 'Era un chiste entre amigos');

      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, isNotNull);
      expect(repo.statusCalls, 1, reason: 'no recarga tras un error');
    });

    testWidgets('cancelar la hoja no envía', (tester) async {
      repo.statusResults.add(Result.success(accountStatus(rejections: [accountRejection()])));
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('appealButton_q-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(repo.appeals, isEmpty);
    });
  });

  testWidgets('320 px con letra grande: sin overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repo.statusResults.add(Result.success(accountStatus(
      state: AccountState.restricted,
      restrictedUntil: DateTime.utc(2026, 11, 22, 10),
      activePoints: 4,
      inherited: InheritedStrikes(
        points: 2,
        occurredAt: DateTime.utc(2026, 11, 1),
        expiresAt: DateTime.utc(2027, 1, 30),
      ),
      rejections: [accountRejection(), accountRejection(queueId: 'q-2', canAppeal: false)],
    )));

    await tester.pumpWidget(testableWidget(
      child: const AccountStatusScreen(),
      useScaffold: false,
      mediaQuery: const MediaQueryData(size: Size(320, 640), textScaler: TextScaler.linear(1.5)),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
