import 'package:equatable/equatable.dart';
import '../../../../core/audit/auditable.dart';

enum PublishAs {
  anonymous('anonymous'),
  profile('profile');

  final String value;

  const PublishAs(this.value);
}

enum GossipStatus {
  draft('draft'),
  published('published'),
  hidden('hidden'),
  deleted('deleted');

  final String value;

  const GossipStatus(this.value);
}

enum ModerationStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  flagged('flagged');

  final String value;

  const ModerationStatus(this.value);
}

enum GossipVisibility {
  public('public'),
  private('private'),
  followers('followers');

  final String value;

  const GossipVisibility(this.value);
}

class Gossip extends Equatable implements Auditable {
  final String id;
  final String countryId;
  final String regionId;
  final String cityId;
  final String subject;
  final String content;

  /// URL del audio (nullable)
  /// Ver ADR-003: Decisión de usar String simple
  final String? audioUrl;

  /// URL de la imagen (nullable)
  /// Ver ADR-003: Decisión de usar String simple
  final String? imageUrl;

  /// URL del thumbnail de la imagen (nullable)
  ///
  /// Thumbnail optimizado de 200×200px (~30 KB) para feeds y listas.
  /// Si existe, debe usarse en lugar de imageUrl para reducir transferencia.
  /// La imagen completa (imageUrl) se usa solo al abrir el detalle.
  final String? thumbnailUrl;

  final PublishAs publishedAs;
  final GossipStatus status;
  final ModerationStatus moderationStatus;
  final int reportedCount;
  final int viewCount;
  final DateTime? deletedAt;
  final String? deletedBy;
  final GossipVisibility visibility;
  
  @override
  final DateTime createdAt;
  @override
  final String createdBy;
  @override
  final DateTime? modifiedAt;
  @override
  final String? modifiedBy;

  const Gossip({
    required this.id,
    required this.countryId,
    required this.regionId,
    required this.cityId,
    required this.subject,
    required this.content,
    this.audioUrl,
    this.imageUrl,
    this.thumbnailUrl,
    required this.publishedAs,
    required this.status,
    required this.moderationStatus,
    this.reportedCount = 0,
    this.viewCount = 0,
    this.deletedAt,
    this.deletedBy,
    required this.visibility,
    required this.createdAt,
    required this.createdBy,
    this.modifiedAt,
    this.modifiedBy,
  });

  @override
  List<Object?> get props => [
    id,
    countryId,
    regionId,
    cityId,
    subject,
    content,
    audioUrl,
    imageUrl,
    thumbnailUrl,
    publishedAs,
    status,
    moderationStatus,
    reportedCount,
    viewCount,
    deletedAt,
    deletedBy,
    visibility,
    createdAt,
    createdBy,
    modifiedAt,
    modifiedBy,
  ];
}
