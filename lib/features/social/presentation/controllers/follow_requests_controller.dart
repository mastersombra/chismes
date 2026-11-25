import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/follow_request.dart';
import '../../domain/usecases/get_follow_requests.dart';
import '../../domain/usecases/respond_follow_request.dart';

enum SocialListStatus { initial, loading, loaded, error }

/// Solicitudes de seguimiento a mi cuenta privada: aceptar o rechazar
@injectable
class FollowRequestsController extends ChangeNotifier {
  final GetFollowRequests _getFollowRequests;
  final RespondFollowRequest _respondFollowRequest;

  FollowRequestsController(this._getFollowRequests, this._respondFollowRequest);

  SocialListStatus _status = SocialListStatus.initial;
  Failure? _failure;
  List<FollowRequest> _requests = const [];
  final Set<String> _processing = {};
  bool _disposed = false;

  SocialListStatus get status => _status;
  Failure? get failure => _failure;
  List<FollowRequest> get requests => _requests;
  bool isProcessing(String userId) => _processing.contains(userId);

  Future<void> load() async {
    _status = SocialListStatus.loading;
    _notify();
    final result = await _getFollowRequests();
    switch (result) {
      case Success(value: final requests):
        _requests = requests;
        _status = SocialListStatus.loaded;
        _failure = null;
      case ResultFailure(error: final failure):
        _failure = failure;
        _status = SocialListStatus.error;
    }
    _notify();
  }

  Future<Failure?> accept(String requesterId) => _respond(requesterId, accept: true);

  Future<Failure?> reject(String requesterId) => _respond(requesterId, accept: false);

  /// Si falla con "no disponible" (la canceló o hubo bloqueo) igual se
  /// quita de la lista: ya no está pendiente.
  Future<Failure?> _respond(String requesterId, {required bool accept}) async {
    if (_processing.contains(requesterId)) return null;
    _processing.add(requesterId);
    _notify();

    final result = await _respondFollowRequest(requesterId, accept: accept);
    _processing.remove(requesterId);
    final failure = result.failureValue;
    if (failure == null || failure is DataFailure) {
      _requests = _requests.where((r) => r.user.id != requesterId).toList();
    }
    _notify();
    return failure;
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
