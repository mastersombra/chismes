import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/features/moderation/data/datasources/account_status_remote_data_source.dart';
import 'package:chismes/features/moderation/domain/entities/account_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../sanctions_json_fixtures.dart';
import 'moderation_remote_data_source_test.mocks.dart';

void main() {
  late MockSupabaseClient supabase;
  late MockGoTrueClient auth;
  late MockSession session;
  late MockFunctionsClient functions;
  late AccountStatusRemoteDataSource dataSource;

  setUp(() {
    supabase = MockSupabaseClient();
    auth = MockGoTrueClient();
    session = MockSession();
    functions = MockFunctionsClient();
    when(supabase.auth).thenReturn(auth);
    when(supabase.functions).thenReturn(functions);
    when(auth.currentSession).thenReturn(session);
    when(session.accessToken).thenReturn('jwt');
    dataSource = AccountStatusRemoteDataSource(supabase, MockAppLogger());
  });

  void respond(FunctionResponse response) {
    when(functions.invoke(any, body: anyNamed('body'), headers: anyNamed('headers')))
        .thenAnswer((_) async => response);
  }

  void throwStatus(int status) {
    when(functions.invoke(any, body: anyNamed('body'), headers: anyNamed('headers')))
        .thenThrow(FunctionException(status: status, details: {'error': 'x'}));
  }

  group('getStatus', () {
    test('envía action status con el JWT y parsea el estado', () async {
      respond(FunctionResponse(status: 200, data: {'status': accountStatusJson()}));

      final status = await dataSource.getStatus();

      expect(status.state, AccountState.restricted);
      expect(status.rejections.single.queueId, 'q-1');
      verify(functions.invoke(
        'account-status',
        body: {'action': 'status'},
        headers: {'Authorization': 'Bearer jwt'},
      )).called(1);
    });

    test('respuesta sin status → ServerFailure', () async {
      respond(FunctionResponse(status: 200, data: {'otra': 1}));

      await expectLater(dataSource.getStatus(), throwsA(isA<ServerFailure>()));
    });

    test('sin sesión → AuthFailure sin llamar a la función', () async {
      when(auth.currentSession).thenReturn(null);

      await expectLater(
        dataSource.getStatus(),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', ErrorCode.unauthorized)),
      );
      verifyNever(functions.invoke(any, body: anyNamed('body'), headers: anyNamed('headers')));
    });

    test('status no 2xx sin excepción también se mapea', () async {
      respond(FunctionResponse(status: 404, data: {'error': 'x'}));

      await expectLater(
        dataSource.getStatus(),
        throwsA(isA<DataFailure>().having((f) => f.code, 'code', ErrorCode.notFound)),
      );
    });
  });

  group('submitAppeal', () {
    test('envía appeal con queue_id y mensaje y parsea la apelación', () async {
      respond(FunctionResponse(status: 201, data: {'appeal': appealJson()}));

      final appeal = await dataSource.submitAppeal(queueId: 'q-1', message: 'No era un insulto');

      expect(appeal.id, 'ap-1');
      expect(appeal.status, AppealStatus.pending);
      verify(functions.invoke(
        'account-status',
        body: {'action': 'appeal', 'queue_id': 'q-1', 'message': 'No era un insulto'},
        headers: {'Authorization': 'Bearer jwt'},
      )).called(1);
    });

    test('respuesta sin appeal → ServerFailure', () async {
      respond(FunctionResponse(status: 201, data: <String, dynamic>{}));

      await expectLater(
        dataSource.submitAppeal(queueId: 'q-1', message: 'mensaje largo'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('errores HTTP (FunctionException)', () {
    final cases = <int, Matcher>{
      401: isA<AuthFailure>().having((f) => f.code, 'code', ErrorCode.unauthorized),
      404: isA<DataFailure>().having((f) => f.code, 'code', ErrorCode.notFound),
      409: isA<DataFailure>().having((f) => f.code, 'code', ErrorCode.conflict),
      400: isA<ValidationFailure>().having((f) => f.code, 'code', ErrorCode.validationError),
      500: isA<ServerFailure>().having((f) => f.code, 'code', ErrorCode.serverError),
    };
    cases.forEach((status, matcher) {
      test('$status → Failure tipado', () async {
        throwStatus(status);

        await expectLater(
          dataSource.submitAppeal(queueId: 'q-1', message: 'mensaje largo'),
          throwsA(matcher),
        );
      });
    });
  });
}
