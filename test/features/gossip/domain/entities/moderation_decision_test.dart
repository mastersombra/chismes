import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/domain/entities/moderation_decision.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';

void main() {
  group('ModerationDecision', () {
    test('debe crear decisión con verdict publish', () {
      // Act
      final decision = ModerationDecision(verdict: ModerationVerdict.publish);

      // Assert
      expect(decision.verdict, ModerationVerdict.publish);
      expect(decision.reasons, isEmpty);
      expect(decision.sources, isEmpty);
    });

    test('debe crear decisión con razones', () {
      // Act
      final decision = ModerationDecision(
        verdict: ModerationVerdict.review,
        reasons: [ModerationReason.potentialProfanity, ModerationReason.potentialSpam],
      );

      // Assert
      expect(decision.reasons.length, 2);
      expect(decision.reasons, contains(ModerationReason.potentialProfanity));
      expect(decision.reasons, contains(ModerationReason.potentialSpam));
    });

    test('debe crear decisión con sources', () {
      // Act
      final decision = ModerationDecision(
        verdict: ModerationVerdict.reject,
        sources: [ModerationSource.externalProvider, ModerationSource.localRules],
      );

      // Assert
      expect(decision.sources.length, 2);
      expect(decision.sources, contains(ModerationSource.externalProvider));
      expect(decision.sources, contains(ModerationSource.localRules));
    });

    test('initialGossipStatus debe ser published para verdict publish', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.publish);

      // Act & Assert
      expect(decision.initialGossipStatus, GossipStatus.published);
    });

    test('initialGossipStatus debe ser draft para verdict review', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.review);

      // Act & Assert
      expect(decision.initialGossipStatus, GossipStatus.draft);
    });

    test('initialGossipStatus debe ser draft para verdict reject', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.reject);

      // Act & Assert
      expect(decision.initialGossipStatus, GossipStatus.draft);
    });

    test('initialModerationStatus debe ser approved para verdict publish', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.publish);

      // Act & Assert
      expect(decision.initialModerationStatus, ModerationStatus.approved);
    });

    test('initialModerationStatus debe ser pending para verdict review', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.review);

      // Act & Assert
      expect(decision.initialModerationStatus, ModerationStatus.pending);
    });

    test('initialModerationStatus debe ser rejected para verdict reject', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.reject);

      // Act & Assert
      expect(decision.initialModerationStatus, ModerationStatus.rejected);
    });

    test('requiresHumanReview debe ser true para verdict review', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.review);

      // Act & Assert
      expect(decision.requiresHumanReview, isTrue);
    });

    test('requiresHumanReview debe ser false para verdict publish', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.publish);

      // Act & Assert
      expect(decision.requiresHumanReview, isFalse);
    });

    test('requiresHumanReview debe ser false para verdict reject', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.reject);

      // Act & Assert
      expect(decision.requiresHumanReview, isFalse);
    });

    test('isRejected debe ser true para verdict reject', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.reject);

      // Act & Assert
      expect(decision.isRejected, isTrue);
    });

    test('isRejected debe ser false para verdict publish', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.publish);

      // Act & Assert
      expect(decision.isRejected, isFalse);
    });

    test('isRejected debe ser false para verdict review', () {
      // Arrange
      final decision = ModerationDecision(verdict: ModerationVerdict.review);

      // Act & Assert
      expect(decision.isRejected, isFalse);
    });

    test('mostRestrictive debe retornar reject cuando uno es reject', () {
      // Arrange
      final publish = ModerationDecision(verdict: ModerationVerdict.publish);
      final reject = ModerationDecision(verdict: ModerationVerdict.reject);

      // Act
      final result = ModerationDecision.mostRestrictive(publish, reject);

      // Assert
      expect(result.verdict, ModerationVerdict.reject);
    });

    test('mostRestrictive debe retornar review cuando es más restrictivo', () {
      // Arrange
      final publish = ModerationDecision(verdict: ModerationVerdict.publish);
      final review = ModerationDecision(verdict: ModerationVerdict.review);

      // Act
      final result = ModerationDecision.mostRestrictive(publish, review);

      // Assert
      expect(result.verdict, ModerationVerdict.review);
    });

    test('mostRestrictive debe combinar reasons de ambas decisiones', () {
      // Arrange
      final first = ModerationDecision(
        verdict: ModerationVerdict.publish,
        reasons: [ModerationReason.potentialProfanity],
      );
      final second = ModerationDecision(
        verdict: ModerationVerdict.review,
        reasons: [ModerationReason.potentialSpam],
      );

      // Act
      final result = ModerationDecision.mostRestrictive(first, second);

      // Assert
      expect(result.reasons.length, 2);
      expect(result.reasons, contains(ModerationReason.potentialProfanity));
      expect(result.reasons, contains(ModerationReason.potentialSpam));
    });

    test('mostRestrictive debe combinar sources de ambas decisiones', () {
      // Arrange
      final first = ModerationDecision(
        verdict: ModerationVerdict.publish,
        sources: [ModerationSource.localRules],
      );
      final second = ModerationDecision(
        verdict: ModerationVerdict.review,
        sources: [ModerationSource.externalProvider],
      );

      // Act
      final result = ModerationDecision.mostRestrictive(first, second);

      // Assert
      expect(result.sources.length, 2);
      expect(result.sources, contains(ModerationSource.localRules));
      expect(result.sources, contains(ModerationSource.externalProvider));
    });

    test('debe eliminar reasons duplicadas', () {
      // Arrange
      final decision = ModerationDecision(
        verdict: ModerationVerdict.review,
        reasons: [
          ModerationReason.potentialProfanity,
          ModerationReason.potentialProfanity, // Duplicada
        ],
      );

      // Act & Assert - Set elimina duplicados
      expect(decision.reasons.length, 1);
      expect(decision.reasons.first, ModerationReason.potentialProfanity);
    });

    test('debe eliminar sources duplicadas', () {
      // Arrange
      final decision = ModerationDecision(
        verdict: ModerationVerdict.review,
        sources: [
          ModerationSource.localRules,
          ModerationSource.localRules, // Duplicada
        ],
      );

      // Act & Assert
      expect(decision.sources.length, 1);
      expect(decision.sources.first, ModerationSource.localRules);
    });

    test('dos decisiones con mismos valores deben ser iguales (Equatable)', () {
      // Arrange
      final decision1 = ModerationDecision(
        verdict: ModerationVerdict.publish,
        reasons: [ModerationReason.potentialSpam],
        sources: [ModerationSource.localRules],
      );
      final decision2 = ModerationDecision(
        verdict: ModerationVerdict.publish,
        reasons: [ModerationReason.potentialSpam],
        sources: [ModerationSource.localRules],
      );

      // Act & Assert
      expect(decision1, equals(decision2));
      expect(decision1.hashCode, equals(decision2.hashCode));
    });

    group('mostRestrictive - Casos adicionales', () {
      test('debe retornar reject cuando first es reject y second es publish', () {
        // Arrange
        final reject = ModerationDecision(verdict: ModerationVerdict.reject);
        final publish = ModerationDecision(verdict: ModerationVerdict.publish);

        // Act
        final result = ModerationDecision.mostRestrictive(reject, publish);

        // Assert
        expect(result.verdict, ModerationVerdict.reject);
      });

      test('debe retornar review cuando first es review y second es publish', () {
        // Arrange
        final review = ModerationDecision(verdict: ModerationVerdict.review);
        final publish = ModerationDecision(verdict: ModerationVerdict.publish);

        // Act
        final result = ModerationDecision.mostRestrictive(review, publish);

        // Assert
        expect(result.verdict, ModerationVerdict.review);
      });

      test('debe retornar reject cuando first es reject y second es review', () {
        // Arrange
        final reject = ModerationDecision(verdict: ModerationVerdict.reject);
        final review = ModerationDecision(verdict: ModerationVerdict.review);

        // Act
        final result = ModerationDecision.mostRestrictive(reject, review);

        // Assert
        expect(result.verdict, ModerationVerdict.reject);
      });

      test('debe retornar reject cuando ambos son reject', () {
        // Arrange
        final reject1 = ModerationDecision(
          verdict: ModerationVerdict.reject,
          reasons: [ModerationReason.credibleThreat],
        );
        final reject2 = ModerationDecision(
          verdict: ModerationVerdict.reject,
          reasons: [ModerationReason.potentialViolence],
        );

        // Act
        final result = ModerationDecision.mostRestrictive(reject1, reject2);

        // Assert
        expect(result.verdict, ModerationVerdict.reject);
        expect(result.reasons.length, 2);
      });

      test('debe retornar review cuando ambos son review', () {
        // Arrange
        final review1 = ModerationDecision(
          verdict: ModerationVerdict.review,
          reasons: [ModerationReason.potentialProfanity],
        );
        final review2 = ModerationDecision(
          verdict: ModerationVerdict.review,
          reasons: [ModerationReason.potentialSpam],
        );

        // Act
        final result = ModerationDecision.mostRestrictive(review1, review2);

        // Assert
        expect(result.verdict, ModerationVerdict.review);
        expect(result.reasons.length, 2);
      });

      test('debe retornar publish cuando ambos son publish', () {
        // Arrange
        final publish1 = ModerationDecision(
          verdict: ModerationVerdict.publish,
          sources: [ModerationSource.localRules],
        );
        final publish2 = ModerationDecision(
          verdict: ModerationVerdict.publish,
          sources: [ModerationSource.externalProvider],
        );

        // Act
        final result = ModerationDecision.mostRestrictive(publish1, publish2);

        // Assert
        expect(result.verdict, ModerationVerdict.publish);
        expect(result.sources.length, 2);
      });
    });

    group('ModerationReason - Cobertura completa', () {
      test('debe tener todos los valores del enum disponibles', () {
        // Act & Assert - Verifica que todos los valores existen
        expect(ModerationReason.potentialProfanity, isNotNull);
        expect(ModerationReason.potentialPersonalData, isNotNull);
        expect(ModerationReason.potentialSpam, isNotNull);
        expect(ModerationReason.potentialHarassment, isNotNull);
        expect(ModerationReason.credibleThreat, isNotNull);
        expect(ModerationReason.potentialHate, isNotNull);
        expect(ModerationReason.potentialSexualContent, isNotNull);
        expect(ModerationReason.sexualContentInvolvingMinors, isNotNull);
        expect(ModerationReason.potentialViolence, isNotNull);
        expect(ModerationReason.potentialSelfHarm, isNotNull);
        expect(ModerationReason.externalProviderUnavailable, isNotNull);
        expect(ModerationReason.communityReports, isNotNull);
      });
    });

    group('ModerationSource - Cobertura completa', () {
      test('debe tener todos los valores del enum disponibles', () {
        // Act & Assert - Verifica que todos los valores existen
        expect(ModerationSource.localRules, isNotNull);
        expect(ModerationSource.externalProvider, isNotNull);
        expect(ModerationSource.communityReports, isNotNull);
        expect(ModerationSource.humanReview, isNotNull);
      });
    });

    group('ModerationVerdict - Cobertura completa', () {
      test('debe tener todos los valores del enum disponibles', () {
        // Act & Assert - Verifica que todos los valores existen
        expect(ModerationVerdict.publish, isNotNull);
        expect(ModerationVerdict.review, isNotNull);
        expect(ModerationVerdict.reject, isNotNull);
      });
    });
  });
}
