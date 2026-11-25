import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/logging/logging.dart';
import '../../../../core/result/result.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/profile_service.dart';
import '../../../location/presentation/managers/location_manager.dart';
import '../../domain/entities/feed_gossip.dart';
import '../../domain/usecases/get_following_feed.dart';
import '../../domain/usecases/get_recommended_feed.dart';
import '../states/following_tab_state.dart';

/// Controller para el tab Siguiendo del home.
///
/// **Responsabilidades:**
/// - Gestionar estado del feed de personas que sigo
/// - Cargar feed de quienes sigo
/// - Fallback a recomendados si no hay chismes
/// - Empty state si no sigue a nadie
/// - Cargar más chismes (infinite scroll)
///
/// **Casos:**
/// 1. **No sigue a nadie:** Empty state especial con CTA
/// 2. **Sigue a gente pero no hay chismes:** Fallback a recomendados
/// 3. **Hay chismes:** Feed normal
///
/// **Uso:**
/// ```dart
/// class _FollowingTabState extends State<FollowingTab> {
///   late FollowingTabController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = getIt<FollowingTabController>();
///     _controller.loadFeed();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return ListenableBuilder(
///       listenable: _controller,
///       builder: (context, _) {
///         if (_controller.state.isLoadingInitial) {
///           return Center(child: CircularProgressIndicator());
///         }
///
///         if (_controller.state.isNotFollowing) {
///           return EmptyStateNotFollowing();
///         }
///
///         if (_controller.state.isShowingRecommended) {
///           return Column(
///             children: [
///               RecommendedBadge(),
///               Expanded(child: GossipList(gossips: _controller.state.recommendedGossips)),
///             ],
///           );
///         }
///
///         return GossipList(gossips: _controller.state.gossips);
///       },
///     );
///   }
/// }
/// ```
@injectable
class FollowingTabController extends ChangeNotifier {
  final GetFollowingFeed _getFollowingFeed;
  final GetRecommendedFeed _getRecommendedFeed;
  final LocationManager _locationManager;
  final ProfileService _profileService;
  final AuthService _authService;
  final AppLogger _logger;

  FollowingTabState _state = const FollowingTabState();

  FollowingTabController(
    this._getFollowingFeed,
    this._getRecommendedFeed,
    this._locationManager,
    this._profileService,
    this._authService,
    this._logger,
  );

  /// Estado actual
  FollowingTabState get state => _state;

  /// Actualiza estado y notifica listeners
  void _updateState(FollowingTabState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Carga el feed.
  ///
  /// **Flujo:**
  /// 1. Verificar si sigue a alguien (followingCount de ProfileService)
  /// 2. Si no sigue a nadie → notFollowing state
  /// 3. Si sigue a gente → cargar feed
  /// 4. Si feed vacío → cargar recomendados (fallback)
  Future<void> loadFeed() async {
    _logger.d('Loading following feed');

    _updateState(_state.copyWith(
      status: FollowingTabStatus.loading,
    ));

    try {
      final userId = _authService.userId;
      if (userId == null) {
        // Sin sesión (no debería pasar tras AuthGate): no hay a quién seguir
        _logger.w('No authenticated user for following feed');
        _updateState(_state.copyWith(
          status: FollowingTabStatus.notFollowing,
          followingCount: 0,
        ));
        return;
      }

      // Obtener followingCount de ProfileService
      final followingCount = await _profileService.getFollowingCount(userId);

      _logger.d('Following count obtained', context: {
        'count': followingCount,
      });

      // Caso 1: No sigue a nadie
      if (followingCount == 0) {
        _logger.i('User not following anyone, showing empty state');
        _updateState(_state.copyWith(
          status: FollowingTabStatus.notFollowing,
          followingCount: 0,
        ));
        return;
      }

      // Caso 2: Cargar feed de quienes sigue
      final result = await _getFollowingFeed(
        pageSize: 20,
        cursor: null,
      );

      switch (result) {
        case ResultFailure(error: final failure):
          _logger.e('Failed to load following feed', error: failure);
          _updateState(_state.copyWith(
            status: FollowingTabStatus.error,
            errorMessage: failure.toString(),
          ));
        case Success(value: final paginated):
          _logger.i('Following feed loaded', context: {
            'count': paginated.data.length,
            'hasMore': paginated.hasMore,
          });

          // Caso 3: Hay chismes
          if (paginated.data.isNotEmpty) {
            _updateState(_state.copyWith(
              status: FollowingTabStatus.loaded,
              gossips: paginated.data,
              followingCount: followingCount,
              hasMore: paginated.hasMore,
              nextCursor: paginated.nextCursor,
            ));
          } else {
            // Caso 4: No hay chismes, cargar recomendados
            _logger.i('Following feed empty, loading recommended');
            await _loadRecommended(followingCount);
          }
      }
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error loading following feed',
        error: error,
        stackTrace: stackTrace,
      );
      _updateState(_state.copyWith(
        status: FollowingTabStatus.error,
        errorMessage: 'Unexpected error loading following feed',
      ));
    }
  }

