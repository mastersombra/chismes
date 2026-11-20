import '../../domain/entities/moderation_item.dart';

/// Fila de `moderationQueueItems` tal como la devuelve `moderation-review`
/// (snakeCase, igual que la base)
class ModerationItemModel {
  final String id;
  final String gossipId;
  final String contentAuthorId;
  final String? authorUsername;
  final String? authorDisplayName;
  final String publishedAs;
  final String source;
  final List<String> reasons;
  final String priority;
  final int reportCount;
  final bool autoHidden;
  final String status;
  final String subject;
  final String content;
  final String? imagePreviewUrl;
  final String? imageUrl;
  final String? audioUrl;
  final String? audioQuarantinePath;
  final int interactions;
  final String contentCreatedAt;
  final String createdAt;
  final String? decidedAt;
  final String? decisionSeverity;
  final String? decisionReason;
  final String? decisionNote;

  const ModerationItemModel({
    required this.id,
    required this.gossipId,
    required this.contentAuthorId,
    this.authorUsername,
    this.authorDisplayName,
    required this.publishedAs,
    required this.source,
    required this.reasons,
    required this.priority,
    required this.reportCount,
    required this.autoHidden,
    required this.status,
    required this.subject,
    required this.content,
    this.imagePreviewUrl,
    this.imageUrl,
    this.audioUrl,
    this.audioQuarantinePath,
    required this.interactions,
    required this.contentCreatedAt,
    required this.createdAt,
    this.decidedAt,
    this.decisionSeverity,
    this.decisionReason,
    this.decisionNote,
  });

  factory ModerationItemModel.fromJson(Map<String, dynamic> json) {
    return ModerationItemModel(
      id: json['id'] as String,
      gossipId: json['gossip_id'] as String,
      contentAuthorId: json['content_author_id'] as String,
      authorUsername: json['author_username'] as String?,
      authorDisplayName: json['author_display_name'] as String?,
      publishedAs: json['published_as'] as String? ?? 'profile',
      source: json['source'] as String,
      reasons: (json['reasons'] as List<dynamic>? ?? const [])
          .map((r) => r.toString())
          .toList(),
      priority: json['priority'] as String? ?? 'normal',
      reportCount: (json['report_count'] as num?)?.toInt() ?? 0,
      autoHidden: json['auto_hidden'] as bool? ?? false,
      status: json['status'] as String,
      subject: json['subject'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imagePreviewUrl: json['image_preview_url'] as String?,
      imageUrl: json['image_url'] as String?,
      audioUrl: json['audio_url'] as String?,
      audioQuarantinePath: json['audio_quarantine_path'] as String?,
      interactions: (json['interactions'] as num?)?.toInt() ?? 0,
      contentCreatedAt: json['content_created_at'] as String,
      createdAt: json['created_at'] as String,
      decidedAt: json['decided_at'] as String?,
      decisionSeverity: json['decision_severity'] as String?,
      decisionReason: json['decision_reason'] as String?,
      decisionNote: json['decision_note'] as String?,
    );
  }

  ModerationItem toEntity() {
    return ModerationItem(
      id: id,
      gossipId: gossipId,
      authorId: contentAuthorId,
      authorUsername: authorUsername,
      authorDisplayName: authorDisplayName,
      publishedAnonymously: publishedAs == 'anonymous',
      source: ModerationSource.fromValue(source),
      reasons: reasons,
      highPriority: priority == 'high',
      reportCount: reportCount,
      autoHidden: autoHidden,
      status: ModerationQueueStatus.fromValue(status),
      subject: subject,
      content: content,
      imagePreviewUrl: imagePreviewUrl,
      imageUrl: imageUrl,
      hasAudio: audioUrl != null || audioQuarantinePath != null,
      interactions: interactions,
      contentCreatedAt: DateTime.parse(contentCreatedAt),
      queuedAt: DateTime.parse(createdAt),
      decidedAt: decidedAt != null ? DateTime.parse(decidedAt!) : null,
      decisionSeverity: ModerationSeverity.fromValue(decisionSeverity),
      decisionReason: decisionReason,
      decisionNote: decisionNote,
    );
  }
}
