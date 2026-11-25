import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/social_user.dart';
import '../../domain/usecases/get_blocked_users.dart';
import '../../domain/usecases/unblock_user.dart';
import 'follow_requests_controller.dart' show SocialListStatus;

/// Usuarios que bloqueé: desbloquear
@injectable
class BlockedUsersController extends ChangeNotifier {
  final GetBlockedUsers _getBlockedUsers;
  final UnblockUser _unblockUser;

  BlockedUsersController(this._getBlockedUsers, this._unblockUser);

  SocialListStatus _status = SocialListStatus.initial;
  Failure? _failure;
  List<SocialUser> _users = const [];
  final Set<String> _processing = {};
  bool _disposed = false;

  SocialListStatus get status => _status;
  Failure? get failure => _failure;
  List<SocialUser> get users => _users;
  bool isProcessing(String userId) => _processing.contains(userId);

  Future<void> load() async {
    _status = SocialListStatus.loading;
    _notify();
    final result = await _getBlockedUsers();
    switch (result) {
      case Success(value: final users):
        _users = users;
        _status = SocialListStatus.loaded;
        _failure = null;
      case ResultFailure(error: final failure):
        _failure = failure;
        _status = SocialListStatus.error;
    }
    _notify();
  }

  /// Desbloquea a [userId] y lo quita de la lista. Devuelve el error o null.
  Future<Failure?> unblock(String userId) async {
    if (_processing.contains(userId)) return null;
    _processing.add(userId);
    _notify();

    final result = await _unblockUser(userId);
    _processing.remove(userId);
    if (result case Success()) {
      _users = _users.where((u) => u.id != userId).toList();
    }
    _notify();
    return result.failureValue;
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
