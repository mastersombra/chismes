import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/social_user.dart';
import '../../domain/usecases/search_users.dart';

enum UserSearchStatus {
  /// Texto vacío o muy corto: no se buscó
  idle,
  loading,
  loaded,
  error,
}

/// Búsqueda de usuarios (pestaña Usuarios de Buscar).
///
/// [search] espera [debounce] antes de llamar al servidor; si llega otra
/// búsqueda mientras tanto, la anterior se descarta (también su respuesta).
@injectable
class UserSearchController extends ChangeNotifier {
  static const debounce = Duration(milliseconds: 300);

  final SearchUsers _searchUsers;

  UserSearchController(this._searchUsers);

  UserSearchStatus _status = UserSearchStatus.idle;
  Failure? _failure;
  List<SocialUser> _users = const [];
  String _query = '';
  int _requestId = 0;
  Timer? _timer;
  bool _disposed = false;

  UserSearchStatus get status => _status;
  Failure? get failure => _failure;
  List<SocialUser> get users => _users;
  String get query => _query;

  /// Busca [query] con debounce
  void search(String query) {
    _timer?.cancel();
    if (SearchUsers.normalize(query).length < SearchUsers.minQueryLength) {
      _reset(query);
      return;
    }
    _query = query;
    _requestId++;
    _status = UserSearchStatus.loading;
    _notify();
    _timer = Timer(debounce, () => searchNow(query));
  }

  /// Busca [query] ya (sin debounce): reintentar
  Future<void> searchNow(String query) async {
    _timer?.cancel();
    if (SearchUsers.normalize(query).length < SearchUsers.minQueryLength) {
      _reset(query);
      return;
    }
    _query = query;
    final requestId = ++_requestId;
    _status = UserSearchStatus.loading;
    _notify();

    final result = await _searchUsers(query);
    // Llegó otra búsqueda mientras tanto: esta respuesta ya no sirve
    if (requestId != _requestId) return;

    switch (result) {
      case Success(value: final users):
        _users = users;
        _status = UserSearchStatus.loaded;
        _failure = null;
      case ResultFailure(error: final failure):
        _failure = failure;
        _status = UserSearchStatus.error;
    }
    _notify();
  }

  void _reset(String query) {
    _requestId++;
    _query = query;
    _users = const [];
    _failure = null;
    _status = UserSearchStatus.idle;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
