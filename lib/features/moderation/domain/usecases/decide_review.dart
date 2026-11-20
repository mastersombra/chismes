import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/review_decision.dart';
import '../repositories/moderation_repository.dart';
import '../validators/review_decision_validator.dart';

/// Aprueba o rechaza una entrada de la cola de revisión
///
/// - Aprobar publica el chisme (y su media en cuarentena).
/// - Rechazar lo oculta (no se borra: queda para apelación) y exige gravedad.
@injectable
class DecideReview {
  final ModerationRepository _repository;

  DecideReview(this._repository);

  Future<Result<Failure, void>> call(ReviewDecision decision) async {
    final validation = ReviewDecisionValidator.validate(decision);
    if (validation != null) return Result.failure(validation);

    return _repository.decide(decision);
  }
}
