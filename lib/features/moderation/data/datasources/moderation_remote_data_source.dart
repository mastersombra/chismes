import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide ErrorCode;

import '../../../../core/error/error_codes.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../domain/entities/review_decision.dart';
import '../models/moderation_item_model.dart';

/// Cliente de la Edge Function `moderation-review`
///
/// Lanza [Failure] (el repositorio las convierte en `Result`):
/// - 401 → [AuthFailure] `unauthorized`
/// - 403 → [PermissionFailure] `forbidden` (no es moderador)
/// - 404 → [DataFailure] `notFound`
/// - 409 → [DataFailure] `conflict` (otro moderador ya decidió)
/// - 400 → [ValidationFailure] `validationError`
/// - resto → [ServerFailure] `serverError`
@singleton
class ModerationRemoteDataSource {
  static const functionName = 'moderation-review';

  final SupabaseClient _supabase;
  final AppLogger _logger;

  ModerationRemoteDataSource(this._supabase, this._logger);

  Future<List<ModerationItemModel>> getQueue({
    required String status,
    required int limit,
    required int offset,
  }) async {
    final data = await _invoke({
      'action': 'list',
      'status': status,
      'limit': limit,
      'offset': offset,
    });

    final items = (data as Map<String, dynamic>?)?['items'];
    if (items is! List) {
      throw const ServerFailure(
        code: ErrorCode.serverError,
        technicalMessage: 'moderation-review list: missing items',
      );
    }
    return items
        .map((item) => ModerationItemModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> decide(ReviewDecision decision) async {
    final note = decision.note?.trim();
    await _invoke({
      'action': 'decide',
      'queue_id': decision.queueId,
      'decision': decision.approve ? 'approve' : 'reject',
      if (decision.severity != null) 'severity': decision.severity!.value,
      if (decision.reason != null) 'reason': decision.reason!.value,
      if (note != null && note.isNotEmpty) 'note': note,
    });
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
      _logger.w('moderation-review failed', context: {
        'action': body['action'],
        'status': error.status,
      });
      throw _failureForStatus(error.status, error.details);
    }
  }

  static Failure _failureForStatus(int status, dynamic details) {
    final message = 'moderation-review $status: $details';
    switch (status) {
      case 401:
        return AuthFailure(code: ErrorCode.unauthorized, technicalMessage: message);
      case 403:
        return PermissionFailure(code: ErrorCode.forbidden, technicalMessage: message);
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
