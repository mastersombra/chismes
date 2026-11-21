import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/account_status.dart';
import '../repositories/account_status_repository.dart';
import '../validators/appeal_validator.dart';

/// Apela un rechazo propio (uno por rechazo, dentro del plazo)
@injectable
class SubmitAppeal {
  final AccountStatusRepository _repository;

  SubmitAppeal(this._repository);

  Future<Result<Failure, AccountAppeal>> call({
    required String queueId,
    required String message,
  }) async {
    final validation = AppealValidator.validateSubmission(queueId: queueId, message: message);
    if (validation != null) return Result.failure(validation);

    return _repository.submitAppeal(queueId: queueId, message: message.trim());
  }
}
