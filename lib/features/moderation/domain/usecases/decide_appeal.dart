import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/moderation_appeal.dart';
import '../repositories/moderation_repository.dart';
import '../validators/appeal_validator.dart';

/// Acepta o rechaza una apelación
///
/// - Aceptar anula la falta (la sanción se recalcula en el servidor) y
///   republica el texto del chisme (su media se borró al rechazarlo).
/// - Rechazar mantiene la falta.
@injectable
class DecideAppeal {
  final ModerationRepository _repository;

  DecideAppeal(this._repository);

  Future<Result<Failure, void>> call(AppealDecision decision) async {
    final validation = AppealValidator.validateDecision(decision);
    if (validation != null) return Result.failure(validation);

    return _repository.decideAppeal(decision);
  }
}
