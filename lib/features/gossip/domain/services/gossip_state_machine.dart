import '../entities/gossip.dart';
import '../entities/moderation_decision.dart';

class GossipStateMachine {
  GossipStateMachine._();

  static bool isValidCombination(GossipStatus status, ModerationStatus moderationStatus) {
    final validCombinations = {
      (GossipStatus.draft, ModerationStatus.pending),
      (GossipStatus.draft, ModerationStatus.rejected),
      (GossipStatus.published, ModerationStatus.approved),
      (GossipStatus.hidden, ModerationStatus.flagged),
      (GossipStatus.hidden, ModerationStatus.rejected),
    };

    if (status == GossipStatus.deleted) {
      return true;
    }

    return validCombinations.contains((status, moderationStatus));
  }

  /// Valida si una transición de estados es válida
  ///
  /// **Propósito:** Validar que las transiciones de estado cumplan con las reglas de negocio
  ///
  /// **Uso:** Backend/Cloud Functions para validar antes de escribir a Firestore
  ///
  /// **IMPORTANTE:** El cliente NO debe usar este método para cambiar estados.
  /// Solo el backend controla las transiciones de estado.
  ///
  /// **Transiciones válidas:**
  ///
  /// 1. **Flujo de creación:**
  ///    - (draft, pending) → (published, approved) // Motor automático aprueba
  ///    - (draft, pending) → (draft, rejected) // Motor automático rechaza
  ///
  /// 2. **Flujo de corrección:**
  ///    - (draft, rejected) → (draft, pending) // Usuario corrige y reenvía
  ///
  /// 3. **Flujo de reportes:**
  ///    - (published, approved) → (hidden, flagged) // Usuarios reportan (umbral alcanzado)
  ///    - (hidden, flagged) → (published, approved) // Moderador: reporte falso, restaurar
  ///    - (hidden, flagged) → (draft, rejected) // Moderador: problema menor, permite corrección
  ///    - (hidden, flagged) → (deleted, flagged) // Moderador: problema severo, eliminar
  ///    - (hidden, flagged) → (hidden, rejected) // Moderador: rechaza manualmente
  ///
  /// 4. **Soft delete:**
  ///    - (cualquier_estado_válido) → (deleted, mismo_moderationStatus) // Usuario elimina
  ///
  /// **Ejemplo:**
  /// ```dart
  /// // Backend Cloud Function
  /// final isValid = GossipStateMachine.isValidTransition(
  ///   GossipStatus.draft,
  ///   ModerationStatus.pending,
  ///   GossipStatus.published,
  ///   ModerationStatus.approved,
  /// ); // true - motor aprobó contenido
  /// ```
  static bool isValidTransition(
    GossipStatus fromStatus,
    ModerationStatus fromModeration,
    GossipStatus toStatus,
    ModerationStatus toModeration,
  ) {
    // Validar que el estado inicial es válido
    if (!isValidCombination(fromStatus, fromModeration)) {
      return false;
    }

    // Validar que el estado final es válido
    if (!isValidCombination(toStatus, toModeration)) {
      return false;
    }

    // No hay transición (mismo estado)
    if (fromStatus == toStatus && fromModeration == toModeration) {
      return false;
    }

    // Transiciones válidas como set de tuples: (from, to)
    final validTransitions = {
      // 1. Flujo de creación
      (
        (GossipStatus.draft, ModerationStatus.pending),
        (GossipStatus.published, ModerationStatus.approved),
      ),
      (
        (GossipStatus.draft, ModerationStatus.pending),
        (GossipStatus.draft, ModerationStatus.rejected),
      ),

      // 2. Flujo de corrección
      (
        (GossipStatus.draft, ModerationStatus.rejected),
        (GossipStatus.draft, ModerationStatus.pending),
      ),

      // 3. Flujo de reportes
      (
        (GossipStatus.published, ModerationStatus.approved),
        (GossipStatus.hidden, ModerationStatus.flagged),
      ),
      (
        (GossipStatus.hidden, ModerationStatus.flagged),
        (GossipStatus.published, ModerationStatus.approved),
      ),
      (
        (GossipStatus.hidden, ModerationStatus.flagged),
        (GossipStatus.draft, ModerationStatus.rejected),
      ),
      (
        (GossipStatus.hidden, ModerationStatus.flagged),
        (GossipStatus.deleted, ModerationStatus.flagged),
      ),
      (
        (GossipStatus.hidden, ModerationStatus.flagged),
        (GossipStatus.hidden, ModerationStatus.rejected),
      ),
    };

    final transition = (
      (fromStatus, fromModeration),
      (toStatus, toModeration),
    );

    // Si es una transición explícita válida
    if (validTransitions.contains(transition)) {
      return true;
    }

    // 4. Soft delete: desde cualquier estado válido a deleted (mantiene moderationStatus)
    if (toStatus == GossipStatus.deleted && toModeration == fromModeration) {
      return true;
    }

    return false;
  }

  static bool shouldTriggerModerationReview({
    required int reportedCount,
    required int viewCount,
    required ModerationReason? reportCategory,
  }) {
    final hasEnoughReports = reportedCount >= 3;
    final hasHighRatio = viewCount > 0 && (reportedCount / viewCount) > 0.05;
    final isSevereCategory = _isSevereCategory(reportCategory);

    return hasEnoughReports || hasHighRatio || isSevereCategory;
  }

  static bool isSevereCategory(ModerationReason category) {
    return _isSevereCategory(category);
  }

  static bool _isSevereCategory(ModerationReason? category) {
    if (category == null) return false;

    const severeCategories = {
      ModerationReason.credibleThreat,
      ModerationReason.sexualContentInvolvingMinors,
      ModerationReason.potentialSelfHarm,
    };

    return severeCategories.contains(category);
  }

  static bool isMinorCategory(ModerationReason category) {
    const minorCategories = {
      ModerationReason.potentialProfanity,
      ModerationReason.potentialHarassment,
      ModerationReason.potentialSpam,
      ModerationReason.potentialHate,
      ModerationReason.potentialSexualContent,
      ModerationReason.potentialViolence,
    };

    return minorCategories.contains(category);
  }
}
