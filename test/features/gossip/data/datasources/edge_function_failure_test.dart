import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/features/gossip/data/datasources/supabase_gossip_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mapeo de respuestas no 2xx de moderate-gossip / report-gossip
void main() {
  Failure? map(int status, dynamic data) => SupabaseGossipRemoteDataSource.edgeFunctionFailure(status, data);

  test('403 account_restricted → AccountRestrictedFailure', () {
    final f = map(403, {
      'code': 'account_restricted',
      'state': 'restricted',
      'restricted_until': '2026-11-22T10:00:00Z',
    });

    expect(f, isA<AccountRestrictedFailure>());
    expect(f!.code, ErrorCode.accountRestricted);
  });

  test('403 suspended → accountSuspended', () {
    final f = map(403, {'code': 'account_restricted', 'state': 'suspended'});
    expect(f!.code, ErrorCode.accountSuspended);
  });

  test('401 → AuthFailure unauthorized (con o sin cuerpo)', () {
    expect(map(401, {'error': 'Authentication required', 'message': 'login'}),
        isA<AuthFailure>().having((f) => f.code, 'code', ErrorCode.unauthorized));
    expect(map(401, null), isA<AuthFailure>());
  });

  test('429 → RateLimitFailure con mensaje y retryAfter', () {
    final f = map(429, {'error': 'Rate limit exceeded', 'message': 'Espera 30 s', 'retryAfter': 30});

    expect(f, isA<RateLimitFailure>());
    final rate = f! as RateLimitFailure;
    expect(rate.code, ErrorCode.rateLimitExceeded);
    expect(rate.message, 'Espera 30 s');
    expect(rate.retryAfter, 30);
  });

  test('429 sin cuerpo → RateLimitFailure sin mensaje', () {
    final f = map(429, 'texto') as RateLimitFailure;
    expect(f.message, isNull);
    expect(f.retryAfter, isNull);
  });

  test('contenido rechazado → moderationRejected', () {
    final f = map(400, {'error': 'Content rejected by moderation', 'reasons': ['threat']});
    expect(f, isA<ValidationFailure>().having((f) => f.code, 'code', ErrorCode.moderationRejected));
    expect(f!.technicalMessage, contains('threat'));
  });

  test('imagen falló → mediaUploadFailed', () {
    final f = map(400, {'error': 'Image upload failed', 'message': 'muy grande'});
    expect(f, isA<ValidationFailure>().having((f) => f.code, 'code', ErrorCode.mediaUploadFailed));
    expect(f!.technicalMessage, 'muy grande');
  });

  test('otros → null (el llamador usa el genérico)', () {
    expect(map(400, {'error': 'Validation failed'}), isNull);
    expect(map(403, {'error': 'Forbidden'}), isNull);
    expect(map(500, null), isNull);
    expect(map(503, 'down'), isNull);
  });
}
