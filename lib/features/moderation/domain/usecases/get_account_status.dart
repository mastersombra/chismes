import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/account_status.dart';
import '../repositories/account_status_repository.dart';

/// Estado de la cuenta del usuario actual: sanción vigente, puntos y rechazos
@injectable
class GetAccountStatus {
  final AccountStatusRepository _repository;

  GetAccountStatus(this._repository);

  Future<Result<Failure, AccountStatus>> call() => _repository.getStatus();
}
