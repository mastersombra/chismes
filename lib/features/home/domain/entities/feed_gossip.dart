import 'package:equatable/equatable.dart';

/// Gossip con metadata adicional para renderizar en el feed.
///
/// Esta entity extiende la información base del Gossip con datos
/// calculados por el algoritmo de ranking y flags para la UI.
///
/// **Diferencias con `Gossip` entity:**
/// - Incluye `score`: Puntuación del algoritmo de ranking
/// - Incluye `isFromMyCity`: Para mostrar/ocultar badge de ciudad
/// - Incluye `isTrending`: Para mostrar badge "Trending 🔥"
/// - Solo incluye campos necesarios para el feed (no todos los campos de Gossip)
///
/// **Uso:**
/// ```dart
/// // En GossipCard
/// if (!gossip.isFromMyCity) {
///   // Mostrar badge [Ciudad]
/// }
///
/// if (gossip.isTrending) {
///   // Mostrar badge "Trending 🔥"
/// }
/// ```
class FeedGossip extends Equatable {
  final String id;
  final String subject;
  final String content;
  final String cityId;
  final DateTime createdAt;

  // Contadores
  final int likes;
  final int comments;
  final int shares;

  // Autor
  final String publishedAs; // 'anonymous' o 'profile'
  final String? createdBy; // Nullable si es anónimo

  // Media
  final String? imageUrl;

  // Metadata del algoritmo
  /// Score calculado por el algoritmo de ranking (40/30/20/10)
  ///
  /// Componentes:
  /// - 40% Ciudad (local=100, trending=50, otras=20)
  /// - 30% Interacciones (likes*1 + comments*2 + shares*3)
  /// - 20% Velocity (interacciones / horas)
  /// - 10% Decay (penalización por antigüedad)
  final double score;

  /// Si el chisme es de la ciudad del usuario
  ///
  /// Usado para:
  /// - Mostrar/ocultar badge de ciudad en GossipCard
  /// - Si `false`, mostrar badge con nombre de ciudad
  final bool isFromMyCity;

  /// Si el chisme es trending (viral)
  ///
  /// Criterio (cualquiera):
  /// - likes > 1000
  /// - comments > 200
  /// - shares > 100
  ///
  /// Usado para:
  /// - Mostrar badge "Trending 🔥" en GossipCard
  final bool isTrending;

  const FeedGossip({
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

  @override
  List<Object?> get props => [
        id,
        subject,
        content,
        cityId,
        createdAt,
        likes,
        comments,
        shares,
        publishedAs,
        createdBy,
        imageUrl,
        score,
        isFromMyCity,
        isTrending,
      ];

  /// Número total de interacciones
  int get totalInteractions => likes + comments + shares;

  /// Si el chisme es anónimo
  bool get isAnonymous => publishedAs == 'anonymous';

  @override
  String toString() {
    return 'FeedGossip('
        'id: $id, '
        'subject: ${subject.substring(0, subject.length > 20 ? 20 : subject.length)}..., '
        'score: ${score.toStringAsFixed(2)}, '
        'likes: $likes, '
        'comments: $comments, '
        'shares: $shares, '
        'isFromMyCity: $isFromMyCity, '
        'isTrending: $isTrending'
        ')';
  }
}
