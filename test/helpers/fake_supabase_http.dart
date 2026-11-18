import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// SupabaseClient real sobre un http.Client falso.
///
/// Permite probar la cadena real `from().select().eq()...` y `rpc()` sin red.
class FakeSupabaseHttp {
  final List<http.Request> requests = [];
  http.Response Function(http.Request req) handler;

  late final SupabaseClient client = SupabaseClient(
    'https://test.supabase.co',
    'anon-key',
    httpClient: MockClient((req) async {
      requests.add(req);
      return handler(req);
    }),
  );

  FakeSupabaseHttp([http.Response Function(http.Request req)? handler])
      : handler = handler ?? ((req) => jsonResponse(req, []));

  http.Request get lastRequest => requests.last;

  Map<String, dynamic> get lastBody =>
      jsonDecode(lastRequest.body) as Map<String, dynamic>;

  void respondJson(Object? body, {int status = 200}) {
    handler = (req) => jsonResponse(req, body, status: status);
  }

  void respondError(int status, {String message = 'boom', String code = 'XX000'}) {
    handler = (req) => jsonResponse(
          req,
          {'message': message, 'code': code, 'details': null, 'hint': null},
          status: status,
        );
  }

  void respondRaw(String body, {int status = 200}) {
    handler = (req) => http.Response(body, status,
        headers: {'content-type': 'application/json'}, request: req);
  }

  // postgrest lee response.request!, así que hay que adjuntar el request.
  static http.Response jsonResponse(http.Request req, Object? body,
          {int status = 200}) =>
      http.Response(jsonEncode(body), status,
          headers: {'content-type': 'application/json'}, request: req);
}
