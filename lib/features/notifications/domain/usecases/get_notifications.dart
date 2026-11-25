import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/notification_page.dart';
import '../repositories/notifications_repository.dart';

/// Página de notificaciones (paginada por cursor)
@injectable
class GetNotifications {
  final NotificationsRepository _repository;

  GetNotifications(this._repository);

  Future<Result<Failure, NotificationPage>> call({
    int pageSize = 30,
    NotificationCursor? cursor,
  }) =>
      _repository.getNotifications(pageSize: pageSize, cursor: cursor);
}
