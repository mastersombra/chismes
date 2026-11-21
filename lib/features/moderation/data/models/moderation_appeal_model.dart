import '../../domain/entities/account_status.dart';
import '../../domain/entities/moderation_appeal.dart';
import '../../domain/entities/moderation_item.dart';

/// Fila de `moderation_appeal_items` tal como la devuelve `moderation-review`
/// (snake_case, igual que la base)
class ModerationAppealModel {
  final String id;
  final String queueId;
  final String gossipId;
  final String userId;
  final String? authorUsername;
  final String? authorDisplayName;
  final String publishedAs;
  final String message;
  final String status;
  final String createdAt;
  final String? decidedAt;
  final String? decisionNote;
  final String subject;
  final String content;
  final String originalSource;
  final List<String> originalReasons;
  final int originalReportCount;
  final String? originalSeverity;
  final String? originalReason;
  final String? originalNote;
  final String? originalDecidedAt;
  final String? originalDecidedBy;

  const ModerationAppealModel({
    required this.id,
    required this.queueId,
    required this.gossipId,
    required this.userId,
    this.authorUsername,
    this.authorDisplayName,
    required this.publishedAs,
    required this.message,
    required this.status,
    required this.createdAt,
    this.decidedAt,
    this.decisionNote,
    required this.subject,
    required this.content,
    required this.originalSource,
    required this.originalReasons,
    required this.originalReportCount,
    this.originalSeverity,
    this.originalReason,
    this.originalNote,
    this.originalDecidedAt,
    this.originalDecidedBy,
  });

  factory ModerationAppealModel.fromJson(Map<String, dynamic> json) {
    return ModerationAppealModel(
      id: json['id'] as String,
      queueId: json['queue_id'] as String,
      gossipId: json['gossip_id'] as String,
      userId: json['user_id'] as String,
      authorUsername: json['author_username'] as String?,
      authorDisplayName: json['author_display_name'] as String?,
      publishedAs: json['published_as'] as String? ?? 'profile',
      message: json['message'] as String? ?? '',
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
      decidedAt: json['decided_at'] as String?,
      decisionNote: json['decision_note'] as String?,
      subject: json['subject'] as String? ?? '',
      content: json['content'] as String? ?? '',
      originalSource: json['original_source'] as String? ?? 'reports',
      originalReasons: (json['original_reasons'] as List<dynamic>? ?? const [])
          .map((r) => r.toString())
          .toList(),
      originalReportCount: (json['original_report_count'] as num?)?.toInt() ?? 0,
      originalSeverity: json['original_severity'] as String?,
      originalReason: json['original_reason'] as String?,
      originalNote: json['original_note'] as String?,
      originalDecidedAt: json['original_decided_at'] as String?,
      originalDecidedBy: json['original_decided_by'] as String?,
    );
  }

  ModerationAppeal toEntity() {
    return ModerationAppeal(
      id: id,
      queueId: queueId,
      gossipId: gossipId,
      authorId: userId,
      authorUsername: authorUsername,
      authorDisplayName: authorDisplayName,
      publishedAnonymously: publishedAs == 'anonymous',
      message: message,
      status: AppealStatus.fromValue(status),
      createdAt: DateTime.parse(createdAt),
      decidedAt: decidedAt != null ? DateTime.parse(decidedAt!) : null,
      decisionNote: decisionNote,
      subject: subject,
      content: content,
      originalSource: ModerationSource.fromValue(originalSource),
      originalReasons: originalReasons,
      originalReportCount: originalReportCount,
      originalSeverity: ModerationSeverity.fromValue(originalSeverity),
      originalReason: originalReason,
      originalNote: originalNote,
      originalDecidedAt: originalDecidedAt != null ? DateTime.parse(originalDecidedAt!) : null,
      originalDecidedBy: originalDecidedBy,
    );
  }
}
