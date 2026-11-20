import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/moderation_item.dart';
import '../repositories/moderation_repository.dart';

/// Lista una página de la cola de revisión (pendientes o historial)
@injectable
class GetModerationQueue {
  /// Tamaño de página (el servidor admite hasta 50)
  static const int pageSize = 20;

  final ModerationRepository _repository;

  GetModerationQueue(this._repository);

  Future<Result<Failure, List<ModerationItem>>> call({
    required ModerationQueueStatus status,
    int offset = 0,
  }) {
    return _repository.getQueue(status: status, limit: pageSize, offset: offset);
  }
}
