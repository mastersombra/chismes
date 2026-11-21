import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/moderation_appeal.dart';
import '../../domain/usecases/decide_appeal.dart';

/// Resultado de decidir una apelación
enum AppealDecisionOutcome {
  /// Aplicada
  done,

  /// Ya no está pendiente (otro moderador la decidió): igual sale de la lista
  alreadyDecided,

  /// Se exige que la decida otro moderador (el que rechazó no puede)
  needsAnotherModerator,

  /// Error: sigue pendiente ([AppealDecisionController.errorCode])
  failed,
}

/// Aceptar / rechazar una apelación (pantalla de detalle)
@injectable
class AppealDecisionController extends ChangeNotifier {
  final DecideAppeal _decideAppeal;

  AppealDecisionController(this._decideAppeal);

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  ErrorCode? _errorCode;
  ErrorCode? get errorCode => _errorCode;

  bool _disposed = false;

  Future<AppealDecisionOutcome> decide(String appealId, {required bool accept, String? note}) async {
    if (_isSubmitting) return AppealDecisionOutcome.failed;
    _isSubmitting = true;
    _errorCode = null;
    _notify();

    final result = await _decideAppeal(AppealDecision(appealId: appealId, accept: accept, note: note));
    final outcome = result.when(
      onSuccess: (_) => AppealDecisionOutcome.done,
      onFailure: (failure) {
        if (failure.code == ErrorCode.conflict || failure.code == ErrorCode.notFound) {
          return AppealDecisionOutcome.alreadyDecided;
        }
        if (failure.code == ErrorCode.insufficientPermissions) {
          return AppealDecisionOutcome.needsAnotherModerator;
        }
        _errorCode = failure.code;
        return AppealDecisionOutcome.failed;
      },
    );

    _isSubmitting = false;
    _notify();
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
