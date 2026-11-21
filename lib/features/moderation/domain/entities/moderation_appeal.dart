import 'package:equatable/equatable.dart';

import 'account_status.dart';
import 'moderation_item.dart';

/// Apelación vista por el equipo de moderación: el contenido, la decisión
/// original y lo que escribió el usuario
class ModerationAppeal extends Equatable {
  final String id;
  final String queueId;
  final String gossipId;
  final String authorId;
  final String? authorUsername;
  final String? authorDisplayName;
  final bool publishedAnonymously;

  /// Lo que escribió el usuario
  final String message;
  final AppealStatus status;
  final DateTime createdAt;
  final DateTime? decidedAt;

  /// Nota interna de quien decidió la apelación
  final String? decisionNote;

  final String subject;
  final String content;

  // Decisión original (el rechazo apelado)
  final ModerationSource originalSource;
  final List<String> originalReasons;
  final int originalReportCount;
  final ModerationSeverity? originalSeverity;
  final String? originalReason;
  final String? originalNote;
  final DateTime? originalDecidedAt;

  /// Quién rechazó (para no decidir la propia, si se exige)
  final String? originalDecidedBy;

  ModerationAppeal({
    required this.id,
    required this.queueId,
    required this.gossipId,
    required this.authorId,
    this.authorUsername,
    this.authorDisplayName,
    required this.publishedAnonymously,
    required this.message,
    required this.status,
    required this.createdAt,
    this.decidedAt,
    this.decisionNote,
    required this.subject,
    required this.content,
    required this.originalSource,
    required List<String> originalReasons,
    required this.originalReportCount,
    this.originalSeverity,
    this.originalReason,
    this.originalNote,
    this.originalDecidedAt,
    this.originalDecidedBy,
  }) : originalReasons = List.unmodifiable(originalReasons);

  bool get isPending => status == AppealStatus.pending;

  /// display name > @username > null
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
        queueId,
        gossipId,
        authorId,
        authorUsername,
        authorDisplayName,
        publishedAnonymously,
        message,
        status,
        createdAt,
        decidedAt,
        decisionNote,
        subject,
        content,
        originalSource,
        originalReasons,
        originalReportCount,
        originalSeverity,
        originalReason,
        originalNote,
        originalDecidedAt,
        originalDecidedBy,
      ];
}

/// Decisión de un moderador sobre una apelación
class AppealDecision extends Equatable {
  final String appealId;

  /// true: anula la falta y republica el texto
  final bool accept;
  final String? note;

  const AppealDecision({required this.appealId, required this.accept, this.note});

  @override
  List<Object?> get props => [appealId, accept, note];
}
