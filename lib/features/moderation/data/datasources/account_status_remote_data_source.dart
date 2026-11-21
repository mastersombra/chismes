import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../../../core/error/error_codes.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../domain/entities/account_status.dart';
import '../models/account_status_model.dart';

/// Cliente de la Edge Function `account-status` (cualquier usuario, sobre sí)
///
/// Lanza [Failure] (el repositorio las convierte en `Result`):
/// - 401 → [AuthFailure] `unauthorized`
/// - 404 → [DataFailure] `notFound` (rechazo inexistente o ajeno)
/// - 409 → [DataFailure] `conflict` (ya apelado o fuera de plazo)
/// - 400 → [ValidationFailure] `validationError`
/// - resto → [ServerFailure] `serverError`
@singleton
class AccountStatusRemoteDataSource {
  static const functionName = 'account-status';

  final SupabaseClient _supabase;
  final AppLogger _logger;

  AccountStatusRemoteDataSource(this._supabase, this._logger);

  Future<AccountStatus> getStatus() async {
    final data = await _invoke(const {'action': 'status'});
    final status = data is Map<String, dynamic> ? data['status'] : null;
    if (status is! Map<String, dynamic>) {
      throw const ServerFailure(
        code: ErrorCode.serverError,
        technicalMessage: 'account-status: missing status',
      );
    }
    return AccountStatusModel(status).toEntity();
  }

  Future<AccountAppeal> submitAppeal({required String queueId, required String message}) async {
    final data = await _invoke({'action': 'appeal', 'queue_id': queueId, 'message': message});
    final appeal = data is Map<String, dynamic> ? data['appeal'] : null;
    if (appeal is! Map<String, dynamic>) {
      throw const ServerFailure(
        code: ErrorCode.serverError,
        technicalMessage: 'account-status appeal: missing appeal',
      );
    }
    return AccountStatusModel.appealFromJson(appeal);
  }

  Future<dynamic> _invoke(Map<String, dynamic> body) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw const AuthFailure(
        code: ErrorCode.unauthorized,
        technicalMessage: 'No active session',
      );
    }

    try {
      final response = await _supabase.functions.invoke(
        functionName,
        body: body,
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );
      if (response.status < 200 || response.status >= 300) {
        throw _failureForStatus(response.status, response.data);
      }
      return response.data;
    } on FunctionException catch (error) {
      _logger.w('account-status failed', context: {
        'action': body['action'],
        'status': error.status,
      });
      throw _failureForStatus(error.status, error.details);
    }
  }

  static Failure _failureForStatus(int status, dynamic details) {
    final message = 'account-status $status: $details';
    switch (status) {
      case 401:
        return AuthFailure(code: ErrorCode.unauthorized, technicalMessage: message);
      case 404:
        return DataFailure(code: ErrorCode.notFound, technicalMessage: message);
      case 409:
        return DataFailure(code: ErrorCode.conflict, technicalMessage: message);
      case 400:
        return ValidationFailure(code: ErrorCode.validationError, technicalMessage: message);
      default:
        return ServerFailure(code: ErrorCode.serverError, technicalMessage: message);
    }
  }
}
