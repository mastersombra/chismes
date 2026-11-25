import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../../gossip/domain/entities/gossip.dart';
import '../../domain/entities/social_page.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/usecases/block_user.dart';
import '../../domain/usecases/follow_user.dart';
import '../../domain/usecases/get_user_gossips.dart';
import '../../domain/usecases/get_user_profile.dart';
import '../../domain/usecases/unblock_user.dart';
import '../../domain/usecases/unfollow_user.dart';

enum UserProfileStatus {
  initial,
  loading,
  loaded,

  /// No existe o hay un bloqueo de su lado (no se distingue a propósito)
  notAvailable,
  error,
}

/// Perfil de otro usuario (o el propio): datos, chismes con perfil y las
/// acciones seguir / dejar de seguir / bloquear / desbloquear.
///
/// Tras cada acción se vuelve a leer el perfil del servidor (sin spinner de
/// pantalla completa): contadores y permisos (cuenta privada) quedan exactos.
@injectable
class UserProfileController extends ChangeNotifier {
  static const pageSize = 20;

  final GetUserProfile _getUserProfile;
  final GetUserGossips _getUserGossips;
  final FollowUser _followUser;
  final UnfollowUser _unfollowUser;
  final BlockUser _blockUser;
  final UnblockUser _unblockUser;
  final AppLogger _logger;

  UserProfileController(
    this._getUserProfile,
    this._getUserGossips,
    this._followUser,
    this._unfollowUser,
    this._blockUser,
    this._unblockUser,
    this._logger,
  );

  String? _userId;
  UserProfileStatus _status = UserProfileStatus.initial;
  UserProfile? _profile;
  Failure? _failure;
  List<Gossip> _gossips = const [];
  bool _hasMoreGossips = false;
  SocialCursor? _cursor;
  bool _isLoadingGossips = false;
  bool _isLoadingMore = false;
  bool _gossipsFailed = false;
  bool _isActionInProgress = false;
  bool _disposed = false;

  UserProfileStatus get status => _status;
  UserProfile? get profile => _profile;

  /// Error de la carga del perfil (estado [UserProfileStatus.error])
  Failure? get failure => _failure;
  List<Gossip> get gossips => _gossips;
  bool get hasMoreGossips => _hasMoreGossips;
  bool get isLoadingGossips => _isLoadingGossips;
  bool get isLoadingMore => _isLoadingMore;

  /// La primera página de chismes falló (se puede reintentar)
  bool get gossipsFailed => _gossipsFailed;

  /// Hay una acción (seguir, bloquear...) en curso: botones deshabilitados
  bool get isActionInProgress => _isActionInProgress;

  /// Carga el perfil de [userId] y, si puedo ver su contenido, sus chismes
  Future<void> load(String userId) async {
    _userId = userId;
    _status = UserProfileStatus.loading;
    _failure = null;
    _notify();
    await _fetchProfile(showErrors: true);
  }

  /// Vuelve a leer perfil y chismes (pull-to-refresh)
  Future<void> refresh() async {
    if (_userId == null) return;
    await _fetchProfile(showErrors: _profile == null, reloadGossips: true);
  }

  Future<void> loadMoreGossips() async {
    final userId = _userId;
    if (userId == null ||
        _isLoadingMore ||
        _isLoadingGossips ||
        !_hasMoreGossips ||
        _cursor == null) {
      return;
    }
    _isLoadingMore = true;
    _notify();

    final result = await _getUserGossips(userId, pageSize: pageSize, cursor: _cursor);
    switch (result) {
      case Success(value: final page):
        _gossips = [..._gossips, ...page.items];
        _hasMoreGossips = page.hasMore;
        _cursor = page.nextCursor;
      case ResultFailure(error: final failure):
        _logger.w('Failed to load more user gossips', context: {'code': failure.code.name});
    }
    _isLoadingMore = false;
    _notify();
  }

  /// Reintenta la primera página de chismes
  Future<void> retryGossips() => _loadFirstGossipsPage();

  /// Seguir (o pedir seguir si es privada). Devuelve el error o null.
  Future<Failure?> follow() => _runAction((id) async {
        final result = await _followUser(id);
        return result.failureValue;
      });

  /// Dejar de seguir o cancelar la solicitud. Devuelve el error o null.
  Future<Failure?> unfollow() => _runAction((id) async {
        final result = await _unfollowUser(id);
        return result.failureValue;
      });

  Future<Failure?> block() => _runAction((id) async {
        final result = await _blockUser(id);
        return result.failureValue;
      });

  Future<Failure?> unblock() => _runAction((id) async {
        final result = await _unblockUser(id);
        return result.failureValue;
      });

  Future<Failure?> _runAction(Future<Failure?> Function(String userId) action) async {
    final userId = _userId;
    final profile = _profile;
    if (userId == null || profile == null || profile.isMe || _isActionInProgress) {
      return null;
    }
    _isActionInProgress = true;
    _notify();

    final failure = await action(userId);
    if (failure == null) {
      await _fetchProfile(showErrors: false);
    } else if (failure.code == ErrorCode.userNotAvailable) {
      // Me bloqueó o ya no existe
      _status = UserProfileStatus.notAvailable;
      _profile = null;
      _clearGossips();
    }

    _isActionInProgress = false;
    _notify();
    return failure;
  }

  /// Lee el perfil. Con [showErrors] un fallo cambia el estado de la
  /// pantalla; sin él (tras una acción) se conserva lo que había.
  Future<void> _fetchProfile({
    required bool showErrors,
    bool reloadGossips = false,
  }) async {
    final userId = _userId!;
    final previous = _profile;
    final result = await _getUserProfile(userId);

    switch (result) {
      case Success(value: final profile):
        _profile = profile;
        _status = UserProfileStatus.loaded;
        _failure = null;
        if (!profile.canViewContent) {
          _clearGossips();
        } else if (reloadGossips ||
            previous == null ||
            !previous.canViewContent ||
            _gossipsFailed) {
          _notify();
          await _loadFirstGossipsPage();
          return;
        }
      case ResultFailure(error: final failure):
        if (failure.code == ErrorCode.userNotAvailable) {
          _status = UserProfileStatus.notAvailable;
          _profile = null;
          _clearGossips();
        } else if (showErrors) {
          _status = UserProfileStatus.error;
          _failure = failure;
        } else {
          _logger.w('Failed to refresh user profile', context: {'code': failure.code.name});
        }
    }
    _notify();
  }

  Future<void> _loadFirstGossipsPage() async {
    final userId = _userId;
    if (userId == null) return;
    _isLoadingGossips = true;
    _gossipsFailed = false;
    _notify();

    final result = await _getUserGossips(userId, pageSize: pageSize);
    switch (result) {
      case Success(value: final page):
        _gossips = page.items;
        _hasMoreGossips = page.hasMore;
        _cursor = page.nextCursor;
      case ResultFailure(error: final failure):
        _logger.w('Failed to load user gossips', context: {'code': failure.code.name});
        _gossipsFailed = true;
    }
    _isLoadingGossips = false;
    _notify();
  }

  void _clearGossips() {
    _gossips = const [];
    _hasMoreGossips = false;
    _cursor = null;
    _gossipsFailed = false;
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
