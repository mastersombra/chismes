import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/error_messages.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_l10n_helper.dart';

void main() {
  group('AccountRestrictedFailure.fromResponse', () {
    test('403 restricted con fecha', () {
      final f = AccountRestrictedFailure.fromResponse(403, {
        'code': 'account_restricted',
        'state': 'restricted',
        'restricted_until': '2026-11-22T10:00:00Z',
      });

      expect(f!.code, ErrorCode.accountRestricted);
      expect(f.restrictedUntil, DateTime.parse('2026-11-22T10:00:00Z'));
    });

    test('403 suspended sin fecha', () {
      final f = AccountRestrictedFailure.fromResponse(403, {
        'code': 'account_restricted',
        'state': 'suspended',
        'restricted_until': null,
      });

      expect(f!.code, ErrorCode.accountSuspended);
      expect(f.restrictedUntil, isNull);
    });

    test('fecha inválida → null sin romper', () {
      final f = AccountRestrictedFailure.fromResponse(403, {
        'code': 'account_restricted',
        'state': 'restricted',
        'restricted_until': 'mañana',
      });

      expect(f!.restrictedUntil, isNull);
    });

    test('no es cuenta restringida → null', () {
      expect(AccountRestrictedFailure.fromResponse(403, {'error': 'Forbidden'}), isNull);
      expect(AccountRestrictedFailure.fromResponse(400, {'code': 'account_restricted'}), isNull);
      expect(AccountRestrictedFailure.fromResponse(403, 'texto'), isNull);
      expect(AccountRestrictedFailure.fromResponse(403, null), isNull);
    });

    test('igualdad incluye la fecha', () {
      final until = DateTime.utc(2026, 11, 22);
      expect(
        AccountRestrictedFailure(code: ErrorCode.accountRestricted, restrictedUntil: until),
        AccountRestrictedFailure(code: ErrorCode.accountRestricted, restrictedUntil: until),
      );
      expect(
        AccountRestrictedFailure(code: ErrorCode.accountRestricted, restrictedUntil: until),
        isNot(const AccountRestrictedFailure(code: ErrorCode.accountRestricted)),
      );
    });
  });

  group('ErrorMessages (cuenta restringida)', () {
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    testWidgets('getMessage y getTitle de los códigos nuevos', (tester) async {
      await withL10nContext(tester, (context) {
        expect(ErrorMessages.getMessage(context, ErrorCode.accountRestricted), contains('Estado de la cuenta'));
        expect(ErrorMessages.getMessage(context, ErrorCode.accountSuspended), contains('suspendida'));
        expect(
          ErrorMessages.getTitle(context, ErrorCode.accountRestricted),
          ErrorMessages.getTitle(context, ErrorCode.rateLimitExceeded),
        );
        expect(
          ErrorMessages.getTitle(context, ErrorCode.accountSuspended),
          ErrorMessages.getTitle(context, ErrorCode.rateLimitExceeded),
        );
        return null;
      });
    });

    testWidgets('forFailure: restringida con fecha la incluye', (tester) async {
      await withL10nContext(tester, (context) {
        final message = ErrorMessages.forFailure(
          context,
          AccountRestrictedFailure(
            code: ErrorCode.accountRestricted,
            restrictedUntil: DateTime(2026, 11, 22, 10, 30),
          ),
        );
        expect(message, contains('hasta el'));
        expect(message, contains('22'));
        return null;
      });
    });

    testWidgets('forFailure: restringida sin fecha y suspendida → mensaje del código', (tester) async {
      await withL10nContext(tester, (context) {
        expect(
          ErrorMessages.forFailure(context, const AccountRestrictedFailure(code: ErrorCode.accountRestricted)),
          ErrorMessages.getMessage(context, ErrorCode.accountRestricted),
        );
        expect(
          ErrorMessages.forFailure(
            context,
            AccountRestrictedFailure(code: ErrorCode.accountSuspended, restrictedUntil: DateTime(2026)),
          ),
          ErrorMessages.getMessage(context, ErrorCode.accountSuspended),
        );
        return null;
      });
    });

    testWidgets('forFailure: mensajes del servidor y genérico', (tester) async {
      await withL10nContext(tester, (context) {
        expect(
          ErrorMessages.forFailure(
              context, const ServerFailure(code: ErrorCode.serverError, message: 'Del servidor')),
          'Del servidor',
        );
        expect(
          ErrorMessages.forFailure(
              context, const RateLimitFailure(code: ErrorCode.rateLimitExceeded, message: 'Espera 5 min')),
          'Espera 5 min',
        );
        expect(
          ErrorMessages.forFailure(context, const ServerFailure(code: ErrorCode.serverError)),
          ErrorMessages.getMessage(context, ErrorCode.serverError),
        );
        expect(
          ErrorMessages.forFailure(context, const RateLimitFailure(code: ErrorCode.rateLimitExceeded)),
          ErrorMessages.getMessage(context, ErrorCode.rateLimitExceeded),
        );
        expect(
          ErrorMessages.forFailure(context, const DataFailure(code: ErrorCode.notFound)),
          ErrorMessages.getMessage(context, ErrorCode.notFound),
        );
        return null;
      });
    });
  });
}
