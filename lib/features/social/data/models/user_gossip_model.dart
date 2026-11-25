import '../../../../core/social/gossip_author.dart';
import '../../../gossip/domain/entities/gossip.dart';

/// Chisme de `get_user_gossips` (mismo JSON que los feeds del Home).
///
/// Son siempre chismes con perfil, publicados y aprobados: el JSON no trae
/// estado ni visibilidad, así que se completan con esos valores.
class UserGossipModel {
  final String id;
  final String subject;
  final String content;
  final String? countryId;
  final String? regionId;
  final String cityId;
  final String createdAt;
  final String publishedAs;
  final String? createdBy;
  final String? authorUsername;
  final String? authorDisplayName;
  final String? authorAvatarUrl;
  final String? imageUrl;

  const UserGossipModel({
    required this.id,
    required this.subject,
    required this.content,
    this.countryId,
    this.regionId,
    required this.cityId,
    required this.createdAt,
    required this.publishedAs,
    this.createdBy,
    this.authorUsername,
    this.authorDisplayName,
    this.authorAvatarUrl,
    this.imageUrl,
  });

  /// Lanza [FormatException] si falta un campo requerido o tiene otro tipo
  factory UserGossipModel.fromJson(Map<String, dynamic> json) {
    try {
      return UserGossipModel(
        id: json['id'] as String,
        subject: json['subject'] as String,
        content: json['content'] as String,
        countryId: json['country_id'] as String?,
        regionId: json['region_id'] as String?,
        cityId: json['city_id'] as String,
        createdAt: json['created_at'] as String,
        publishedAs: json['published_as'] as String,
        createdBy: json['created_by'] as String?,
        authorUsername: json['author_username'] as String?,
        authorDisplayName: json['author_display_name'] as String?,
        authorAvatarUrl: json['author_avatar_url'] as String?,
        imageUrl: json['image_url'] as String?,
      );
    } catch (e) {
      throw FormatException('Error deserializando UserGossipModel: $e');
    }
  }

  Gossip toEntity() => Gossip(
        id: id,
        countryId: countryId ?? 'unknown',
        regionId: regionId ?? 'unknown',
        cityId: cityId,
        subject: subject,
        content: content,
        imageUrl: imageUrl,
        publishedAs:
            publishedAs == 'anonymous' ? PublishAs.anonymous : PublishAs.profile,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        visibility: GossipVisibility.public,
        createdAt: DateTime.parse(createdAt),
        createdBy: createdBy,
        author: GossipAuthor.maybe(
          publishedAs: publishedAs,
          createdBy: createdBy,
          username: authorUsername,
          displayName: authorDisplayName,
          avatarUrl: authorAvatarUrl,
        ),
      );
}
