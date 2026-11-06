import 'package:equatable/equatable.dart';

import '../../domain/entities/feed_cursor.dart';
import '../../domain/entities/feed_gossip.dart';

/// Estados posibles del tab Siguiendo.
enum FollowingTabStatus {
  /// Estado inicial (antes de cargar)
  initial,

  /// Cargando feed
  loading,

  /// Feed cargado (hay chismes de quienes sigo)
  loaded,

  /// Feed vacío, mostrando recomendados (fallback)
  loadedRecommended,

  /// No sigue a nadie (empty state)
  notFollowing,

  /// Error al cargar
  error,

  /// Cargando más chismes (infinite scroll)
  loadingMore,
}

/// Estado inmutable del tab Siguiendo.
///
/// **Casos:**
/// 1. **loaded**: Hay chismes de personas que sigo
/// 2. **loadedRecommended**: No hay chismes, mostrando recomendados (fallback)
/// 3. **notFollowing**: No sigo a nadie (empty state especial)
class FollowingTabState extends Equatable {
  final FollowingTabStatus status;
  final List<FeedGossip> gossips;
  final List<FeedGossip> recommendedGossips;
  final String? errorMessage;
  final int followingCount;

  // Paginación
  final bool hasMore;
  final FeedCursor? nextCursor;

  // Banner de nuevos chismes
  final bool hasNewGossips;
  final int newGossipsCount;

  const FollowingTabState({
    this.status = FollowingTabStatus.initial,
    this.gossips = const [],
    this.recommendedGossips = const [],
    this.errorMessage,
    this.followingCount = 0,
    this.hasMore = true,
    this.nextCursor,
    this.hasNewGossips = false,
    this.newGossipsCount = 0,
  });

  @override
  List<Object?> get props => [
        status,
        gossips,
        recommendedGossips,
        errorMessage,
        followingCount,
        hasMore,
        nextCursor,
        hasNewGossips,
        newGossipsCount,
      ];

  /// Si está cargando
  bool get isLoading =>
      status == FollowingTabStatus.loading ||
      status == FollowingTabStatus.loadingMore;

  /// Si está cargando el feed inicial
  bool get isLoadingInitial => status == FollowingTabStatus.loading;

  /// Si está cargando más chismes (infinite scroll)
  bool get isLoadingMore => status == FollowingTabStatus.loadingMore;

  /// Si hay un error
  bool get hasError => status == FollowingTabStatus.error;

  /// Si está mostrando feed de quienes sigo
  bool get isShowingFollowing => status == FollowingTabStatus.loaded;

  /// Si está mostrando recomendados (fallback)
  bool get isShowingRecommended =>
      status == FollowingTabStatus.loadedRecommended;

  /// Si no sigue a nadie (empty state)
  bool get isNotFollowing => status == FollowingTabStatus.notFollowing;

  /// Si el feed está vacío
  bool get isEmpty => gossips.isEmpty && recommendedGossips.isEmpty;

  /// Lista activa (gossips o recommended según el estado)
  List<FeedGossip> get activeList {
    if (isShowingRecommended) {
      return recommendedGossips;
    }
    return gossips;
  }

  /// Copia con cambios
  FollowingTabState copyWith({
    FollowingTabStatus? status,
    List<FeedGossip>? gossips,
    List<FeedGossip>? recommendedGossips,
    String? errorMessage,
    int? followingCount,
    bool? hasMore,
    FeedCursor? nextCursor,
    bool? hasNewGossips,
    int? newGossipsCount,
  }) {
    return FollowingTabState(
      status: status ?? this.status,
      gossips: gossips ?? this.gossips,
      recommendedGossips: recommendedGossips ?? this.recommendedGossips,
      errorMessage: errorMessage ?? this.errorMessage,
      followingCount: followingCount ?? this.followingCount,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      hasNewGossips: hasNewGossips ?? this.hasNewGossips,
      newGossipsCount: newGossipsCount ?? this.newGossipsCount,
    );
  }

  /// Copia limpiando campos nullable
  FollowingTabState copyWithNullable({
    FollowingTabStatus? status,
    List<FeedGossip>? gossips,
    List<FeedGossip>? recommendedGossips,
    bool clearError = false,
    int? followingCount,
    bool? hasMore,
    bool clearCursor = false,
    bool? hasNewGossips,
    int? newGossipsCount,
  }) {
    return FollowingTabState(
      status: status ?? this.status,
      gossips: gossips ?? this.gossips,
      recommendedGossips: recommendedGossips ?? this.recommendedGossips,
      errorMessage: clearError ? null : errorMessage,
      followingCount: followingCount ?? this.followingCount,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearCursor ? null : nextCursor,
      hasNewGossips: hasNewGossips ?? this.hasNewGossips,
      newGossipsCount: newGossipsCount ?? this.newGossipsCount,
    );
  }

  @override
  String toString() {
    return 'FollowingTabState('
        'status: $status, '
        'gossips: ${gossips.length}, '
        'recommended: ${recommendedGossips.length}, '
        'following: $followingCount'
        ')';
  }
}
