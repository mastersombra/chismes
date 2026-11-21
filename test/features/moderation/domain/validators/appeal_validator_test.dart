import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_appeal.dart';
import 'package:chismes/features/moderation/domain/validators/appeal_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppealValidator.validateSubmission', () {
    test('mensaje válido (recortado) → null', () {
      expect(
        AppealValidator.validateSubmission(queueId: 'q-1', message: '   No era un insulto   '),
        isNull,
      );
    });

    test('sin queueId → missingRequiredField', () {
      final f = AppealValidator.validateSubmission(queueId: '  ', message: 'mensaje suficiente');
      expect(f!.code, ErrorCode.missingRequiredField);
      expect(f.fieldErrors, {'queueId': 'required'});
    });

    test('corto (contando sin espacios de los bordes) → too_short', () {
      final f = AppealValidator.validateSubmission(queueId: 'q-1', message: '   corto    ');
      expect(f!.code, ErrorCode.invalidInput);
      expect(f.fieldErrors, {'message': 'too_short'});
    });

    test('límites exactos: 10 y 1000 válidos; 1001 → too_long', () {
      expect(AppealValidator.validateSubmission(queueId: 'q', message: 'a' * 10), isNull);
      expect(AppealValidator.validateSubmission(queueId: 'q', message: 'a' * 1000), isNull);
      final f = AppealValidator.validateSubmission(queueId: 'q', message: 'a' * 1001);
      expect(f!.fieldErrors, {'message': 'too_long'});
    });
  });

  group('AppealValidator.validateDecision', () {
    test('válida con y sin nota', () {
      expect(AppealValidator.validateDecision(const AppealDecision(appealId: 'a', accept: true)), isNull);
      expect(
        AppealValidator.validateDecision(AppealDecision(appealId: 'a', accept: false, note: 'x' * 1000)),
        isNull,
      );
    });

    test('sin appealId → missingRequiredField', () {
      final f = AppealValidator.validateDecision(const AppealDecision(appealId: ' ', accept: true));
      expect(f!.code, ErrorCode.missingRequiredField);
      expect(f.fieldErrors, {'appealId': 'required'});
    });

    test('nota > 1000 → too_long', () {
      final f = AppealValidator.validateDecision(AppealDecision(appealId: 'a', accept: true, note: 'x' * 1001));
      expect(f!.code, ErrorCode.invalidInput);
      expect(f.fieldErrors, {'note': 'too_long'});
    });
  });
}
