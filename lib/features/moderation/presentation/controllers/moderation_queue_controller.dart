import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/result/result.dart';
import '../../../../core/logging/logging.dart';
import '../../domain/entities/moderation_item.dart';
import '../../domain/usecases/get_moderation_queue.dart';

/// Estado de una pestaña de la cola (pendientes, aprobados o rechazados)
@immutable
class ModerationTabState {
  final List<ModerationItem> items;

  /// Ya se pidió al menos una página
  final bool loaded;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final ErrorCode? errorCode;

  const ModerationTabState({
    this.items = const [],
    this.loaded = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorCode,
  });

  ModerationTabState copyWith({
    List<ModerationItem>? items,
    bool? loaded,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    ErrorCode? Function()? errorCode,
  }) {
    return ModerationTabState(
      items: items ?? this.items,
      loaded: loaded ?? this.loaded,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorCode: errorCode != null ? errorCode() : this.errorCode,
    );
  }
}

/// Cola de revisión humana: una lista paginada por estado.
///
/// Las pestañas se cargan al abrirse por primera vez ([ensureLoaded]). Tras
/// una decisión, [onItemDecided] saca el ítem de pendientes y marca el
/// historial para recargarse.
@injectable
class ModerationQueueController extends ChangeNotifier {
  final GetModerationQueue _getQueue;
  final AppLogger _logger;

  ModerationQueueController(this._getQueue, this._logger);

  final Map<ModerationQueueStatus, ModerationTabState> _tabs = {
    for (final status in ModerationQueueStatus.values) status: const ModerationTabState(),
  };

  bool _disposed = false;

  ModerationTabState tab(ModerationQueueStatus status) => _tabs[status]!;

  /// Carga la primera página si la pestaña nunca se cargó
  Future<void> ensureLoaded(ModerationQueueStatus status) async {
    final state = tab(status);
    if (state.loaded || state.isLoading) return;
    await refresh(status);
  }

  /// Recarga desde la primera página
  Future<void> refresh(ModerationQueueStatus status) async {
    if (tab(status).isLoading) return;
    _set(status, tab(status).copyWith(isLoading: true, errorCode: () => null));

    final result = await _getQueue(status: status);
    result.when(
      onSuccess: (items) => _set(
        status,
        ModerationTabState(
          items: items,
          loaded: true,
          hasMore: items.length >= GetModerationQueue.pageSize,
        ),
      ),
      onFailure: (failure) {
        _logger.w('Failed to load moderation queue', context: {
          'status': status.value,
          'code': failure.code.name,
        });
        _set(
          status,
          tab(status).copyWith(loaded: true, isLoading: false, errorCode: () => failure.code),
        );
      },
    );
  }

  /// Siguiente página (scroll infinito)
  Future<void> loadMore(ModerationQueueStatus status) async {
    final state = tab(status);
    if (!state.loaded || state.isLoading || state.isLoadingMore || !state.hasMore) return;
    _set(status, state.copyWith(isLoadingMore: true));

    final result = await _getQueue(status: status, offset: state.items.length);
    result.when(
      onSuccess: (page) {
        final known = {for (final item in tab(status).items) item.id};
        _set(
          status,
          tab(status).copyWith(
            // Sin duplicados si la cola cambió entre páginas
            items: [...tab(status).items, ...page.where((i) => !known.contains(i.id))],
            isLoadingMore: false,
            hasMore: page.length >= GetModerationQueue.pageSize,
          ),
        );
      },
      onFailure: (failure) {
        _logger.w('Failed to load more moderation items', context: {
          'status': status.value,
          'code': failure.code.name,
        });
        // No borra la lista: el usuario puede reintentar con el scroll
        _set(status, tab(status).copyWith(isLoadingMore: false, hasMore: false));
      },
    );
  }

  /// Un moderador decidió (o alguien más ya lo había hecho): sale de
  /// pendientes y el historial se recarga la próxima vez que se abra.
  void onItemDecided(String queueId) {
    final pending = tab(ModerationQueueStatus.pending);
    _tabs[ModerationQueueStatus.pending] = pending.copyWith(
      items: pending.items.where((i) => i.id != queueId).toList(),
    );
    _tabs[ModerationQueueStatus.approved] = const ModerationTabState();
    _tabs[ModerationQueueStatus.rejected] = const ModerationTabState();
    _notify();
  }

  void _set(ModerationQueueStatus status, ModerationTabState state) {
    _tabs[status] = state;
    _notify();
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
