import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../../location/presentation/managers/location_manager.dart';
import '../../domain/entities/feed_gossip.dart';
import '../../domain/usecases/check_new_gossips.dart';
import '../../domain/usecases/get_popular_feed.dart';
import '../states/popular_tab_state.dart';

/// Controller para el tab Popular del home.
///
/// **Responsabilidades:**
/// - Gestionar estado del feed popular
/// - Cargar feed inicial
/// - Refrescar feed (pull-to-refresh)
/// - Cargar más chismes (infinite scroll)
/// - Polling para detectar nuevos chismes
/// - Gestionar banner de nuevos chismes
///
/// **Uso:**
/// ```dart
/// @injectable
/// class PopularTab extends StatefulWidget {
///   @override
///   State<PopularTab> createState() => _PopularTabState();
/// }
///
/// class _PopularTabState extends State<PopularTab> {
///   late PopularTabController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = getIt<PopularTabController>();
///     _controller.loadFeed();
///   }
///
///   @override
///   void dispose() {
///     _controller.dispose(); // Importante: cancela polling
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return RefreshIndicator(
///       onRefresh: () => _controller.refresh(),
///       child: ListenableBuilder(
///         listenable: _controller,
///         builder: (context, _) {
///           if (_controller.state.isLoadingInitial) {
///             return Center(child: CircularProgressIndicator());
///           }
///
///           return ListView.builder(
///             itemCount: _controller.state.gossips.length,
///             itemBuilder: (context, index) {
///               // Preload cuando falta 3 items
///               if (index == _controller.state.gossips.length - 3) {
///                 _controller.loadMore();
///               }
///               return GossipCard(gossip: _controller.state.gossips[index]);
///             },
///           );
///         },
///       ),
///     );
///   }
/// }
/// ```
@injectable
class PopularTabController extends ChangeNotifier {
  final GetPopularFeed _getPopularFeed;
  final CheckNewGossips _checkNewGossips;
  final LocationManager _locationManager;
  final AppLogger _logger;

  PopularTabState _state = const PopularTabState();

  // Polling timer
  Timer? _pollingTimer;
  static const _pollingInterval = Duration(seconds: 60);

  PopularTabController(
    this._getPopularFeed,
    this._checkNewGossips,
    this._locationManager,
    this._logger,
  );

  /// Estado actual
  PopularTabState get state => _state;

  /// Actualiza estado y notifica listeners
  void _updateState(PopularTabState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Carga el feed inicial.
  ///
  /// **Flujo:**
  /// 1. Detectar ciudad (GPS o guardada)
  /// 2. Llamar use case GetPopularFeed
  /// 3. Actualizar estado con chismes
  /// 4. Iniciar polling para nuevos chismes
  Future<void> loadFeed() async {
    _logger.d('Loading popular feed');

    _updateState(_state.copyWith(
      status: PopularTabStatus.loading,
    ));

    try {
      // 1. Obtener ciudad (de LocationManager state)
      // TODO: Cargar ubicación guardada al iniciar la app
      final city = _locationManager.state.selectedCity;

      _logger.d('Location obtained', context: {
        'cityId': city?.id,
        'cityName': city?.name,
      });

      // 2. Cargar feed
      final result = await _getPopularFeed(
        userId: null, // TODO: Get from AuthService when implemented
        cityId: city?.id,
        pageSize: 20,
        cursor: null,
      );

      switch (result) {
        case ResultFailure(error: final failure):
          _logger.e('Failed to load popular feed', error: failure);
          _updateState(_state.copyWith(
            status: PopularTabStatus.error,
            errorMessage: failure.toString(),
          ));
        case Success(value: final paginated):
          _logger.i('Popular feed loaded', context: {
            'count': paginated.data.length,
            'hasMore': paginated.hasMore,
          });

          _updateState(_state.copyWith(
            status: PopularTabStatus.loaded,
            gossips: paginated.data,
            currentCityId: city?.id,
            currentCityName: city?.name,
            lastLoadTime: DateTime.now(),
            hasMore: paginated.hasMore,
            nextCursor: paginated.nextCursor,
          ));

          // 3. Iniciar polling
          _startPolling();
      }
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error loading popular feed',
        error: error,
        stackTrace: stackTrace,
      );
      _updateState(_state.copyWith(
        status: PopularTabStatus.error,
        errorMessage: 'Error inesperado al cargar feed',
      ));
    }
  }

  /// Refresca el feed (pull-to-refresh).
  ///
  /// **Comportamiento:**
  /// - Recarga desde el inicio (sin cursor)
  /// - Oculta banner de nuevos chismes
  /// - Resetea paginación
  Future<void> refresh() async {
    _logger.d('Refreshing popular feed');

    // Resetear paginación y banner
    _updateState(_state.copyWithNullable(
      hasNewGossips: false,
      newGossipsCount: 0,
      clearCursor: true,
      hasMore: true,
    ));

    // Recargar desde inicio
    await loadFeed();
  }

  /// Carga más chismes (infinite scroll).
  ///
  /// **Uso:** Llamar cuando el usuario scrollea cerca del final.
  ///
  /// **Guard clauses:**
  /// - Si ya está cargando más → skip
  /// - Si no hay más páginas → skip
  Future<void> loadMore() async {
    // Guard clauses
    if (_state.isLoadingMore || !_state.hasMore) {
      return;
    }

    _logger.d('Loading more gossips', context: {
      'currentCount': _state.gossips.length,
      'cursor': _state.nextCursor?.toString(),
    });

    _updateState(_state.copyWith(
      status: PopularTabStatus.loadingMore,
    ));

    try {
      final result = await _getPopularFeed(
        userId: null,
        cityId: _state.currentCityId,
        pageSize: 20,
        cursor: _state.nextCursor,
      );

      switch (result) {
        case ResultFailure(error: final failure):
          _logger.e('Failed to load more gossips', error: failure);
          // Volver a estado loaded (no cambiar lista actual)
          _updateState(_state.copyWith(
            status: PopularTabStatus.loaded,
          ));
        case Success(value: final paginated):
          _logger.i('More gossips loaded', context: {
            'newCount': paginated.data.length,
            'totalCount': _state.gossips.length + paginated.data.length,
            'hasMore': paginated.hasMore,
          });

          // Agregar nuevos chismes a la lista existente
          final updatedGossips = List<FeedGossip>.from([
            ..._state.gossips,
            ...paginated.data,
          ]);

          _updateState(_state.copyWith(
            status: PopularTabStatus.loaded,
            gossips: updatedGossips,
            hasMore: paginated.hasMore,
            nextCursor: paginated.nextCursor,
          ));
      }
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error loading more gossips',
        error: error,
        stackTrace: stackTrace,
      );
      // Volver a estado loaded
      _updateState(_state.copyWith(
        status: PopularTabStatus.loaded,
      ));
    }
  }

  /// Inicia polling para detectar nuevos chismes.
  ///
  /// **Comportamiento:**
  /// - Verifica cada 60 segundos
  /// - Solo si hay lastLoadTime
  /// - Actualiza banner si hay nuevos
  void _startPolling() {
    _stopPolling(); // Cancelar timer anterior si existe

    _pollingTimer = Timer.periodic(_pollingInterval, (_) async {
      await _checkForNewGossips();
    });

    _logger.d('Polling started');
  }

  /// Detiene el polling.
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Verifica si hay chismes nuevos.
  ///
  /// **Comportamiento:**
  /// - Llama CheckNewGossips use case
  /// - Si hay nuevos, actualiza estado para mostrar banner
  Future<void> _checkForNewGossips() async {
    if (_state.lastLoadTime == null) {
      return;
    }

    _logger.d('Checking for new gossips');

    try {
      final result = await _checkNewGossips(
        userId: null,
        cityId: _state.currentCityId,
        since: _state.lastLoadTime!,
      );

      switch (result) {
        case ResultFailure(error: final failure):
          // Silently fail (no notificar al usuario)
          _logger.w('Failed to check new gossips', error: failure);
        case Success(value: final count):
          if (count > 0) {
            _logger.i('New gossips detected', context: {'count': count});
            _updateState(_state.copyWith(
              hasNewGossips: true,
              newGossipsCount: count,
            ));
          }
      }
    } catch (error) {
      _logger.w('Error checking new gossips', error: error);
    }
  }

  /// Carga los nuevos chismes (cuando usuario hace tap en banner).
  ///
  /// **Comportamiento:**
  /// - Oculta banner
  /// - Recarga feed desde inicio
  /// - Scroll automático al top (manejado por UI)
  Future<void> loadNewGossips() async {
    _logger.d('Loading new gossips from banner');

    // Ocultar banner
    _updateState(_state.copyWith(
      hasNewGossips: false,
      newGossipsCount: 0,
    ));

    // Recargar feed
    await loadFeed();
  }

  @override
  void dispose() {
    _stopPolling();
    _logger.d('PopularTabController disposed');
    super.dispose();
  }
}
