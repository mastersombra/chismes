import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/domain/services/gossip_state_machine.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/domain/entities/moderation_decision.dart';

void main() {
  group('GossipStateMachine.isValidCombination', () {
    test('debe aceptar draft + pending (chisme creado, motor revisando)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.draft,
        ModerationStatus.pending,
      );
      expect(result, isTrue);
    });

    test('debe aceptar draft + rejected (motor detectó problema)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.draft,
        ModerationStatus.rejected,
      );
      expect(result, isTrue);
    });

    test('debe aceptar published + approved (publicado y aprobado)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.published,
        ModerationStatus.approved,
      );
      expect(result, isTrue);
    });

    test('debe aceptar hidden + flagged (reportado, oculto para corrección)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.hidden,
        ModerationStatus.flagged,
      );
      expect(result, isTrue);
    });

    test('debe aceptar hidden + rejected (rechazado por moderación)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.hidden,
        ModerationStatus.rejected,
      );
      expect(result, isTrue);
    });

    test('debe aceptar deleted con cualquier moderationStatus', () {
      expect(
        GossipStateMachine.isValidCombination(
          GossipStatus.deleted,
          ModerationStatus.pending,
        ),
        isTrue,
      );
      expect(
        GossipStateMachine.isValidCombination(
          GossipStatus.deleted,
          ModerationStatus.approved,
        ),
        isTrue,
      );
      expect(
        GossipStateMachine.isValidCombination(
          GossipStatus.deleted,
          ModerationStatus.rejected,
        ),
        isTrue,
      );
      expect(
        GossipStateMachine.isValidCombination(
          GossipStatus.deleted,
          ModerationStatus.flagged,
        ),
        isTrue,
      );
    });

    test('debe rechazar published + pending (combinación ambigua)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.published,
        ModerationStatus.pending,
      );
      expect(result, isFalse);
    });

    test('debe rechazar published + rejected (incoherente)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.published,
        ModerationStatus.rejected,
      );
      expect(result, isFalse);
    });

    test('debe rechazar published + flagged (incoherente)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.published,
        ModerationStatus.flagged,
      );
      expect(result, isFalse);
    });

    test('debe rechazar draft + approved (incoherente)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.draft,
        ModerationStatus.approved,
      );
      expect(result, isFalse);
    });

    test('debe rechazar draft + flagged (incoherente)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.draft,
        ModerationStatus.flagged,
      );
      expect(result, isFalse);
    });

    test('debe rechazar hidden + pending (incoherente)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.hidden,
        ModerationStatus.pending,
      );
      expect(result, isFalse);
    });

    test('debe rechazar hidden + approved (incoherente)', () {
      final result = GossipStateMachine.isValidCombination(
        GossipStatus.hidden,
        ModerationStatus.approved,
      );
      expect(result, isFalse);
    });
  });

  group('GossipStateMachine.shouldTriggerModerationReview', () {
    test('debe retornar true cuando reportedCount >= 3', () {
      final result = GossipStateMachine.shouldTriggerModerationReview(
        reportedCount: 3,
        viewCount: 100,
        reportCategory: null,
      );
      expect(result, isTrue);
    });

    test('debe retornar true cuando ratio reports/views > 5%', () {
      final result = GossipStateMachine.shouldTriggerModerationReview(
        reportedCount: 6,
        viewCount: 100, // 6/100 = 6% > 5%
        reportCategory: null,
      );
      expect(result, isTrue);
    });

    test('debe retornar true cuando reportedCount >= 3 incluso si ratio es exactamente 5%', () {
      final result = GossipStateMachine.shouldTriggerModerationReview(
        reportedCount: 5, // >= 3, triggerea revisión
        viewCount: 100, // 5/100 = 5% (no > 5%, pero reportedCount >= 3)
        reportCategory: null,
      );
      expect(result, isTrue); // true porque reportedCount >= 3
    });

    test('debe retornar false cuando ratio es bajo y reportedCount < 3', () {
      final result = GossipStateMachine.shouldTriggerModerationReview(
        reportedCount: 2, // < 3
        viewCount: 100, // 2/100 = 2% (no > 5%)
        reportCategory: null,
      );
      expect(result, isFalse);
    });

    test('debe retornar true para categoría severa (credibleThreat)', () {
      final result = GossipStateMachine.shouldTriggerModerationReview(
        reportedCount: 1,
        viewCount: 100,
        reportCategory: ModerationReason.credibleThreat,
      );
      expect(result, isTrue);
    });

    test('debe retornar true para categoría severa (sexualContentInvolvingMinors)', () {
      final result = GossipStateMachine.shouldTriggerModerationReview(
        reportedCount: 1,
        viewCount: 100,
        reportCategory: ModerationReason.sexualContentInvolvingMinors,
      );
      expect(result, isTrue);
    });

    test('debe retornar true para categoría severa (potentialSelfHarm)', () {
      final result = GossipStateMachine.shouldTriggerModerationReview(
        reportedCount: 1,
        viewCount: 100,
        reportCategory: ModerationReason.potentialSelfHarm,
      );
      expect(result, isTrue);
    });

    test('debe retornar false para categoría menor sin suficientes reportes', () {
      final result = GossipStateMachine.shouldTriggerModerationReview(
        reportedCount: 1,
        viewCount: 100,
        reportCategory: ModerationReason.potentialProfanity,
      );
      expect(result, isFalse);
    });

    test('debe manejar viewCount = 0 sin división por cero', () {
      final result = GossipStateMachine.shouldTriggerModerationReview(
        reportedCount: 2,
        viewCount: 0,
        reportCategory: null,
      );
      expect(result, isFalse);
    });
  });

  group('GossipStateMachine.isSevereCategory', () {
    test('debe retornar true para credibleThreat', () {
      expect(
        GossipStateMachine.isSevereCategory(ModerationReason.credibleThreat),
        isTrue,
      );
    });

    test('debe retornar true para sexualContentInvolvingMinors', () {
      expect(
        GossipStateMachine.isSevereCategory(
          ModerationReason.sexualContentInvolvingMinors,
        ),
        isTrue,
      );
    });

    test('debe retornar true para potentialSelfHarm', () {
      expect(
        GossipStateMachine.isSevereCategory(ModerationReason.potentialSelfHarm),
        isTrue,
      );
    });

    test('debe retornar false para categorías menores', () {
      expect(
        GossipStateMachine.isSevereCategory(ModerationReason.potentialProfanity),
        isFalse,
      );
      expect(
        GossipStateMachine.isSevereCategory(ModerationReason.potentialHarassment),
        isFalse,
      );
      expect(
        GossipStateMachine.isSevereCategory(ModerationReason.potentialSpam),
        isFalse,
      );
    });
  });

  group('GossipStateMachine.isMinorCategory', () {
    test('debe retornar true para potentialProfanity', () {
      expect(
        GossipStateMachine.isMinorCategory(ModerationReason.potentialProfanity),
        isTrue,
      );
    });

    test('debe retornar true para potentialHarassment', () {
      expect(
        GossipStateMachine.isMinorCategory(ModerationReason.potentialHarassment),
        isTrue,
      );
    });

    test('debe retornar true para potentialSpam', () {
      expect(
        GossipStateMachine.isMinorCategory(ModerationReason.potentialSpam),
        isTrue,
      );
    });

    test('debe retornar true para potentialHate', () {
      expect(
        GossipStateMachine.isMinorCategory(ModerationReason.potentialHate),
        isTrue,
      );
    });

    test('debe retornar true para potentialSexualContent', () {
      expect(
        GossipStateMachine.isMinorCategory(ModerationReason.potentialSexualContent),
        isTrue,
      );
    });

    test('debe retornar true para potentialViolence', () {
      expect(
        GossipStateMachine.isMinorCategory(ModerationReason.potentialViolence),
        isTrue,
      );
    });

    test('debe retornar false para categorías severas', () {
      expect(
        GossipStateMachine.isMinorCategory(ModerationReason.credibleThreat),
        isFalse,
      );
      expect(
        GossipStateMachine.isMinorCategory(
          ModerationReason.sexualContentInvolvingMinors,
        ),
        isFalse,
      );
      expect(
        GossipStateMachine.isMinorCategory(ModerationReason.potentialSelfHarm),
        isFalse,
      );
    });
  });

  group('GossipStateMachine.isValidTransition', () {
    group('Flujo de creación', () {
      test('debe permitir transición: (draft, pending) → (published, approved) - motor aprueba', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.draft,
          ModerationStatus.pending,
          GossipStatus.published,
          ModerationStatus.approved,
        );
        expect(result, isTrue);
      });

      test('debe permitir transición: (draft, pending) → (draft, rejected) - motor rechaza', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.draft,
          ModerationStatus.pending,
          GossipStatus.draft,
          ModerationStatus.rejected,
        );
        expect(result, isTrue);
      });
    });

    group('Flujo de corrección', () {
      test('debe permitir transición: (draft, rejected) → (draft, pending) - usuario corrige', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.draft,
          ModerationStatus.rejected,
          GossipStatus.draft,
          ModerationStatus.pending,
        );
        expect(result, isTrue);
      });
    });

    group('Flujo de reportes', () {
      test('debe permitir transición: (published, approved) → (hidden, flagged) - usuarios reportan', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.published,
          ModerationStatus.approved,
          GossipStatus.hidden,
          ModerationStatus.flagged,
        );
        expect(result, isTrue);
      });

      test('debe permitir transición: (hidden, flagged) → (published, approved) - reporte falso', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.hidden,
          ModerationStatus.flagged,
          GossipStatus.published,
          ModerationStatus.approved,
        );
        expect(result, isTrue);
      });

      test('debe permitir transición: (hidden, flagged) → (draft, rejected) - problema menor', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.hidden,
          ModerationStatus.flagged,
          GossipStatus.draft,
          ModerationStatus.rejected,
        );
        expect(result, isTrue);
      });

      test('debe permitir transición: (hidden, flagged) → (deleted, flagged) - problema severo', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.hidden,
          ModerationStatus.flagged,
          GossipStatus.deleted,
          ModerationStatus.flagged,
        );
        expect(result, isTrue);
      });

      test('debe permitir transición: (hidden, flagged) → (hidden, rejected) - rechazo manual', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.hidden,
          ModerationStatus.flagged,
          GossipStatus.hidden,
          ModerationStatus.rejected,
        );
        expect(result, isTrue);
      });
    });

    group('Soft delete', () {
      test('debe permitir soft delete desde (draft, pending)', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.draft,
          ModerationStatus.pending,
          GossipStatus.deleted,
          ModerationStatus.pending,
        );
        expect(result, isTrue);
      });

      test('debe permitir soft delete desde (draft, rejected)', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.draft,
          ModerationStatus.rejected,
          GossipStatus.deleted,
          ModerationStatus.rejected,
        );
        expect(result, isTrue);
      });

      test('debe permitir soft delete desde (published, approved)', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.published,
          ModerationStatus.approved,
          GossipStatus.deleted,
          ModerationStatus.approved,
        );
        expect(result, isTrue);
      });

      test('debe permitir soft delete desde (hidden, flagged)', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.hidden,
          ModerationStatus.flagged,
          GossipStatus.deleted,
          ModerationStatus.flagged,
        );
        expect(result, isTrue);
      });

      test('debe permitir soft delete desde (hidden, rejected)', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.hidden,
          ModerationStatus.rejected,
          GossipStatus.deleted,
          ModerationStatus.rejected,
        );
        expect(result, isTrue);
      });

      test('NO debe permitir soft delete si cambia moderationStatus', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.published,
          ModerationStatus.approved,
          GossipStatus.deleted,
          ModerationStatus.rejected, // Cambió moderationStatus
        );
        expect(result, isFalse);
      });
    });

    group('Transiciones inválidas', () {
      test('debe rechazar transición sin cambio de estado', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.published,
          ModerationStatus.approved,
          GossipStatus.published,
          ModerationStatus.approved,
        );
        expect(result, isFalse);
      });

      test('debe rechazar transición desde estado inválido', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.published, // Estado inicial inválido
          ModerationStatus.rejected, // (published + rejected es inválido)
          GossipStatus.hidden,
          ModerationStatus.flagged,
        );
        expect(result, isFalse);
      });

      test('debe rechazar transición hacia estado inválido', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.published,
          ModerationStatus.approved,
          GossipStatus.published, // Estado final inválido
          ModerationStatus.rejected, // (published + rejected es inválido)
        );
        expect(result, isFalse);
      });

      test('debe rechazar transición no documentada: (published, approved) → (draft, pending)', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.published,
          ModerationStatus.approved,
          GossipStatus.draft,
          ModerationStatus.pending,
        );
        expect(result, isFalse);
      });

      test('debe rechazar transición no documentada: (draft, rejected) → (published, approved)', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.draft,
          ModerationStatus.rejected,
          GossipStatus.published,
          ModerationStatus.approved,
        );
        expect(result, isFalse);
      });

      test('debe rechazar transición no documentada: (hidden, rejected) → (published, approved)', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.hidden,
          ModerationStatus.rejected,
          GossipStatus.published,
          ModerationStatus.approved,
        );
        expect(result, isFalse);
      });

      test('debe rechazar salto de estado: (draft, pending) → (hidden, flagged)', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.draft,
          ModerationStatus.pending,
          GossipStatus.hidden,
          ModerationStatus.flagged,
        );
        expect(result, isFalse);
      });

      test('debe rechazar transición desde deleted (soft delete es permanente)', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.deleted,
          ModerationStatus.approved,
          GossipStatus.published,
          ModerationStatus.approved,
        );
        expect(result, isFalse);
      });
    });

    group('Edge cases', () {
      test('debe rechazar cambio solo de moderationStatus sin cambio de GossipStatus', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.draft,
          ModerationStatus.pending,
          GossipStatus.draft,
          ModerationStatus.approved, // Solo cambia moderationStatus
        );
        expect(result, isFalse);
      });

      test('debe rechazar cambio solo de GossipStatus sin cambio de moderationStatus', () {
        final result = GossipStateMachine.isValidTransition(
          GossipStatus.draft,
          ModerationStatus.pending,
          GossipStatus.published, // Solo cambia GossipStatus
          ModerationStatus.pending,
        );
        expect(result, isFalse);
      });
    });
  });
}
