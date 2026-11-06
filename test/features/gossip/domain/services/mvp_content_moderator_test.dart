import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/domain/services/mvp_content_moderator.dart';
import 'package:chismes/features/gossip/domain/entities/create_gossip_input.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/domain/entities/moderation_decision.dart';

void main() {
  group('MvpModerationPolicy.evaluate', () {
    late MvpModerationPolicy policy;

    setUp(() {
      policy = const MvpModerationPolicy();
    });

    group('Contenido limpio', () {
      test('debe publicar contenido limpio sin problemas', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Chisme del día',
          content: 'Contenido completamente limpio y apropiado',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.publish);
        expect(decision.reasons, isEmpty);
        expect(decision.sources, contains(ModerationSource.localRules));
      });
    });

    group('Datos personales', () {
      test('debe enviar a revisión si contiene email', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Contacto',
          content: 'Escríbeme a correo@example.com para más info',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.review);
        expect(decision.reasons, contains(ModerationReason.potentialPersonalData));
      });

      test('debe enviar a revisión si contiene teléfono colombiano', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Contacto',
          content: 'Llámame al 3001234567',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.review);
        expect(decision.reasons, contains(ModerationReason.potentialPersonalData));
      });

      test('debe enviar a revisión si contiene teléfono con +57', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Contacto',
          content: 'Llámame al +57 300 123 4567',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.review);
        expect(decision.reasons, contains(ModerationReason.potentialPersonalData));
      });
    });

    group('Spam', () {
      test('debe enviar a revisión si contiene URL', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Enlace',
          content: 'Visita https://example.com para más información',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.review);
        expect(decision.reasons, contains(ModerationReason.potentialSpam));
      });

      test('debe enviar a revisión si contiene www.', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Enlace',
          content: 'Visita www.example.com',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.review);
        expect(decision.reasons, contains(ModerationReason.potentialSpam));
      });

      test('debe enviar a revisión si contiene caracteres repetidos (spam)', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'AAAAAAAA',
          content: 'miraaaaaaaaa esto',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.review);
        expect(decision.reasons, contains(ModerationReason.potentialSpam));
      });
    });

    group('Términos de revisión', () {
      test('debe enviar a revisión si contiene "hijueputa"', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Insulto',
          content: 'Ese tipo es un hijueputa',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.review);
        expect(decision.reasons, contains(ModerationReason.potentialProfanity));
      });

      test('debe enviar a revisión si contiene "gonorrea"', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Insulto',
          content: 'Ese gonorrea me robó',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.review);
        expect(decision.reasons, contains(ModerationReason.potentialProfanity));
      });

      test('debe ignorar términos de revisión incrustados en palabras', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Palabra válida',
          content: 'La mariposa es bonita', // contiene "marica" pero no como palabra completa
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        // No debe detectar el término porque no está como palabra completa
        expect(decision.verdict, ModerationVerdict.publish);
      });

      test('debe normalizar acentos y detectar "gónorrea"', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Insulto',
          content: 'Ese gónorrea me robó', // con acento
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.review);
        expect(decision.reasons, contains(ModerationReason.potentialProfanity));
      });

      test('debe normalizar números como letras y detectar "h1ju3put4"', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Insulto',
          content: 'Ese tipo es un h1ju3put4', // hijueputa con números
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.review);
        expect(decision.reasons, contains(ModerationReason.potentialProfanity));
      });
    });

    group('Amenazas creíbles', () {
      test('debe rechazar amenaza directa "te voy a matar"', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Amenaza',
          content: 'Te voy a matar si no pagas',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.reject);
        expect(decision.reasons, contains(ModerationReason.credibleThreat));
      });

      test('debe rechazar amenaza "lo vamos a golpear"', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Amenaza',
          content: 'Lo vamos a golpear cuando salga',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.reject);
        expect(decision.reasons, contains(ModerationReason.credibleThreat));
      });

      test('debe rechazar amenaza "la voy a atacar"', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Amenaza',
          content: 'La voy a atacar por lo que hizo',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.reject);
        expect(decision.reasons, contains(ModerationReason.credibleThreat));
      });
    });

    group('Múltiples problemas', () {
      test('debe combinar múltiples razones de revisión', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Múltiples problemas',
          content: 'Ese hijueputa tiene correo@example.com y su teléfono es 3001234567',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.review);
        expect(decision.reasons, contains(ModerationReason.potentialPersonalData));
        expect(decision.reasons, contains(ModerationReason.potentialProfanity));
        expect(decision.reasons.length, greaterThan(1));
      });

      test('debe priorizar rechazo sobre revisión si hay amenaza', () {
        final input = CreateGossipInput(
          countryId: '1',
          regionId: '1',
          cityId: '1',
          subject: 'Amenaza con insulto',
          content: 'Hijueputa te voy a matar',
          publishedAs: PublishAs.anonymous,
          idempotencyKey: 'test-key-1',
        );

        final decision = policy.evaluate(input);

        expect(decision.verdict, ModerationVerdict.reject);
        expect(decision.reasons, contains(ModerationReason.credibleThreat));
      });
    });
  });

  group('MvpContentModerator', () {
    late MvpContentModerator moderator;

    setUp(() {
      const policy = MvpModerationPolicy();
      moderator = const MvpContentModerator(policy: policy);
    });

    test('debe usar la política para moderar contenido', () async {
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Chisme limpio',
        content: 'Contenido apropiado',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final decision = await moderator.moderate(input);

      expect(decision.verdict, ModerationVerdict.publish);
      expect(decision.reasons, isEmpty);
    });

    test('debe detectar contenido problemático', () async {
      final input = CreateGossipInput(
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Amenaza',
        content: 'Te voy a matar',
        publishedAs: PublishAs.anonymous,
        idempotencyKey: 'test-key-1',
      );

      final decision = await moderator.moderate(input);

      expect(decision.verdict, ModerationVerdict.reject);
      expect(decision.reasons, contains(ModerationReason.credibleThreat));
    });
  });
}
