import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/navigation/social_navigator.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/auth_service.dart';
import '../../domain/entities/social_page.dart';
import '../../domain/entities/social_user.dart';
import '../../domain/usecases/get_follow_list.dart';
import '../../domain/usecases/remove_follower.dart';

enum FollowListStatus {
  initial,
  loading,
  loaded,

  /// No puedo ver la lista (cuenta privada que no sigo, o bloqueo)
  notAvailable,
  error,
}

/// Lista paginada de seguidores o seguidos de un usuario. En MIS seguidores
/// permite quitar a alguien.
@injectable
class FollowListController extends ChangeNotifier {
  static const pageSize = 30;

  final GetFollowList _getFollowList;
  final RemoveFollower _removeFollower;
  final AuthService _authService;
  final AppLogger _logger;

  FollowListController(
    this._getFollowList,
    this._removeFollower,
    this._authService,
    this._logger,
  );

  late String _userId;
  late FollowListKind _kind;
  FollowListStatus _status = FollowListStatus.initial;
  Failure? _failure;
  List<SocialUser> _users = const [];
  bool _hasMore = false;
  SocialCursor? _cursor;
  bool _isLoadingMore = false;
  final Set<String> _removing = {};
  bool _disposed = false;

  FollowListStatus get status => _status;
  Failure? get failure => _failure;
  List<SocialUser> get users => _users;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  FollowListKind get kind => _kind;

  /// Es la lista de MIS seguidores: se puede "Quitar"
  bool get canRemoveFollowers =>
      _kind == FollowListKind.followers && _userId == _authService.userId;

  bool isRemoving(String userId) => _removing.contains(userId);

  /// Carga la primera página de [kind] de [userId]
  Future<void> load(String userId, FollowListKind kind) async {
    _userId = userId;
    _kind = kind;
    _status = FollowListStatus.loading;
    _failure = null;
    _notify();
    await _loadFirst();
  }

  Future<void> refresh() => _loadFirst();

  Future<void> _loadFirst() async {
    final result = await _getFollowList(_userId, _kind, pageSize: pageSize);
    switch (result) {
      case Success(value: final page):
        _users = page.items;
        _hasMore = page.hasMore;
        _cursor = page.nextCursor;
        _status = FollowListStatus.loaded;
        _failure = null;
      case ResultFailure(error: final failure):
        _failure = failure;
        _status = failure.code == ErrorCode.userNotAvailable
            ? FollowListStatus.notAvailable
            : FollowListStatus.error;
    }
    _notify();
  }

  Future<void> loadMore() async {
    if (_status != FollowListStatus.loaded ||
        _isLoadingMore ||
        !_hasMore ||
        _cursor == null) {
      return;
    }
    _isLoadingMore = true;
    _notify();

    final result = await _getFollowList(
      _userId,
      _kind,
      pageSize: pageSize,
      cursor: _cursor,
    );
    switch (result) {
      case Success(value: final page):
        _users = [..._users, ...page.items];
        _hasMore = page.hasMore;
        _cursor = page.nextCursor;
      case ResultFailure(error: final failure):
        _logger.w('Failed to load more follow list', context: {'code': failure.code.name});
    }
    _isLoadingMore = false;
    _notify();
  }

  /// Quita a [followerId] de mis seguidores. Devuelve el error o null.
  Future<Failure?> removeFollower(String followerId) async {
    if (!canRemoveFollowers || _removing.contains(followerId)) return null;
    _removing.add(followerId);
    _notify();

    final result = await _removeFollower(followerId);
    _removing.remove(followerId);
    if (result case Success()) {
      _users = _users.where((u) => u.id != followerId).toList();
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
