import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/moderation_item.dart';
import '../../domain/entities/review_decision.dart';
import '../../domain/usecases/decide_review.dart';

/// Resultado de enviar una decisión
enum DecisionOutcome {
  /// Aplicada
  done,

  /// Ya no está pendiente (otro moderador decidió o el chisme se borró):
  /// el ítem igual sale de pendientes
  alreadyDecided,

  /// Error: el ítem sigue pendiente ([ReviewDecisionController.errorCode])
  failed,
}

/// Aprobar / rechazar un ítem de la cola (pantalla de detalle)
@injectable
class ReviewDecisionController extends ChangeNotifier {
  final DecideReview _decideReview;

  ReviewDecisionController(this._decideReview);

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  ErrorCode? _errorCode;
  ErrorCode? get errorCode => _errorCode;

  bool _disposed = false;

  Future<DecisionOutcome> approve(String queueId) {
    return _submit(ReviewDecision.approve(queueId: queueId));
  }

  Future<DecisionOutcome> reject(
    String queueId, {
    required ModerationSeverity severity,
    RejectReason? reason,
    String? note,
  }) {
    return _submit(ReviewDecision.reject(
      queueId: queueId,
      severity: severity,
      reason: reason,
      note: note,
    ));
  }

  Future<DecisionOutcome> _submit(ReviewDecision decision) async {
    if (_isSubmitting) return DecisionOutcome.failed;
    _isSubmitting = true;
    _errorCode = null;
    _notify();

    final result = await _decideReview(decision);
    final outcome = result.when(
      onSuccess: (_) => DecisionOutcome.done,
      onFailure: (failure) {
        if (failure.code == ErrorCode.conflict || failure.code == ErrorCode.notFound) {
          return DecisionOutcome.alreadyDecided;
        }
        _errorCode = failure.code;
        return DecisionOutcome.failed;
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
