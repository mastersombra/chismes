import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import 'profile_remote_datasource_delete_account_test.mocks.dart';

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
  late ProfileRemoteDataSource dataSource;

  setUp(() {
    supabase = MockSupabaseClient();
    auth = MockGoTrueClient();
    session = MockSession();
    functions = MockFunctionsClient();
    when(supabase.auth).thenReturn(auth);
    when(supabase.functions).thenReturn(functions);
    when(auth.currentSession).thenReturn(session);
    when(session.accessToken).thenReturn('jwt');
    dataSource = ProfileRemoteDataSource(supabase, MockAppLogger());
  });

  void respond(FunctionResponse response) {
    when(functions.invoke(any, body: anyNamed('body'), headers: anyNamed('headers')))
        .thenAnswer((_) async => response);
  }

  void throwStatus(int status) {
    when(functions.invoke(any, body: anyNamed('body'), headers: anyNamed('headers')))
        .thenThrow(FunctionException(status: status, details: {'error': 'x'}));
  }

  group('deleteAccount', () {
    test('llama a delete-account con la confirmación y el JWT, luego cierra la sesión local', () async {
      respond(FunctionResponse(status: 200, data: {'deleted': true}));

      await dataSource.deleteAccount();

      verifyInOrder([
        functions.invoke(
          'delete-account',
          body: {'confirmation': 'DELETE_MY_ACCOUNT'},
          headers: {'Authorization': 'Bearer jwt'},
        ),
        auth.signOut(scope: SignOutScope.local),
      ]);
    });

    test('sin sesión → AuthFailure y no llama al servidor', () async {
      when(auth.currentSession).thenReturn(null);

      await expectLater(
        dataSource.deleteAccount(),
        throwsA(isA<AuthFailure>().having((f) => f.code, 'code', ErrorCode.unauthorized)),
      );
      verifyNever(functions.invoke(any, body: anyNamed('body'), headers: anyNamed('headers')));
      verifyNever(auth.signOut(scope: anyNamed('scope')));
    });

    final cases = <int, TypeMatcher<Failure>>{
      401: isA<AuthFailure>(),
      400: isA<ValidationFailure>(),
      500: isA<ServerFailure>(),
    };
    cases.forEach((status, matcher) {
      test('FunctionException $status → Failure y no cierra sesión', () async {
        throwStatus(status);

        await expectLater(dataSource.deleteAccount(), throwsA(matcher));
        verifyNever(auth.signOut(scope: anyNamed('scope')));
      });
    });

    test('respuesta no 2xx sin excepción → ServerFailure', () async {
      respond(FunctionResponse(status: 503, data: {'error': 'down'}));

      await expectLater(dataSource.deleteAccount(), throwsA(isA<ServerFailure>()));
      verifyNever(auth.signOut(scope: anyNamed('scope')));
    });

    test('si falla el cierre de sesión local, la eliminación igual se considera exitosa', () async {
      respond(FunctionResponse(status: 200, data: {'deleted': true}));
      when(auth.signOut(scope: anyNamed('scope'))).thenThrow(Exception('storage'));

      await dataSource.deleteAccount();

      verify(auth.signOut(scope: SignOutScope.local)).called(1);
    });
  });
}
