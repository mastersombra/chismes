import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/notifications_repository.dart';

/// Cantidad de notificaciones sin leer (máx. 100)
@injectable
class GetUnreadNotificationsCount {
  final NotificationsRepository _repository;

  GetUnreadNotificationsCount(this._repository);

  Future<Result<Failure, int>> call() => _repository.getUnreadCount();
}
