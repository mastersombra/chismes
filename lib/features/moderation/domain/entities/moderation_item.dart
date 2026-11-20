import 'package:equatable/equatable.dart';

/// Estado de una entrada de la cola de revisión
enum ModerationQueueStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected');

  const ModerationQueueStatus(this.value);

  /// Valor en la base / API (`moderation_queue.status`)
  final String value;

  static ModerationQueueStatus fromValue(String value) =>
      values.firstWhere((s) => s.value == value, orElse: () => pending);
}

/// Gravedad de un rechazo (base de las sanciones futuras)
enum ModerationSeverity {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const ModerationSeverity(this.value);

  final String value;

  static ModerationSeverity? fromValue(String? value) {
    for (final severity in values) {
      if (severity.value == value) return severity;
    }
    return null;
  }
}

/// Por qué el contenido llegó a la cola
enum ModerationSource {
  /// La IA o las reglas dijeron "revisar"
  aiReview('ai_review'),

  /// Sin veredicto automático (IA o reglas no disponibles)
  aiUnavailable('ai_unavailable'),

  /// Llegó al umbral de reportes de usuarios
  reports('reports');

  const ModerationSource(this.value);

  final String value;

  static ModerationSource fromValue(String value) =>
      values.firstWhere((s) => s.value == value, orElse: () => aiReview);
}

/// Contenido en la cola de revisión humana (hoy: un chisme)
///
/// Incluye el autor REAL aunque se haya publicado como anónimo: solo lo ve
/// el equipo de moderación (`moderation-review`).
class ModerationItem extends Equatable {
  /// Id de la entrada en la cola (`moderation_queue.id`)
  final String id;
  final String gossipId;
  final String authorId;
  final String? authorUsername;
  final String? authorDisplayName;
  final bool publishedAnonymously;

  final ModerationSource source;

  /// Códigos de razón (`term:x`, `ai_score:x`, `potential_spam`, motivos de
  /// reporte...). La UI los traduce.
  final List<String> reasons;
  final bool highPriority;
  final int reportCount;

  /// Los reportes lo ocultaron automáticamente (aprobar lo restaura)
  final bool autoHidden;
  final ModerationQueueStatus status;

  final String subject;
  final String content;

  /// URL firmada (5 min) de la imagen en cuarentena, si está pendiente
  final String? imagePreviewUrl;

  /// URL pública de la imagen, si el chisme ya estaba publicado
  final String? imageUrl;
  final bool hasAudio;
  final int interactions;

  /// Cuándo se creó el contenido
  final DateTime contentCreatedAt;

  /// Cuándo entró a la cola
  final DateTime queuedAt;

  final DateTime? decidedAt;
  final ModerationSeverity? decisionSeverity;
  final String? decisionReason;
  final String? decisionNote;

  ModerationItem({
    required this.id,
    required this.gossipId,
    required this.authorId,
    this.authorUsername,
    this.authorDisplayName,
    required this.publishedAnonymously,
    required this.source,
    required List<String> reasons,
    required this.highPriority,
    required this.reportCount,
    required this.autoHidden,
    required this.status,
    required this.subject,
    required this.content,
    this.imagePreviewUrl,
    this.imageUrl,
    required this.hasAudio,
    required this.interactions,
    required this.contentCreatedAt,
    required this.queuedAt,
    this.decidedAt,
    this.decisionSeverity,
    this.decisionReason,
    this.decisionNote,
  }) : reasons = List.unmodifiable(reasons);

  bool get isPending => status == ModerationQueueStatus.pending;

  /// Imagen a mostrar: la de cuarentena (pendiente) o la pública
  String? get displayImageUrl => imagePreviewUrl ?? imageUrl;

  /// Nombre del autor para el equipo: display name > @username > null
  String? get authorName {
    if (authorDisplayName != null && authorDisplayName!.isNotEmpty) {
      return authorDisplayName;
    }
    if (authorUsername != null && authorUsername!.isNotEmpty) {
      return '@$authorUsername';
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        gossipId,
        authorId,
        authorUsername,
        authorDisplayName,
        publishedAnonymously,
        source,
        reasons,
        highPriority,
        reportCount,
        autoHidden,
        status,
        subject,
        content,
        imagePreviewUrl,
        imageUrl,
        hasAudio,
        interactions,
        contentCreatedAt,
        queuedAt,
        decidedAt,
        decisionSeverity,
        decisionReason,
        decisionNote,
      ];
}
