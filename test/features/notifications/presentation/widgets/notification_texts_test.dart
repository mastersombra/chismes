import 'package:chismes/features/notifications/domain/entities/app_notification.dart';
import 'package:chismes/features/notifications/presentation/widgets/notification_texts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_wrapper.dart';
import '../../notifications_fixtures.dart';

void main() {
  /// Ejecuta [body] con un BuildContext localizado en [locale]
  Future<void> withContext(
    WidgetTester tester,
    void Function(BuildContext context) body, {
    Locale locale = const Locale('es'),
  }) async {
    late BuildContext captured;
    await tester.pumpWidget(testableWidget(
      locale: locale,
      child: Builder(builder: (context) {
        captured = context;
        return const SizedBox();
      }),
    ));
    body(captured);
  }

  const subjectGossip = NotificationGossip(id: kGossipId, subject: 'La fiesta');

  group('sentence (es)', () {
    testWidgets('sociales usan nombre visible o @usuario', (tester) async {
      await withContext(tester, (c) {
        String s(NotificationType type, NotificationActor? actor) =>
            NotificationTexts.sentence(c, tNotification(type: type, actor: actor));

        expect(s(NotificationType.newFollower, tActor), '@beto empezó a seguirte');
        expect(s(NotificationType.followRequest, tActor), '@beto quiere seguirte');
        expect(
          s(NotificationType.followAccepted,
              const NotificationActor(id: kActorId, username: 'beto', displayName: 'Beto G')),
          'Beto G aceptó tu solicitud',
        );
        expect(s(NotificationType.newFollower, null), 'Usuario empezó a seguirte');
        expect(s(NotificationType.newFollower, const NotificationActor(id: kActorId)),
            'Usuario empezó a seguirte');
      });
    });

    testWidgets('de la cuenta incluyen el asunto', (tester) async {
      await withContext(tester, (c) {
        String s(NotificationType type, {String? reason}) => NotificationTexts.sentence(
            c, tNotification(type: type, gossip: subjectGossip, reason: reason));

        expect(s(NotificationType.gossipApproved), 'Tu chisme "La fiesta" fue aprobado');
        expect(s(NotificationType.gossipRejected), 'Tu chisme "La fiesta" fue rechazado');
        expect(s(NotificationType.gossipRejected, reason: 'spam'),
            'Tu chisme "La fiesta" fue rechazado: Spam');
        expect(s(NotificationType.appealAccepted),
            'Tu apelación de "La fiesta" fue aceptada: el chisme volvió a publicarse');
        expect(s(NotificationType.appealRejected), 'Tu apelación de "La fiesta" fue rechazada');
      });
    });
  });

  testWidgets('sentence (en)', (tester) async {
    await withContext(locale: const Locale('en'), tester, (c) {
      expect(NotificationTexts.sentence(c, tNotification()), '@beto started following you');
      expect(
        NotificationTexts.sentence(
            c, tNotification(type: NotificationType.gossipRejected, gossip: subjectGossip, reason: 'x')),
        "Your gossip \"La fiesta\" was rejected: it doesn't follow the community guidelines",
      );
    });
  });

  testWidgets('reason traduce los códigos predefinidos; desconocido → genérico', (tester) async {
    await withContext(tester, (c) {
      expect(NotificationTexts.reason(c, 'harassment'), 'Acoso o intimidación');
      expect(NotificationTexts.reason(c, 'hate'), 'Odio o discriminación');
      expect(NotificationTexts.reason(c, 'sexual_content'), 'Contenido sexual');
      expect(NotificationTexts.reason(c, 'violence'), 'Violencia o amenazas');
      expect(NotificationTexts.reason(c, 'personal_data'), 'Datos personales');
      expect(NotificationTexts.reason(c, 'spam'), 'Spam');
      expect(NotificationTexts.reason(c, 'misinformation'), 'Desinformación');
      expect(NotificationTexts.reason(c, 'other'), 'Otro motivo');
      expect(NotificationTexts.reason(c, 'nota libre'), 'no cumple las normas de la comunidad');
    });
  });

  test('excerpt recorta asuntos largos y rellena los vacíos', () {
    expect(NotificationTexts.excerpt('  Corto  '), 'Corto');
    expect(NotificationTexts.excerpt(null), '…');
    expect(NotificationTexts.excerpt('   '), '…');
    final long = '${'a' * 39} ${'b' * 20}';
    expect(NotificationTexts.excerpt(long), '${'a' * 39}…');
    expect(NotificationTexts.excerpt('c' * 40), 'c' * 40);
  });

  testWidgets('relativeTime: ahora, min, h, d y fecha desde 7 días', (tester) async {
    final now = DateTime(2026, 11, 24, 12);
    await withContext(tester, (c) {
      String t(Duration ago) => NotificationTexts.relativeTime(c, now.subtract(ago), now);

      expect(t(const Duration(seconds: 30)), 'ahora');
      expect(t(const Duration(minutes: 5)), '5 min');
      expect(t(const Duration(minutes: 59)), '59 min');
      expect(t(const Duration(hours: 3)), '3 h');
      expect(t(const Duration(days: 2)), '2 d');
      expect(t(const Duration(days: 6, hours: 23)), '6 d');
      expect(
        t(const Duration(days: 10)),
        MaterialLocalizations.of(c).formatShortMonthDay(DateTime(2026, 11, 14, 12)),
      );
    });
  });
}
