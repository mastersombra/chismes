import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/moderation/data/datasources/moderation_remote_data_source.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:chismes/features/moderation/domain/entities/review_decision.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../moderation_fixtures.dart';
import 'moderation_remote_data_source_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SupabaseClient>(),
  MockSpec<GoTrueClient>(),
  MockSpec<Session>(),
  MockSpec<FunctionsClient>(),
  MockSpec<AppLogger>(),
])
void main() {
  late MockSupabaseClient supabase;
  late MockGoTrueClient auth;
  late MockSession session;
  late MockFunctionsClient functions;
  late ModerationRemoteDataSource dataSource;

  setUp(() {
    supabase = MockSupabaseClient();
    auth = MockGoTrueClient();
    session = MockSession();
    functions = MockFunctionsClient();
    when(supabase.auth).thenReturn(auth);
    when(supabase.functions).thenReturn(functions);
    when(auth.currentSession).thenReturn(session);
    when(session.accessToken).thenReturn('jwt');
    dataSource = ModerationRemoteDataSource(supabase, MockAppLogger());
  });

  void respond(FunctionResponse response) {
    when(functions.invoke(any, body: anyNamed('body'), headers: anyNamed('headers')))
        .thenAnswer((_) async => response);
  }

  void throwStatus(int status) {
    when(functions.invoke(any, body: anyNamed('body'), headers: anyNamed('headers')))
        .thenThrow(FunctionException(status: status, details: {'error': 'x'}));
  }

  group('getQueue', () {
    test('envía list con status/limit/offset y el JWT, y parsea los ítems', () async {
      respond(FunctionResponse(status: 200, data: {
        'items': [queueItemJson(), queueItemJson(id: 'q-2')],
      }));

      final items = await dataSource.getQueue(status: 'pending', limit: 20, offset: 40);

      expect(items.map((i) => i.id), ['q-1', 'q-2']);
      expect(items.first.toEntity().status, ModerationQueueStatus.pending);
      verify(functions.invoke(
        'moderation-review',
        body: {'action': 'list', 'status': 'pending', 'limit': 20, 'offset': 40},
        headers: {'Authorization': 'Bearer jwt'},
      )).called(1);
    });

    test('respuesta sin items → ServerFailure', () async {
      respond(FunctionResponse(status: 200, data: {'otra': 1}));

      await expectLater(
        dataSource.getQueue(status: 'pending', limit: 20, offset: 0),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('sin sesión → AuthFailure sin llamar a la función', () async {
      when(auth.currentSession).thenReturn(null);

      await expectLater(
        dataSource.getQueue(status: 'pending', limit: 20, offset: 0),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', ErrorCode.unauthorized)),
      );
      verifyNever(functions.invoke(any, body: anyNamed('body'), headers: anyNamed('headers')));
    });

    final cases = <int, Matcher>{
      401: isA<AuthFailure>().having((f) => f.code, 'code', ErrorCode.unauthorized),
      403: isA<PermissionFailure>().having((f) => f.code, 'code', ErrorCode.forbidden),
      404: isA<DataFailure>().having((f) => f.code, 'code', ErrorCode.notFound),
      409: isA<DataFailure>().having((f) => f.code, 'code', ErrorCode.conflict),
      400: isA<ValidationFailure>().having((f) => f.code, 'code', ErrorCode.validationError),
      500: isA<ServerFailure>().having((f) => f.code, 'code', ErrorCode.serverError),
    };
    cases.forEach((status, matcher) {
      test('FunctionException $status → Failure correspondiente', () async {
        throwStatus(status);
        await expectLater(
          dataSource.getQueue(status: 'pending', limit: 20, offset: 0),
          throwsA(matcher),
        );
      });
    });

    test('respuesta no 2xx sin excepción también se mapea', () async {
      respond(FunctionResponse(status: 403, data: {'error': 'Forbidden'}));

      await expectLater(
        dataSource.getQueue(status: 'pending', limit: 20, offset: 0),
        throwsA(isA<PermissionFailure>()),
      );
    });
  });

  group('decide', () {
    setUp(() => respond(FunctionResponse(status: 200, data: {'ok': true})));

    test('aprobar: solo queue_id y decision', () async {
      await dataSource.decide(const ReviewDecision.approve(queueId: 'q-1', note: '   '));

      verify(functions.invoke(
        'moderation-review',
        body: {'action': 'decide', 'queue_id': 'q-1', 'decision': 'approve'},
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('rechazar: gravedad, motivo y nota recortada', () async {
      await dataSource.decide(const ReviewDecision.reject(
        queueId: 'q-1',
        severity: ModerationSeverity.critical,
        reason: RejectReason.personalData,
        note: '  publica el celular  ',
      ));

      verify(functions.invoke(
        'moderation-review',
        body: {
          'action': 'decide',
          'queue_id': 'q-1',
          'decision': 'reject',
          'severity': 'critical',
          'reason': 'personal_data',
          'note': 'publica el celular',
        },
        headers: anyNamed('headers'),
      )).called(1);
    });

    test('409 (ya decidido) → DataFailure conflict', () async {
      throwStatus(409);

      await expectLater(
        dataSource.decide(const ReviewDecision.approve(queueId: 'q-1')),
        throwsA(isA<DataFailure>().having((f) => f.code, 'code', ErrorCode.conflict)),
      );
    });
  });
}
