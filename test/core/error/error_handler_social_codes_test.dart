import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/error_handler.dart';
import 'package:chismes/core/error/error_messages.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../helpers/test_l10n_helper.dart';

/// SQLSTATE propios de las funciones sociales (migración 018)
void main() {
  group('ErrorHandler - SQLSTATE sociales', () {
    test('CS404 (usuario no disponible) → DataFailure(userNotAvailable)', () {
      final failure = ErrorHandler.handleError(
        const supabase.PostgrestException(message: 'user_not_available', code: 'CS404'),
      );

      expect(failure, isA<DataFailure>());
      expect(failure.code, ErrorCode.userNotAvailable);
      expect(failure.technicalMessage, 'user_not_available');
    });

    test('CS400 (consigo mismo) → ValidationFailure(invalidInput)', () {
      final failure = ErrorHandler.handleError(
        const supabase.PostgrestException(message: 'cannot_follow_self', code: 'CS400'),
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.code, ErrorCode.invalidInput);
    });

    test('CS401 (sin sesión) → AuthFailure(userNotAuthenticated)', () {
      final failure = ErrorHandler.handleError(
        const supabase.PostgrestException(message: 'not_authenticated', code: 'CS401'),
      );

      expect(failure, isA<AuthFailure>());
      expect(failure.code, ErrorCode.userNotAuthenticated);
    });

    test('CS429 (límite de seguir) → RateLimitFailure(followRateLimited) con el DETAIL', () {
      final failure = ErrorHandler.handleError(
        const supabase.PostgrestException(
          message: 'follow_rate_limited',
          code: 'CS429',
          details: 'hourly',
        ),
      );

      expect(failure, isA<RateLimitFailure>());
      expect(failure.code, ErrorCode.followRateLimited);
      expect(failure.technicalMessage, contains('hourly'));
    });
  });

  testWidgets('CS429 muestra el mensaje amigable de seguir muy rápido', (tester) async {
    final failure = ErrorHandler.handleError(
      const supabase.PostgrestException(message: 'follow_rate_limited', code: 'CS429'),
    );

    final message = await withL10nContext(
      tester,
      (context) => ErrorMessages.forFailure(context, failure),
    );

    expect(message, 'Estás siguiendo a muchas personas muy rápido. Intenta más tarde.');
  });
}
