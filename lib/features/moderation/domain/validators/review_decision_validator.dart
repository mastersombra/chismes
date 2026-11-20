import '../../../../core/error/error_codes.dart';
import '../../../../core/error/failure.dart';
import '../entities/review_decision.dart';

/// Reglas de una decisión (mismos límites que `moderation-review`).
///
/// La gravedad obligatoria al rechazar la garantiza el tipo
/// (`ReviewDecision.reject` la exige).
class ReviewDecisionValidator {
  ReviewDecisionValidator._();

  /// `moderation_queue.decision_note` (CHECK <= 1000)
  static const int maxNoteLength = 1000;

  static ValidationFailure? validate(ReviewDecision decision) {
    if (decision.queueId.trim().isEmpty) {
      return const ValidationFailure(
        code: ErrorCode.missingRequiredField,
        technicalMessage: 'queueId is required',
        fieldErrors: {'queueId': 'required'},
      );
    }
    final note = decision.note?.trim();
    if (note != null && note.length > maxNoteLength) {
      return const ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: 'note exceeds $maxNoteLength chars',
        fieldErrors: {'note': 'too_long'},
      );
    }
    return null;
  }
}
