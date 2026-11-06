import '../../domain/entities/feed_cursor.dart';
import '../../domain/entities/paginated_gossips.dart';
import 'feed_gossip_model.dart';

/// Model para PaginatedGossips - Mapea JSON de Supabase RPC.
///
/// **JSON esperado de Supabase:**
/// ```json
/// {
///   "data": [
///     { /* FeedGossipModel */ },
///     { /* FeedGossipModel */ },
///     ...
///   ],
///   "has_more": true,
///   "next_cursor": {
///     "score": 123.45,
///     "id": "uuid"
///   } | null
/// }
/// ```
///
/// **Diferencias con Entity:**
/// - JSON usa snake_case
/// - Entity usa camelCase
class PaginatedGossipsModel {
  final List<FeedGossipModel> data;
  final bool hasMore;
  final Map<String, dynamic>? nextCursor;

  const PaginatedGossipsModel({
    required this.data,
    required this.hasMore,
    this.nextCursor,
  });

  /// Deserializa desde JSON de Supabase RPC.
  ///
  /// **Throws:**
  /// - `FormatException`: Si el JSON tiene tipos incorrectos
  factory PaginatedGossipsModel.fromJson(Map<String, dynamic> json) {
    try {
      final dataList = json['data'] as List<dynamic>;
      final gossipModels = dataList
          .map((item) => FeedGossipModel.fromJson(item as Map<String, dynamic>))
          .toList();

      return PaginatedGossipsModel(
        data: gossipModels,
        hasMore: json['has_more'] as bool,
        nextCursor: json['next_cursor'] as Map<String, dynamic>?,
      );
    } catch (e) {
      throw FormatException(
        'Error deserializando PaginatedGossipsModel: $e\nJSON: $json',
      );
    }
  }

  /// Convierte a Entity del Domain Layer.
  ///
  /// **Conversiones:**
  /// - `data`: `List<FeedGossipModel>` → `List<FeedGossip>`
  /// - `nextCursor`: `Map` → `FeedCursor?`
  PaginatedGossips toEntity() {
    return PaginatedGossips(
      data: data.map((model) => model.toEntity()).toList(),
      hasMore: hasMore,
      nextCursor: nextCursor != null
          ? FeedCursor.fromJson(nextCursor!)
          : null,
    );
  }

  /// Constructor para respuesta vacía
  const PaginatedGossipsModel.empty()
      : data = const [],
        hasMore = false,
        nextCursor = null;

  @override
  String toString() {
    return 'PaginatedGossipsModel('
        'count: ${data.length}, '
        'hasMore: $hasMore, '
        'hasCursor: ${nextCursor != null}'
        ')';
  }
}
