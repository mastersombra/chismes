import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:chismes/features/moderation/domain/entities/review_decision.dart';
import 'package:chismes/features/moderation/domain/validators/review_decision_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aprobar válido', () {
    expect(ReviewDecisionValidator.validate(const ReviewDecision.approve(queueId: 'q-1')), isNull);
  });

  test('rechazar con gravedad y nota en el límite es válido', () {
    final decision = ReviewDecision.reject(
      queueId: 'q-1',
      severity: ModerationSeverity.low,
      note: 'a' * ReviewDecisionValidator.maxNoteLength,
    );
    expect(ReviewDecisionValidator.validate(decision), isNull);
  });

  test('sin queueId → missingRequiredField', () {
    final failure = ReviewDecisionValidator.validate(const ReviewDecision.approve(queueId: '  '));
    expect(failure?.code, ErrorCode.missingRequiredField);
    expect(failure?.fieldErrors, {'queueId': 'required'});
  });

  test('nota demasiado larga → invalidInput', () {
    final failure = ReviewDecisionValidator.validate(ReviewDecision.approve(
      queueId: 'q-1',
      note: 'a' * (ReviewDecisionValidator.maxNoteLength + 1),
    ));
    expect(failure?.code, ErrorCode.invalidInput);
    expect(failure?.fieldErrors, {'note': 'too_long'});
  });
}
