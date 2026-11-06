import '../../../gossip/domain/entities/gossip.dart';
import '../../domain/entities/feed_gossip.dart';

/// Adaptador de FeedGossip a Gossip.
///
/// **Propósito:**
/// GossipCard espera un `Gossip` completo, pero en el feed tenemos `FeedGossip`
/// (una versión simplificada). Este helper convierte FeedGossip → Gossip
/// con valores por defecto para campos faltantes.
///
/// **Uso:**
/// ```dart
/// GossipCard(
///   gossip: FeedGossipAdapter.toGossip(feedGossip),
/// )
/// ```
class FeedGossipAdapter {
  /// Convierte FeedGossip a Gossip.
  ///
  /// **Campos mapeados:**
  /// - id, subject, content, cityId → directo
  /// - createdAt, createdBy, imageUrl → directo
  /// - publishedAs → mapea 'anonymous'/'profile' a enum
  ///
  /// **Campos con valores por defecto:**
  /// - countryId, regionId → 'unknown' (no están en FeedGossip)
  /// - status → published
  /// - moderationStatus → approved
  /// - todos los contadores excepto likes/comments → 0
  /// - visibility → public
  static Gossip toGossip(FeedGossip feedGossip) {
    return Gossip(
      id: feedGossip.id,
      countryId: 'unknown', // No disponible en FeedGossip
      regionId: 'unknown', // No disponible en FeedGossip
      cityId: feedGossip.cityId,
      subject: feedGossip.subject,
      content: feedGossip.content,
      imageUrl: feedGossip.imageUrl,
      publishedAs: _mapPublishedAs(feedGossip.publishedAs),
      status: GossipStatus.published,
      moderationStatus: ModerationStatus.approved,
      reportedCount: 0,
      viewCount: 0,
      visibility: GossipVisibility.public,
      createdAt: feedGossip.createdAt,
      createdBy: feedGossip.createdBy ?? 'anonymous',
    );
  }

  /// Mapea string de publishedAs a enum.
  static PublishAs _mapPublishedAs(String value) {
    return value == 'anonymous' ? PublishAs.anonymous : PublishAs.profile;
  }
}
