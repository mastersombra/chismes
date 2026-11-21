import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/moderation/domain/entities/account_status.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_appeal.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:chismes/features/moderation/domain/usecases/get_appeals.dart';
import 'package:chismes/features/moderation/presentation/controllers/appeals_controller.dart';
import 'package:chismes/features/moderation/presentation/widgets/account_rejection_card.dart';
import 'package:chismes/features/moderation/presentation/widgets/appeal_sheet.dart';
import 'package:chismes/features/moderation/presentation/widgets/appeals_tab.dart';
import 'package:chismes/features/moderation/presentation/widgets/moderation_detail.dart';
import 'package:chismes/features/moderation/presentation/widgets/moderation_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mock_app_logger_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import '../../sanctions_fixtures.dart';

void main() {
  group('ModerationLabels (sanciones)', () {
    testWidgets('sanción, estado y filtro de apelación, fecha', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(testableWidget(child: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      expect(ModerationLabels.sanction(ctx, SanctionKind.warning), 'Advertencia');
      expect(ModerationLabels.sanction(ctx, SanctionKind.restriction), 'Restricción');
      expect(ModerationLabels.sanction(ctx, SanctionKind.suspension), 'Suspensión');
      expect(ModerationLabels.appealStatus(ctx, AppealStatus.pending), 'Apelación en revisión');
      expect(ModerationLabels.appealStatus(ctx, AppealStatus.accepted), 'Apelación aceptada');
      expect(ModerationLabels.appealStatus(ctx, AppealStatus.rejected), 'Apelación rechazada');
      expect(ModerationLabels.appealFilter(ctx, AppealStatus.pending), 'Pendientes');
      expect(ModerationLabels.appealFilter(ctx, AppealStatus.accepted), 'Aceptadas');
      expect(ModerationLabels.appealFilter(ctx, AppealStatus.rejected), 'Rechazadas');
      final date = ModerationLabels.date(ctx, DateTime.utc(2026, 11, 19, 12));
      expect(date, isNotEmpty);
      expect(date, isNot(contains('·')));
    });
  });

  group('DetailSection / DetailInfoRow', () {
    testWidgets('título, hijos, ícono y color', (tester) async {
      await tester.pumpWidget(testableWidget(
        child: const DetailSection(
          title: 'Sección',
          children: [DetailInfoRow(icon: Icons.notes, text: 'fila', color: Colors.red)],
        ),
      ));

      expect(find.text('Sección'), findsOneWidget);
      expect(find.text('fila'), findsOneWidget);
      expect(tester.widget<Icon>(find.byIcon(Icons.notes)).color, Colors.red);
    });
  });

  group('AccountRejectionCard', () {
    Future<void> pumpCard(WidgetTester tester, AccountRejection rejection,
        {bool submitting = false, VoidCallback? onAppeal}) {
      return tester.pumpWidget(testableWidget(
        child: SingleChildScrollView(
          child: AccountRejectionCard(
            rejection: rejection,
            submitting: submitting,
            onAppeal: onAppeal ?? () {},
          ),
        ),
      ));
    }

    testWidgets('vigente apelable: gravedad, sanción, motivo, puntos y botón', (tester) async {
      var tapped = false;
      await pumpCard(tester, accountRejection(), onAppeal: () => tapped = true);

      expect(find.text('Boda en el barrio'), findsOneWidget);
      expect(find.text('Advertencia'), findsOneWidget);
      expect(find.textContaining('Rechazado el'), findsOneWidget);
      expect(find.textContaining('2 puntos hasta el'), findsOneWidget);
      expect(find.textContaining('Puedes apelar hasta el'), findsOneWidget);

      await tester.tap(find.byKey(const Key('appealButton_q-1')));
      expect(tapped, isTrue);
    });

    testWidgets('1 punto en singular', (tester) async {
      await pumpCard(tester, accountRejection(points: 1, severity: ModerationSeverity.low));
      expect(find.textContaining('1 punto hasta el'), findsOneWidget);
    });

    testWidgets('enviando: botón deshabilitado con spinner', (tester) async {
      await pumpCard(tester, accountRejection(), submitting: true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ButtonStyleButton>(find.byKey(const Key('appealButton_q-1')));
      expect(button.onPressed, isNull);
    });

    for (final status in AppealStatus.values) {
      testWidgets('con apelación ${status.value}: muestra su estado, sin botón', (tester) async {
        await pumpCard(
          tester,
          accountRejection(canAppeal: false, appeal: accountAppeal(status: status)),
        );
        expect(find.textContaining('Apelación'), findsOneWidget);
        expect(find.byKey(const Key('appealButton_q-1')), findsNothing);
      });
    }

    testWidgets('anulado: etiqueta, sin puntos ni aviso de plazo', (tester) async {
      await pumpCard(
        tester,
        accountRejection(overturned: true, points: null, sanction: null, canAppeal: false),
      );
      expect(find.text('Anulado por apelación'), findsOneWidget);
      expect(find.textContaining('puntos hasta'), findsNothing);
      expect(find.text('El plazo para apelar venció'), findsNothing);
    });

    testWidgets('plazo vencido sin apelación', (tester) async {
      await pumpCard(tester, accountRejection(canAppeal: false, severity: null, reason: null));
      expect(find.text('El plazo para apelar venció'), findsOneWidget);
    });
  });

  group('AppealSheet', () {
    Future<String?> Function() openSheet(WidgetTester tester) {
      String? result;
      var done = false;
      return () async {
        await tester.pumpWidget(testableWidget(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await AppealSheet.show(context, subject: 'Boda en el barrio');
                done = true;
              },
              child: const Text('abrir'),
            ),
          ),
        ));
        await tester.tap(find.text('abrir'));
        await tester.pumpAndSettle();
        return done ? result : null;
      };
    }

    testWidgets('valida requerido, mínimo y devuelve el texto recortado', (tester) async {
      String? result;
      await tester.pumpWidget(testableWidget(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await AppealSheet.show(context, subject: 'Boda en el barrio'),
            child: const Text('abrir'),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.text('Apelar el rechazo'), findsOneWidget);
      expect(find.text('Boda en el barrio'), findsOneWidget);

      await tester.tap(find.byKey(const Key('submitAppealButton')));
      await tester.pumpAndSettle();
      expect(find.byType(AppealSheet), findsOneWidget, reason: 'vacío no envía');

      await tester.enterText(find.byKey(const Key('appealMessageField')), 'corto');
      await tester.tap(find.byKey(const Key('submitAppealButton')));
      await tester.pumpAndSettle();
      expect(find.byType(AppealSheet), findsOneWidget, reason: 'corto no envía');

      await tester.enterText(find.byKey(const Key('appealMessageField')), '  Era un chiste entre amigos  ');
      await tester.tap(find.byKey(const Key('submitAppealButton')));
      await tester.pumpAndSettle();

      expect(find.byType(AppealSheet), findsNothing);
      expect(result, 'Era un chiste entre amigos');
    });

    testWidgets('maxLength limita a 1000', (tester) async {
      await openSheet(tester)();
      final field = tester.widget<TextField>(find.descendant(
        of: find.byKey(const Key('appealMessageField')),
        matching: find.byType(TextField),
      ));
      expect(field.maxLength, 1000);
    });

    testWidgets('cancelar devuelve null', (tester) async {
      String? result = 'x';
      await tester.pumpWidget(testableWidget(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await AppealSheet.show(context, subject: 's'),
            child: const Text('abrir'),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });

  group('AppealsTab', () {
    late FakeModerationRepository repo;
    late AppealsController controller;

    setUp(() {
      repo = FakeModerationRepository();
      controller = AppealsController(GetAppeals(repo), MockAppLogger());
    });

    Future<void> pumpTab(WidgetTester tester, {ValueChanged<ModerationAppeal>? onOpen}) async {
      await tester.pumpWidget(testableWidget(
        child: AppealsTab(controller: controller, onOpen: onOpen ?? (_) {}),
      ));
      await tester.pump();
    }

    testWidgets('sin cargar: spinner', (tester) async {
      await pumpTab(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('pendientes vacías y segmentos', (tester) async {
      await controller.select(AppealStatus.pending);
      await pumpTab(tester);

      expect(find.text('No hay apelaciones pendientes'), findsOneWidget);
      expect(find.text('Pendientes'), findsOneWidget);
      expect(find.text('Aceptadas'), findsOneWidget);
      expect(find.text('Rechazadas'), findsOneWidget);
    });

    testWidgets('elegir un segmento carga esa lista (historial vacío)', (tester) async {
      await controller.select(AppealStatus.pending);
      await pumpTab(tester);

      await tester.tap(find.text('Aceptadas'));
      await tester.pumpAndSettle();

      expect(controller.selected, AppealStatus.accepted);
      expect(repo.appealCalls, contains((AppealStatus.accepted, 0)));
      expect(find.text('Todavía no hay decisiones aquí'), findsOneWidget);
    });

    testWidgets('403: sin permisos y sin reintentar', (tester) async {
      repo.appealPages[(AppealStatus.pending, 0)] =
          Result.failure(const PermissionFailure(code: ErrorCode.forbidden));
      await controller.select(AppealStatus.pending);
      await pumpTab(tester);

      expect(find.text('Tu cuenta no tiene permisos de moderación'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('error: reintentar vuelve a pedir', (tester) async {
      repo.appealPages[(AppealStatus.pending, 0)] =
          Result.failure(const ServerFailure(code: ErrorCode.serverError));
      await controller.select(AppealStatus.pending);
      await pumpTab(tester);
      expect(find.text('No se pudo cargar la cola'), findsOneWidget);

      repo.appealPages[(AppealStatus.pending, 0)] = Result.success([moderationAppeal()]);
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(AppealCard), findsOneWidget);
    });

    testWidgets('lista: tarjeta con gravedad, motivo, mensaje; tap abre', (tester) async {
      ModerationAppeal? opened;
      repo.appealPages[(AppealStatus.pending, 0)] = Result.success([moderationAppeal()]);
      await controller.select(AppealStatus.pending);
      await pumpTab(tester, onOpen: (a) => opened = a);

      expect(find.text('Boda en el barrio'), findsOneWidget);
      expect(find.text('“No era un insulto, era un chiste”'), findsOneWidget);

      await tester.tap(find.byType(AppealCard));
      expect(opened?.id, 'ap-1');
    });

    testWidgets('decidida: muestra su estado en la tarjeta', (tester) async {
      repo.appealPages[(AppealStatus.accepted, 0)] =
          Result.success([moderationAppeal(status: AppealStatus.accepted, originalSeverity: null, originalReason: null)]);
      await controller.select(AppealStatus.accepted);
      await pumpTab(tester);

      expect(find.text('Apelación aceptada'), findsOneWidget);
    });

    testWidgets('scroll al final pide la siguiente página', (tester) async {
      repo.appealPages[(AppealStatus.pending, 0)] = Result.success([
        for (var i = 0; i < GetAppeals.pageSize; i++) moderationAppeal(id: 'a-$i'),
      ]);
      await controller.select(AppealStatus.pending);
      await pumpTab(tester);

      await tester.fling(find.byType(ListView), const Offset(0, -20000), 5000);
      await tester.pumpAndSettle();

      expect(repo.appealCalls, contains((AppealStatus.pending, GetAppeals.pageSize)));
    });

    testWidgets('320 px sin overflow', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repo.appealPages[(AppealStatus.pending, 0)] = Result.success([moderationAppeal()]);
      await controller.select(AppealStatus.pending);
      await pumpTab(tester);

      expect(tester.takeException(), isNull);
    });
  });
}
