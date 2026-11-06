import 'package:equatable/equatable.dart';

import '../../domain/entities/feed_cursor.dart';
import '../../domain/entities/feed_gossip.dart';

/// Estados posibles del tab Popular.
enum PopularTabStatus {
  /// Estado inicial (antes de cargar)
  initial,

  /// Cargando feed inicial
  loading,

  /// Feed cargado exitosamente
  loaded,

  /// Error al cargar feed
  error,

  /// Cargando nuevos chismes del banner
  loadingNew,

  /// Cargando más chismes (infinite scroll)
  loadingMore,
}

/// Estado inmutable del tab Popular.
///
/// **Uso con ChangeNotifier:**
/// ```dart
/// class PopularTabController extends ChangeNotifier {
///   PopularTabState _state = const PopularTabState();
///
///   PopularTabState get state => _state;
///
///   void _updateState(PopularTabState newState) {
///     _state = newState;
///     notifyListeners();
///   }
/// }
/// ```
class PopularTabState extends Equatable {
  final PopularTabStatus status;
  final List<FeedGossip> gossips;
  final String? errorMessage;
  final String? currentCityId;
  final String? currentCityName;
  final DateTime? lastLoadTime;

  // Paginación
  final bool hasMore;
  final FeedCursor? nextCursor;

  // Banner de nuevos chismes
  final bool hasNewGossips;
  final int newGossipsCount;

  const PopularTabState({
    this.status = PopularTabStatus.initial,
    this.gossips = const [],
    this.errorMessage,
    this.currentCityId,
    this.currentCityName,
    this.lastLoadTime,
    this.hasMore = true,
    this.nextCursor,
    this.hasNewGossips = false,
    this.newGossipsCount = 0,
  });

  @override
  List<Object?> get props => [
        status,
        gossips,
        errorMessage,
        currentCityId,
        currentCityName,
        lastLoadTime,
        hasMore,
        nextCursor,
        hasNewGossips,
        newGossipsCount,
      ];

  /// Si está cargando (cualquier tipo de carga)
  bool get isLoading =>
      status == PopularTabStatus.loading ||
      status == PopularTabStatus.loadingNew ||
      status == PopularTabStatus.loadingMore;

  /// Si está cargando el feed inicial
  bool get isLoadingInitial => status == PopularTabStatus.loading;

  /// Si está cargando más chismes (infinite scroll)
  bool get isLoadingMore => status == PopularTabStatus.loadingMore;

  /// Si hay un error
  bool get hasError => status == PopularTabStatus.error;

  /// Si el feed está cargado
  bool get isLoaded => status == PopularTabStatus.loaded;

  /// Si el feed está vacío
  bool get isEmpty => gossips.isEmpty;

  /// Texto del header de ubicación
  String get locationHeaderText {
    if (currentCityName != null) {
      return 'Popular en $currentCityName';
    }
    return 'Popular 🌎';
  }

  /// Copia con cambios
  PopularTabState copyWith({
    PopularTabStatus? status,
    List<FeedGossip>? gossips,
    String? errorMessage,
    String? currentCityId,
    String? currentCityName,
    DateTime? lastLoadTime,
    bool? hasMore,
    FeedCursor? nextCursor,
    bool? hasNewGossips,
    int? newGossipsCount,
  }) {
    return PopularTabState(
      status: status ?? this.status,
      gossips: gossips ?? this.gossips,
      errorMessage: errorMessage ?? this.errorMessage,
      currentCityId: currentCityId ?? this.currentCityId,
      currentCityName: currentCityName ?? this.currentCityName,
      lastLoadTime: lastLoadTime ?? this.lastLoadTime,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor ?? this.nextCursor,
      hasNewGossips: hasNewGossips ?? this.hasNewGossips,
      newGossipsCount: newGossipsCount ?? this.newGossipsCount,
    );
  }

  /// Copia limpiando campos nullable
  PopularTabState copyWithNullable({
    PopularTabStatus? status,
    List<FeedGossip>? gossips,
    bool clearError = false,
    String? currentCityId,
    String? currentCityName,
    DateTime? lastLoadTime,
    bool? hasMore,
    bool clearCursor = false,
    bool? hasNewGossips,
    int? newGossipsCount,
  }) {
    return PopularTabState(
      status: status ?? this.status,
      gossips: gossips ?? this.gossips,
      errorMessage: clearError ? null : errorMessage,
      currentCityId: currentCityId ?? this.currentCityId,
      currentCityName: currentCityName ?? this.currentCityName,
      lastLoadTime: lastLoadTime ?? this.lastLoadTime,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: clearCursor ? null : nextCursor,
      hasNewGossips: hasNewGossips ?? this.hasNewGossips,
      newGossipsCount: newGossipsCount ?? this.newGossipsCount,
    );
  }

  @override
  String toString() {
    return 'PopularTabState('
        'status: $status, '
        'gossips: ${gossips.length}, '
        'hasMore: $hasMore, '
        'hasNewGossips: $hasNewGossips'
        ')';
  }
}
