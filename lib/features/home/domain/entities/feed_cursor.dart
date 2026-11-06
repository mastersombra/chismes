import 'package:equatable/equatable.dart';

/// Cursor para paginación cursor-based en el feed.
///
/// En lugar de offset-based pagination (LIMIT/OFFSET), usamos cursor-based
/// que es más eficiente y evita duplicados cuando hay inserciones concurrentes.
///
/// El cursor contiene los valores de las columnas de ordenamiento
/// (score, id o created_at, id) del último elemento de la página anterior.
///
/// **Por qué cursor-based:**
/// - Performance: O(1) vs O(n) con offsets grandes
/// - No duplicados: Los nuevos elementos no afectan la paginación
/// - Usa índices: Siempre puede usar índices compuestos
///
/// **Ejemplo de uso:**
/// ```dart
/// // Primera página (sin cursor)
/// final firstPage = await getPopularFeed(cursor: null);
///
/// // Segunda página (con cursor del último elemento)
/// final cursor = FeedCursor(
///   score: firstPage.data.last.score,
///   id: firstPage.data.last.id,
/// );
/// final secondPage = await getPopularFeed(cursor: cursor);
/// ```
class FeedCursor extends Equatable {
  /// Score del último elemento (para Popular feed)
  /// Null si es Following feed (usa created_at)
  final double? score;

  /// created_at del último elemento (para Following feed)
  /// Null si es Popular feed (usa score)
  final DateTime? createdAt;

  /// ID del último elemento (siempre requerido para desempate)
  final String id;

  const FeedCursor({
    this.score,
    this.createdAt,
    required this.id,
  }) : assert(
          score != null || createdAt != null,
          'Debe tener score (Popular) o createdAt (Following)',
        );

  /// Constructor para Popular feed (ordena por score)
  const FeedCursor.popular({
    required double score,
    required String id,
  }) : this(score: score, id: id);

  /// Constructor para Following feed (ordena por created_at)
  const FeedCursor.following({
    required DateTime createdAt,
    required String id,
  }) : this(createdAt: createdAt, id: id);

  @override
  List<Object?> get props => [score, createdAt, id];

  Map<String, dynamic> toJson() => {
        if (score != null) 'score': score,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        'id': id,
      };

  factory FeedCursor.fromJson(Map<String, dynamic> json) {
    final score = json['score'] as num?;
    final createdAtStr = json['created_at'] as String?;

    return FeedCursor(
      score: score?.toDouble(),
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : null,
      id: json['id'] as String,
    );
  }

  @override
  String toString() {
    if (score != null) {
      return 'FeedCursor.popular(score: $score, id: $id)';
    } else {
      return 'FeedCursor.following(createdAt: $createdAt, id: $id)';
    }
  }
}
