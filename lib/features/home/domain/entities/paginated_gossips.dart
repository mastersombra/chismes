import 'package:equatable/equatable.dart';

import 'feed_cursor.dart';
import 'feed_gossip.dart';

/// Respuesta paginada del feed con cursor-based pagination.
///
/// Contiene:
/// - `data`: Lista de chismes de la página actual
/// - `hasMore`: Si hay más páginas disponibles
/// - `nextCursor`: Cursor para cargar la siguiente página
///
/// **Uso en UI:**
/// ```dart
/// final result = await getPopularFeed();
///
/// result.fold(
///   onFailure: (failure) => showError(failure),
///   onSuccess: (paginated) {
///     // Mostrar chismes
///     gossips.addAll(paginated.data);
///
///     // Verificar si hay más
///     if (paginated.hasMore) {
///       // Guardar cursor para próxima vez
///       _nextCursor = paginated.nextCursor;
///     }
///   },
/// );
/// ```
///
/// **Uso en Controller:**
/// ```dart
/// Future<void> loadMore() async {
///   if (!_hasMore || _isLoadingMore) return;
///
///   final result = await _getPopularFeed(cursor: _nextCursor);
///
///   result.fold(
///     onFailure: (_) => {},
///     onSuccess: (paginated) {
///       _gossips.addAll(paginated.data);
///       _hasMore = paginated.hasMore;
///       _nextCursor = paginated.nextCursor;
///     },
///   );
/// }
/// ```
class PaginatedGossips extends Equatable {
  /// Lista de chismes de la página actual
  final List<FeedGossip> data;

  /// Si hay más páginas disponibles
  ///
  /// Se calcula en el backend:
  /// - Si `data.length < pageSize` → `hasMore = false`
  /// - Si `data.length >= pageSize` → `hasMore = true`
  final bool hasMore;

  /// Cursor para la siguiente página
  ///
  /// Contiene el score/created_at e id del último elemento de `data`.
  /// Null si `hasMore == false`.
  final FeedCursor? nextCursor;

  const PaginatedGossips({
    required this.data,
    required this.hasMore,
    this.nextCursor,
  }) : assert(
          !hasMore || nextCursor != null,
          'nextCursor debe existir si hasMore es true',
        );

  /// Constructor para respuesta vacía
  const PaginatedGossips.empty()
      : data = const [],
        hasMore = false,
        nextCursor = null;

  @override
  List<Object?> get props => [data, hasMore, nextCursor];

  /// Si la respuesta está vacía
  bool get isEmpty => data.isEmpty;

  /// Si la respuesta tiene datos
  bool get isNotEmpty => data.isNotEmpty;

  /// Número de chismes en esta página
  int get length => data.length;

  @override
  String toString() {
    return 'PaginatedGossips('
        'count: ${data.length}, '
        'hasMore: $hasMore, '
        'nextCursor: $nextCursor'
        ')';
  }
}
