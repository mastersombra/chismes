import '../../domain/entities/feed_gossip.dart';

/// Model para FeedGossip - Mapea JSON de Supabase RPC.
///
/// **Propósito:**
/// - DTO (Data Transfer Object) para el feed
/// - Mapea respuesta de `get_popular_feed` y `get_following_feed`
///
/// **JSON esperado de Supabase:**
/// ```json
/// {
///   "id": "uuid",
///   "subject": "string",
///   "content": "string",
///   "city_id": "string",
///   "created_at": "2024-01-01T00:00:00Z",
///   "likes": 100,
///   "comments": 20,
///   "shares": 5,
///   "published_as": "anonymous",
///   "created_by": "uuid" | null,
///   "image_url": "https://..." | null,
///   "score": 123.45,
///   "is_from_my_city": true,
///   "is_trending": false
/// }
/// ```
///
/// **Diferencias con GossipModel:**
/// - Campos en snake_case (vienen de SQL)
/// - Solo campos necesarios para el feed (no todos los de Gossip)
/// - Incluye metadata calculada (score, is_from_my_city, is_trending)
class FeedGossipModel {
  final String id;
  final String subject;
  final String content;
  final String cityId;
  final String createdAt; // ISO8601 string
  final int likes;
  final int comments;
  final int shares;
  final String publishedAs;
  final String? createdBy;
  final String? imageUrl;
  final double score;
  final bool isFromMyCity;
  final bool isTrending;

  const FeedGossipModel({
    required this.id,
    required this.subject,
    required this.content,
    required this.cityId,
    required this.createdAt,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.publishedAs,
    this.createdBy,
    this.imageUrl,
    required this.score,
    required this.isFromMyCity,
    required this.isTrending,
  });

  /// Deserializa desde JSON de Supabase RPC.
  ///
  /// **Throws:**
  /// - `FormatException`: Si el JSON tiene tipos incorrectos
  /// - `FormatException`: Si falta un campo requerido
  factory FeedGossipModel.fromJson(Map<String, dynamic> json) {
    try {
      return FeedGossipModel(
        id: json['id'] as String,
        subject: json['subject'] as String,
        content: json['content'] as String,
        cityId: json['city_id'] as String,
        createdAt: json['created_at'] as String,
        likes: json['likes'] as int,
        comments: json['comments'] as int,
        shares: json['shares'] as int,
        publishedAs: json['published_as'] as String,
        createdBy: json['created_by'] as String?,
        imageUrl: json['image_url'] as String?,
        score: (json['score'] as num).toDouble(),
        isFromMyCity: json['is_from_my_city'] as bool,
        isTrending: json['is_trending'] as bool,
      );
    } catch (e) {
      throw FormatException(
        'Error deserializando FeedGossipModel: $e\nJSON: $json',
      );
    }
  }

  /// Convierte a Entity del Domain Layer.
  ///
  /// **Conversiones:**
  /// - `createdAt`: String ISO8601 → DateTime
  /// - `score`: num → double
  /// - Resto: sin conversión
  FeedGossip toEntity() {
    return FeedGossip(
      id: id,
      subject: subject,
      content: content,
      cityId: cityId,
      createdAt: DateTime.parse(createdAt),
      likes: likes,
      comments: comments,
      shares: shares,
      publishedAs: publishedAs,
      createdBy: createdBy,
      imageUrl: imageUrl,
      score: score,
      isFromMyCity: isFromMyCity,
      isTrending: isTrending,
    );
  }

  /// Serializa a JSON (útil para debugging/testing).
  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'content': content,
        'city_id': cityId,
        'created_at': createdAt,
        'likes': likes,
        'comments': comments,
        'shares': shares,
        'published_as': publishedAs,
        'created_by': createdBy,
        'image_url': imageUrl,
        'score': score,
        'is_from_my_city': isFromMyCity,
        'is_trending': isTrending,
      };

  @override
  String toString() {
    return 'FeedGossipModel('
        'id: $id, '
        'subject: ${subject.substring(0, subject.length > 20 ? 20 : subject.length)}..., '
        'score: ${score.toStringAsFixed(2)}'
        ')';
  }
}
