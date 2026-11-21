import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/account_status.dart';
import '../entities/moderation_appeal.dart';
import '../repositories/moderation_repository.dart';

/// Lista una página de apelaciones (pendientes o decididas)
@injectable
class GetAppeals {
  /// Tamaño de página (el servidor admite hasta 50)
  static const int pageSize = 20;

  final ModerationRepository _repository;

  GetAppeals(this._repository);

  Future<Result<Failure, List<ModerationAppeal>>> call({
    required AppealStatus status,
    int offset = 0,
  }) {
    return _repository.getAppeals(status: status, limit: pageSize, offset: offset);
  }
}
