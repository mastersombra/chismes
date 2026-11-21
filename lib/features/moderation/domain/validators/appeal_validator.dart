import '../../../../core/error/error_codes.dart';
import '../../../../core/error/failure.dart';
import '../entities/moderation_appeal.dart';

/// Reglas de apelaciones (mismos límites que `015_sanctions.sql`)
class AppealValidator {
  AppealValidator._();

  /// `moderation_appeals.message`: 10–1000 sin espacios de los bordes
  static const int minMessageLength = 10;
  static const int maxMessageLength = 1000;

  /// `moderation_appeals.decision_note` (<= 1000)
  static const int maxNoteLength = 1000;

  static ValidationFailure? validateSubmission({
    required String queueId,
    required String message,
  }) {
    if (queueId.trim().isEmpty) {
      return const ValidationFailure(
        code: ErrorCode.missingRequiredField,
        technicalMessage: 'queueId is required',
        fieldErrors: {'queueId': 'required'},
      );
    }
    final length = message.trim().length;
    if (length < minMessageLength) {
      return const ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: 'appeal message shorter than $minMessageLength chars',
        fieldErrors: {'message': 'too_short'},
      );
    }
    if (length > maxMessageLength) {
      return const ValidationFailure(
        code: ErrorCode.invalidInput,
        technicalMessage: 'appeal message exceeds $maxMessageLength chars',
        fieldErrors: {'message': 'too_long'},
      );
    }
    return null;
  }

  static ValidationFailure? validateDecision(AppealDecision decision) {
    if (decision.appealId.trim().isEmpty) {
      return const ValidationFailure(
        code: ErrorCode.missingRequiredField,
        technicalMessage: 'appealId is required',
        fieldErrors: {'appealId': 'required'},
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
