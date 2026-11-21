import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/features/moderation/data/datasources/moderation_remote_data_source.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_appeal.dart';
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

  group('getAppeals', () {
    test('envía list_appeals con status/limit/offset y parsea', () async {
      respond(FunctionResponse(status: 200, data: {
        'items': [moderationAppealJson(), moderationAppealJson(id: 'ap-2')],
      }));

      final items = await dataSource.getAppeals(status: 'pending', limit: 20, offset: 20);

      expect(items.map((a) => a.id), ['ap-1', 'ap-2']);
      verify(functions.invoke(
        'moderation-review',
        body: {'action': 'list_appeals', 'status': 'pending', 'limit': 20, 'offset': 20},
        headers: {'Authorization': 'Bearer jwt'},
      )).called(1);
    });

    test('sin items → ServerFailure', () async {
      respond(FunctionResponse(status: 200, data: <String, dynamic>{}));

      await expectLater(
        dataSource.getAppeals(status: 'pending', limit: 20, offset: 0),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('decideAppeal', () {
    test('aceptar con nota recortada', () async {
      respond(FunctionResponse(status: 200, data: {'appeal': {}}));

      await dataSource.decideAppeal(const AppealDecision(appealId: 'ap-1', accept: true, note: '  ok  '));

      verify(functions.invoke(
        'moderation-review',
        body: {'action': 'decide_appeal', 'appeal_id': 'ap-1', 'decision': 'accept', 'note': 'ok'},
        headers: {'Authorization': 'Bearer jwt'},
      )).called(1);
    });

    test('rechazar sin nota (vacía no se envía)', () async {
      respond(FunctionResponse(status: 200, data: {'appeal': {}}));

      await dataSource.decideAppeal(const AppealDecision(appealId: 'ap-1', accept: false, note: '   '));

      verify(functions.invoke(
        'moderation-review',
        body: {'action': 'decide_appeal', 'appeal_id': 'ap-1', 'decision': 'reject'},
        headers: {'Authorization': 'Bearer jwt'},
      )).called(1);
    });

    test('409 same_moderator → PermissionFailure insufficientPermissions', () async {
      when(functions.invoke(any, body: anyNamed('body'), headers: anyNamed('headers'))).thenThrow(
        FunctionException(status: 409, details: {'error': 'x', 'code': 'same_moderator'}),
      );

      await expectLater(
        dataSource.decideAppeal(const AppealDecision(appealId: 'ap-1', accept: true)),
        throwsA(isA<PermissionFailure>().having((f) => f.code, 'code', ErrorCode.insufficientPermissions)),
      );
    });

    test('409 sin code → DataFailure conflict', () async {
      when(functions.invoke(any, body: anyNamed('body'), headers: anyNamed('headers')))
          .thenThrow(FunctionException(status: 409, details: {'error': 'Appeal already decided'}));

      await expectLater(
        dataSource.decideAppeal(const AppealDecision(appealId: 'ap-1', accept: true)),
        throwsA(isA<DataFailure>().having((f) => f.code, 'code', ErrorCode.conflict)),
      );
    });
  });
}