  /// Carga feed recomendado (fallback).
  ///
  /// **Uso interno:** Llamado automáticamente cuando el feed de Following está vacío.
  Future<void> _loadRecommended(int followingCount) async {
    _logger.d('Loading recommended feed');

    try {
      // Obtener ciudad
      final cityId = _locationManager.state.selectedCity?.id;

      final result = await _getRecommendedFeed(
        userId: null,
        cityId: cityId,
        pageSize: 20,
        cursor: null,
      );

      switch (result) {
        case ResultFailure(error: final failure):
          _logger.e('Failed to load recommended feed', error: failure);
          _updateState(_state.copyWith(
            status: FollowingTabStatus.error,
            errorMessage: failure.toString(),
          ));
        case Success(value: final paginated):
          _logger.i('Recommended feed loaded', context: {
            'count': paginated.data.length,
          });

          _updateState(_state.copyWith(
            status: FollowingTabStatus.loadedRecommended,
            recommendedGossips: paginated.data,
            followingCount: followingCount,
            hasMore: paginated.hasMore,
            nextCursor: paginated.nextCursor,
          ));
      }
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error loading recommended feed',
        error: error,
        stackTrace: stackTrace,
      );
      _updateState(_state.copyWith(
        status: FollowingTabStatus.error,
        errorMessage: 'Error loading recommended feed',
      ));
    }
  }

  /// Refresca el feed (pull-to-refresh).
  ///
  /// **Comportamiento:**
  /// - Recarga desde el inicio
  /// - Resetea paginación
  Future<void> refresh() async {
    _logger.d('Refreshing following feed');

    // Resetear paginación
    _updateState(_state.copyWithNullable(
      clearCursor: true,
      hasMore: true,
    ));

    // Recargar desde inicio
    await loadFeed();
  }

  /// Carga más chismes (infinite scroll).
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
      'currentCount': _state.activeList.length,
      'cursor': _state.nextCursor?.toString(),
    });

    // Guardar estado anterior ANTES de cambiar a loadingMore
    // (isShowingRecommended depende del status)
    final wasShowingRecommended = _state.isShowingRecommended;

    _updateState(_state.copyWith(
      status: FollowingTabStatus.loadingMore,
    ));

    try {
      // Decidir qué use case usar según el estado anterior
      if (wasShowingRecommended) {
        // Cargar más recomendados
        await _loadMoreRecommended();
      } else {
        // Cargar más de quienes sigo
        await _loadMoreFollowing();
      }
    } catch (error, stackTrace) {
      _logger.e(
        'Unexpected error loading more gossips',
        error: error,
        stackTrace: stackTrace,
      );
      // Volver al estado anterior
      _updateState(_state.copyWith(
        status: wasShowingRecommended
            ? FollowingTabStatus.loadedRecommended
            : FollowingTabStatus.loaded,
      ));
    }
  }

  /// Carga más chismes de quienes sigo.
  Future<void> _loadMoreFollowing() async {
    final result = await _getFollowingFeed(
      pageSize: 20,
      cursor: _state.nextCursor,
    );

    switch (result) {
      case ResultFailure(error: final failure):
        _logger.e('Failed to load more following gossips', error: failure);
        _updateState(_state.copyWith(
          status: FollowingTabStatus.loaded,
        ));
      case Success(value: final paginated):
        _logger.i('More following gossips loaded', context: {
          'newCount': paginated.data.length,
          'totalCount': _state.gossips.length + paginated.data.length,
        });

        final updatedGossips = List<FeedGossip>.from([
          ..._state.gossips,
          ...paginated.data,
        ]);

        _updateState(_state.copyWith(
          status: FollowingTabStatus.loaded,
          gossips: updatedGossips,
          hasMore: paginated.hasMore,
          nextCursor: paginated.nextCursor,
        ));
    }
  }

  /// Carga más recomendados.
  Future<void> _loadMoreRecommended() async {
    final cityId = _locationManager.state.selectedCity?.id;

    final result = await _getRecommendedFeed(
      userId: null,
      cityId: cityId,
      pageSize: 20,
      cursor: _state.nextCursor,
    );

    switch (result) {
      case ResultFailure(error: final failure):
        _logger.e('Failed to load more recommended gossips', error: failure);
        _updateState(_state.copyWith(
          status: FollowingTabStatus.loadedRecommended,
        ));
      case Success(value: final paginated):
        _logger.i('More recommended gossips loaded', context: {
          'newCount': paginated.data.length,
          'totalCount':
              _state.recommendedGossips.length + paginated.data.length,
        });

        final updatedGossips = List<FeedGossip>.from([
          ..._state.recommendedGossips,
          ...paginated.data,
        ]);

        _updateState(_state.copyWith(
          status: FollowingTabStatus.loadedRecommended,
          recommendedGossips: updatedGossips,
          hasMore: paginated.hasMore,
          nextCursor: paginated.nextCursor,
        ));
    }
  }

  @override
  void dispose() {
    _logger.d('FollowingTabController disposed');
    super.dispose();
  }
}
