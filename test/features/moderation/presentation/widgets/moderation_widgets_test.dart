import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:chismes/features/moderation/domain/entities/review_decision.dart';
import 'package:chismes/features/moderation/presentation/widgets/moderation_item_card.dart';
import 'package:chismes/features/moderation/presentation/widgets/moderation_labels.dart';
import 'package:chismes/features/moderation/presentation/widgets/reject_decision_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_network_image.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import '../../moderation_fixtures.dart';

void main() {
  group('ModerationLabels', () {
    testWidgets('traduce razones conocidas, prefijos y deja las desconocidas', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(testableWidget(child: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      })));

      expect(ModerationLabels.reason(ctx, 'term:malparido'), 'Término: malparido');
      expect(ModerationLabels.reason(ctx, 'ai_score:harassment'), 'IA: harassment');
      expect(ModerationLabels.reason(ctx, 'potential_spam'), 'Posible spam o links');
      expect(ModerationLabels.reason(ctx, 'moderation_unavailable'), 'La IA no respondió');
      expect(ModerationLabels.reason(ctx, 'rules_unavailable'), 'No se pudieron leer las reglas');
      expect(ModerationLabels.reason(ctx, 'potential_personal_data'), 'Posibles datos personales');
      expect(ModerationLabels.reason(ctx, 'credible_threat'), 'Posible amenaza');
      expect(ModerationLabels.reason(ctx, 'audio_not_moderated'), 'Audio sin moderar');
      for (final code in ['spam', 'harassment', 'violence', 'sexual_content', 'misinformation', 'other']) {
        expect(ModerationLabels.reason(ctx, code), isNot(code), reason: code);
      }
      expect(ModerationLabels.reason(ctx, 'algo_nuevo'), 'algo_nuevo');

      for (final source in ModerationSource.values) {
        expect(ModerationLabels.source(ctx, source), isNotEmpty);
      }
      for (final severity in ModerationSeverity.values) {
        expect(ModerationLabels.severity(ctx, severity), isNotEmpty);
      }
      for (final reason in RejectReason.values) {
        expect(ModerationLabels.rejectReason(ctx, reason), isNotEmpty);
      }
      expect(ModerationLabels.decisionReason(ctx, 'hate'), 'Odio o discriminación');
      expect(ModerationLabels.decisionReason(ctx, 'texto libre'), 'texto libre');
      expect(ModerationLabels.dateTime(ctx, DateTime.utc(2026, 11, 19, 10)), contains('·'));
    });
  });

  group('ModerationItemCard', () {
    testWidgets('muestra estado, contenido, razones (+N), reportes y audio', (tester) async {
      var tapped = false;
      await tester.pumpWidget(testableWidget(
        child: ModerationItemCard(
          item: moderationItem(
            highPriority: true,
            autoHidden: true,
            source: ModerationSource.reports,
            reasons: const ['spam', 'harassment', 'violence', 'other', 'term:x'],
            reportCount: 3,
            hasAudio: true,
          ),
          onTap: () => tapped = true,
        ),
      ));

      expect(find.text('Prioridad alta'), findsOneWidget);
      expect(find.text('Reportes'), findsOneWidget);
      expect(find.text('Oculto por reportes'), findsOneWidget);
      expect(find.text('Boda en el barrio'), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
      expect(find.text('3 reportes'), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsOneWidget);

      await tester.tap(find.byType(ModerationItemCard));
      expect(tapped, isTrue);
    });

    testWidgets('decidido: gravedad y miniatura de la imagen', (tester) async {
      useFakeNetworkImages(addTearDown);
      await tester.pumpWidget(testableWidget(
        child: ModerationItemCard(
          item: moderationItem(
            status: ModerationQueueStatus.rejected,
            decisionSeverity: ModerationSeverity.critical,
            decidedAt: DateTime.utc(2026, 11, 20),
            imageUrl: 'https://img/x.jpg',
            reasons: const [],
          ),
          onTap: () {},
        ),
      ));
      await tester.pump();

      expect(find.text('Crítica'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Prioridad alta'), findsNothing);
    });

    testWidgets('sin overflow en 320px', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(testableWidget(
        child: SingleChildScrollView(
          child: ModerationItemCard(
            item: moderationItem(
              highPriority: true,
              autoHidden: true,
              reportCount: 12,
              hasAudio: true,
              subject: 'Un asunto larguísimo que no cabe en una sola línea de una pantalla',
              reasons: const ['term:una frase bastante larga para el chip', 'ai_score:harassment/threatening'],
            ),
            onTap: () {},
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('RejectDecisionSheet', () {
    Future<RejectSelection?> openSheet(WidgetTester tester, Future<void> Function() interact) async {
      RejectSelection? selection;
      var closed = false;
      await tester.pumpWidget(testableWidget(child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            selection = await RejectDecisionSheet.show(context);
            closed = true;
          },
          child: const Text('abrir'),
        ),
      )));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await interact();
      await tester.pumpAndSettle();
      expect(closed, isTrue);
      return selection;
    }

    testWidgets('rechazar exige gravedad; devuelve gravedad, motivo y nota', (tester) async {
      final selection = await openSheet(tester, () async {
        final confirm = find.byKey(const Key('confirmRejectButton'));
        expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

        await tester.tap(find.text('Grave'));
        await tester.pump();
        expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);

        await tester.tap(find.text('Spam'));
        await tester.enterText(find.byType(TextField), '  reincidente  ');
        await tester.pump();
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
      });

      expect(selection?.severity, ModerationSeverity.high);
      expect(selection?.reason, RejectReason.spam);
      expect(selection?.note, 'reincidente');
    });

    testWidgets('motivo se puede desmarcar y la nota vacía es null', (tester) async {
      final selection = await openSheet(tester, () async {
        await tester.tap(find.text('Leve'));
        await tester.tap(find.text('Spam'));
        await tester.pump();
        await tester.tap(find.text('Spam'));
        await tester.pump();
        final confirm = find.byKey(const Key('confirmRejectButton'));
        await tester.ensureVisible(confirm);
        await tester.tap(confirm);
      });

      expect(selection?.severity, ModerationSeverity.low);
      expect(selection?.reason, isNull);
      expect(selection?.note, isNull);
    });

    testWidgets('cancelar devuelve null', (tester) async {
      final selection = await openSheet(tester, () async {
        final cancel = find.text('Cancelar');
        await tester.ensureVisible(cancel);
        await tester.tap(cancel);
      });

      expect(selection, isNull);
    });
  });
}
