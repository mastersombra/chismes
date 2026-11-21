import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/error_codes.dart';
import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/moderation_appeal.dart';
import '../../domain/usecases/get_appeals.dart';

/// Una lista de apelaciones (pendientes, aceptadas o rechazadas)
@immutable
class AppealsListState {
  final List<ModerationAppeal> items;

  /// Ya se pidió al menos una página
  final bool loaded;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final ErrorCode? errorCode;

  const AppealsListState({
    this.items = const [],
    this.loaded = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorCode,
  });

  AppealsListState copyWith({
    List<ModerationAppeal>? items,
    bool? loaded,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    ErrorCode? Function()? errorCode,
  }) {
    return AppealsListState(
      items: items ?? this.items,
      loaded: loaded ?? this.loaded,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorCode: errorCode != null ? errorCode() : this.errorCode,
    );
  }
}

/// Apelaciones en el panel de moderación: una lista paginada por estado,
/// cargada al elegirla por primera vez ([select]).
@injectable
class AppealsController extends ChangeNotifier {
  final GetAppeals _getAppeals;
  final AppLogger _logger;

  AppealsController(this._getAppeals, this._logger);

  final Map<AppealStatus, AppealsListState> _lists = {
    for (final status in AppealStatus.values) status: const AppealsListState(),
  };

  AppealStatus _selected = AppealStatus.pending;
  AppealStatus get selected => _selected;

  bool _disposed = false;

  AppealsListState list(AppealStatus status) => _lists[status]!;

  AppealsListState get current => list(_selected);

  /// Cambia de lista y la carga si nunca se cargó
  Future<void> select(AppealStatus status) async {
    _selected = status;
    _notify();
    final state = list(status);
    if (state.loaded || state.isLoading) return;
    await refresh(status);
  }

  /// Recarga desde la primera página
  Future<void> refresh(AppealStatus status) async {
    if (list(status).isLoading) return;
    _set(status, list(status).copyWith(isLoading: true, errorCode: () => null));

    final result = await _getAppeals(status: status);
    result.when(
      onSuccess: (items) => _set(
        status,
        AppealsListState(items: items, loaded: true, hasMore: items.length >= GetAppeals.pageSize),
      ),
      onFailure: (failure) {
        _logger.w('Failed to load appeals', context: {
          'status': status.value,
          'code': failure.code.name,
        });
        _set(status, list(status).copyWith(loaded: true, isLoading: false, errorCode: () => failure.code));
      },
    );
  }

  /// Siguiente página (scroll infinito)
  Future<void> loadMore(AppealStatus status) async {
    final state = list(status);
    if (!state.loaded || state.isLoading || state.isLoadingMore || !state.hasMore) return;
    _set(status, state.copyWith(isLoadingMore: true));

    final result = await _getAppeals(status: status, offset: state.items.length);
    result.when(
      onSuccess: (page) {
        final known = {for (final item in list(status).items) item.id};
        _set(
          status,
          list(status).copyWith(
            items: [...list(status).items, ...page.where((i) => !known.contains(i.id))],
            isLoadingMore: false,
            hasMore: page.length >= GetAppeals.pageSize,
          ),
        );
      },
      onFailure: (failure) {
        _logger.w('Failed to load more appeals', context: {
          'status': status.value,
          'code': failure.code.name,
        });
        _set(status, list(status).copyWith(isLoadingMore: false, hasMore: false));
      },
    );
  }

  /// Se decidió (aquí o por otro moderador): sale de pendientes y el
  /// historial se recarga la próxima vez que se elija
  void onAppealDecided(String appealId) {
    final pending = list(AppealStatus.pending);
    _lists[AppealStatus.pending] = pending.copyWith(
      items: pending.items.where((a) => a.id != appealId).toList(),
    );
    _lists[AppealStatus.accepted] = const AppealsListState();
    _lists[AppealStatus.rejected] = const AppealsListState();
    _notify();
  }

  void _set(AppealStatus status, AppealsListState state) {
    _lists[status] = state;
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
