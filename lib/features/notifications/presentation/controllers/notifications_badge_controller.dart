import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/auth_service.dart';
import '../../domain/usecases/get_unread_notifications_count.dart';

/// Contador de notificaciones sin leer de la campana (valor = cantidad).
///
/// Sin Realtime: se refresca al crear la campana, al volver la app a primer
/// plano, al cambiar de pestaña y al cerrar la pantalla de notificaciones.
/// [refresh] ignora las llamadas dentro de [throttle] desde el último
/// refresco correcto (salvo `force`). Un error conserva el último valor.
///
/// Al cerrar sesión vuelve a 0 (escucha [AuthService.userStream]).
@lazySingleton
class NotificationsBadgeController extends ValueNotifier<int> {
  static const throttle = Duration(seconds: 10);

  final GetUnreadNotificationsCount _getUnreadCount;
  final AppLogger _logger;
  StreamSubscription<Object?>? _authSubscription;

  /// Reloj (reemplazable en tests)
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  DateTime? _lastSuccess;
  Future<void>? _inFlight;

  /// Sube con cada [clear]: descarta respuestas pedidas antes
  int _generation = 0;

  NotificationsBadgeController(
    this._getUnreadCount,
    AuthService authService,
    this._logger,
  ) : super(0) {
    _authSubscription = authService.userStream.listen(
      (user) {
        if (user == null) clear();
      },
      onError: (Object error) =>
          _logger.w('Auth stream error in notifications badge', context: {'error': '$error'}),
    );
  }

  /// Texto del badge: '' si no hay, '99+' si son más de 99
  static String label(int count) {
    if (count <= 0) return '';
    return count > 99 ? '99+' : '$count';
  }

  /// Pide el contador al servidor (si no se pidió hace poco o [force])
  Future<void> refresh({bool force = false}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final last = _lastSuccess;
    if (!force && last != null && now().difference(last) < throttle) {
      return Future.value();
    }
    final future = _load().whenComplete(() => _inFlight = null);
    _inFlight = future;
    return future;
  }

  Future<void> _load() async {
    final generation = _generation;
    final result = await _getUnreadCount();
    if (generation != _generation) return; // Se limpió mientras tanto
    switch (result) {
      case Success(value: final count):
        _lastSuccess = now();
        value = count < 0 ? 0 : count;
      case ResultFailure(error: final failure):
        _logger.w('Failed to refresh unread notifications', context: {
          'code': failure.code.name,
        });
    }
  }

  /// Vuelve a 0 (todas leídas o sesión cerrada). El próximo [refresh] va al
  /// servidor aunque no haya pasado [throttle].
  void clear() {
    _generation++;
    _inFlight = null;
    _lastSuccess = null;
    value = 0;
  }

  @override
  @disposeMethod
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    super.dispose();
  }
}
