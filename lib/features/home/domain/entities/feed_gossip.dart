import 'package:equatable/equatable.dart';

import '../../../../core/social/gossip_author.dart';

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
/// Anillo de cercanía de un chisme respecto a la ubicación del usuario.
///
/// Lo calcula `get_popular_feed` comparando la ciudad/región/país del chisme
/// con los del usuario. `global` = otro país (entra por tendencia o relleno).
enum FeedProximity {
  city,
  region,
  country,
  global;

  /// Parsea el valor del servidor; desconocido o null → `global`.
  static FeedProximity fromString(String? value) {
    return FeedProximity.values.firstWhere(
      (p) => p.name == value,
      orElse: () => FeedProximity.global,
    );
  }
}

class FeedGossip extends Equatable {
  final String id;
  final String subject;
  final String content;
  final String cityId;

  /// Nombre de la ciudad del chisme (para la etiqueta "📍 Medellín")
  final String? cityName;
  final DateTime createdAt;

  // Contadores
  final int likes;
  final int comments;
  final int shares;

  // Autor
  final String publishedAs; // 'anonymous' o 'profile'
  final String? createdBy; // Nullable si es anónimo

  /// Autor visible (@usuario, nombre, foto). Solo en chismes con perfil;
  /// SIEMPRE null en los anónimos.
  final GossipAuthor? author;

  // Media
  final String? imageUrl;

  // Metadata del algoritmo
  /// Score del ranking (ver `get_popular_feed` en la migración 008):
  /// 40% cercanía + 25% popularidad + 20% velocity + 15% frescura
  /// (+ bonus si es tendencia). Pesos en la tabla `feed_settings`.
  final double score;

  /// Anillo de cercanía (ciudad, región, país, global)
  final FeedProximity proximity;

  /// Si el chisme es de la ciudad del usuario
  ///
  /// Puede ser `null` si el usuario no tiene ciudad configurada.
  ///
  /// Usado para:
  /// - Mostrar/ocultar badge de ciudad en GossipCard
  /// - Si `false`, mostrar badge con nombre de ciudad
  /// - Si `null`, no mostrar badge de ciudad
  final bool? isFromMyCity;

  /// Si el chisme es tendencia
  ///
  /// Criterio RELATIVO (servidor): interacciones/hora en el percentil 95 de
  /// las últimas 48 h, con un mínimo absoluto. Ver `feed_settings`.
  ///
  /// Usado para:
  /// - Mostrar badge "Trending 🔥" en GossipCard
  final bool isTrending;

  const FeedGossip({
    required this.id,
    required this.subject,
    required this.content,
    required this.cityId,
    this.cityName,
    required this.createdAt,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.publishedAs,
    this.createdBy,
    this.author,
    this.imageUrl,
    required this.score,
    this.proximity = FeedProximity.global,
    this.isFromMyCity, // Nullable: puede ser null si el usuario no tiene ciudad
    required this.isTrending,
  });

  @override
  List<Object?> get props => [
        id,
        subject,
        content,
        cityId,
        cityName,
        createdAt,
        likes,
        comments,
        shares,
        publishedAs,
        createdBy,
        author,
        imageUrl,
        score,
        proximity,
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
