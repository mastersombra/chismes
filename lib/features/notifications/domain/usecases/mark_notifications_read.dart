import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/notifications_repository.dart';

/// Marca como leídas las [ids] indicadas o, sin ids, todas
@injectable
class MarkNotificationsRead {
  final NotificationsRepository _repository;

  MarkNotificationsRead(this._repository);

  Future<Result<Failure, int>> call({List<String>? ids}) => _repository.markRead(ids: ids);
}
