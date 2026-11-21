import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/usecases/get_account_status.dart';
import '../../domain/usecases/submit_appeal.dart';

/// Resultado de enviar una apelación
enum AppealOutcome {
  /// Enviada
  done,

  /// El servidor no la admite (ya apelado, fuera de plazo o el rechazo ya no
  /// existe): el estado se recarga para mostrar lo actual
  notAllowed,

  /// Error: se puede reintentar ([AccountStatusController.appealErrorCode])
  failed,
}

/// Estado de la cuenta del usuario y sus apelaciones (Perfil → Estado de la cuenta)
@injectable
class AccountStatusController extends ChangeNotifier {
  final GetAccountStatus _getStatus;
  final SubmitAppeal _submitAppeal;
  final AppLogger _logger;

  AccountStatusController(this._getStatus, this._submitAppeal, this._logger);

  AccountStatus? _status;
  AccountStatus? get status => _status;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ErrorCode? _errorCode;

  /// Error al cargar el estado
  ErrorCode? get errorCode => _errorCode;

  /// Rechazo cuya apelación se está enviando
  String? _submittingQueueId;
  String? get submittingQueueId => _submittingQueueId;

  ErrorCode? _appealErrorCode;
  ErrorCode? get appealErrorCode => _appealErrorCode;

  bool _disposed = false;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorCode = null;
    _notify();

    final result = await _getStatus();
    result.when(
      onSuccess: (status) => _status = status,
      onFailure: (failure) {
        _logger.w('Failed to load account status', context: {'code': failure.code.name});
        _errorCode = failure.code;
      },
    );

    _isLoading = false;
    _notify();
  }

  Future<AppealOutcome> submitAppeal({required String queueId, required String message}) async {
    if (_submittingQueueId != null) return AppealOutcome.failed;
    _submittingQueueId = queueId;
    _appealErrorCode = null;
    _notify();

    final result = await _submitAppeal(queueId: queueId, message: message);
    final outcome = result.when(
      onSuccess: (_) => AppealOutcome.done,
      onFailure: (failure) {
        if (failure.code == ErrorCode.conflict || failure.code == ErrorCode.notFound) {
          return AppealOutcome.notAllowed;
        }
        _appealErrorCode = failure.code;
        return AppealOutcome.failed;
      },
    );

    _submittingQueueId = null;
    _notify();
    if (outcome != AppealOutcome.failed) await load();
    return outcome;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
