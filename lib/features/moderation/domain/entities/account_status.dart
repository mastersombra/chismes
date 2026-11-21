import 'package:equatable/equatable.dart';

import 'moderation_item.dart';

/// Estado de la cuenta frente a la moderación (`015_sanctions.sql`)
enum AccountState {
  /// Puede publicar y reportar (puede tener advertencias)
  ok('ok'),

  /// No puede publicar ni reportar hasta [AccountStatus.restrictedUntil]
  restricted('restricted'),

  /// No puede publicar ni reportar hasta que una apelación lo levante
  suspended('suspended');

  const AccountState(this.value);

  final String value;

  static AccountState fromValue(String? value) =>
      values.firstWhere((s) => s.value == value, orElse: () => ok);
}

/// Sanción que generó una falta (según los puntos vigentes en ese momento)
enum SanctionKind {
  warning('warning'),
  restriction('restriction'),
  suspension('suspension');

  const SanctionKind(this.value);

  final String value;

  static SanctionKind? fromValue(String? value) {
    for (final kind in values) {
      if (kind.value == value) return kind;
    }
    return null;
  }
}

/// Estado de una apelación
enum AppealStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected');

  const AppealStatus(this.value);

  final String value;

  static AppealStatus fromValue(String? value) =>
      values.firstWhere((s) => s.value == value, orElse: () => pending);
}

/// Apelación del usuario sobre uno de sus rechazos
class AccountAppeal extends Equatable {
  final String id;
  final AppealStatus status;
  final String message;
  final DateTime createdAt;
  final DateTime? decidedAt;

  const AccountAppeal({
    required this.id,
    required this.status,
    required this.message,
    required this.createdAt,
    this.decidedAt,
  });

  @override
  List<Object?> get props => [id, status, message, createdAt, decidedAt];
}

/// Contenido propio rechazado por un moderador (una falta, salvo que se
/// haya anulado por apelación)
class AccountRejection extends Equatable {
  final String queueId;
  final String gossipId;
  final String subject;
  final String content;
  final ModerationSeverity? severity;

  /// Código del motivo (`RejectReason`) o texto libre
  final String? reason;
  final DateTime decidedAt;

  /// Anulada por una apelación aceptada: no cuenta
  final bool overturned;

  /// Puntos de la falta (null si se anuló)
  final int? points;

  /// Cuándo vencen sus puntos
  final DateTime expiresAt;

  /// Sanción que generó (null si se anuló)
  final SanctionKind? sanction;

  /// Fin de la restricción que generó (null: advertencia o suspensión)
  final DateTime? sanctionEndsAt;
  final DateTime appealDeadline;
  final bool canAppeal;
  final AccountAppeal? appeal;

  const AccountRejection({
    required this.queueId,
    required this.gossipId,
    required this.subject,
    required this.content,
    this.severity,
    this.reason,
    required this.decidedAt,
    required this.overturned,
    this.points,
    required this.expiresAt,
    this.sanction,
    this.sanctionEndsAt,
    required this.appealDeadline,
    required this.canAppeal,
    this.appeal,
  });

  @override
  List<Object?> get props => [
        queueId,
        gossipId,
        subject,
        content,
        severity,
        reason,
        decidedAt,
        overturned,
        points,
        expiresAt,
        sanction,
        sanctionEndsAt,
        appealDeadline,
        canAppeal,
        appeal,
      ];
}

/// Faltas heredadas de una cuenta anterior eliminada con el mismo email
class InheritedStrikes extends Equatable {
  final int points;
  final DateTime occurredAt;
  final DateTime expiresAt;
  final SanctionKind? sanction;

  const InheritedStrikes({
    required this.points,
    required this.occurredAt,
    required this.expiresAt,
    this.sanction,
  });

  @override
  List<Object?> get props => [points, occurredAt, expiresAt, sanction];
}

/// Puntos desde los que se aplica cada sanción
class SanctionThresholds extends Equatable {
  final int restrictionShort;
  final int restrictionLong;
  final int suspension;

  const SanctionThresholds({
    required this.restrictionShort,
    required this.restrictionLong,
    required this.suspension,
  });

  @override
  List<Object?> get props => [restrictionShort, restrictionLong, suspension];
}

/// Lo que el usuario ve en "Estado de la cuenta"
class AccountStatus extends Equatable {
  final AccountState state;
  final DateTime? restrictedUntil;
  final int activePoints;
  final int strikeCount;
  final int expiryDays;
  final int appealWindowDays;
  final SanctionThresholds thresholds;
  final InheritedStrikes? inherited;
  final List<AccountRejection> rejections;

  AccountStatus({
    required this.state,
    this.restrictedUntil,
    required this.activePoints,
    required this.strikeCount,
    required this.expiryDays,
    required this.appealWindowDays,
    required this.thresholds,
    this.inherited,
    required List<AccountRejection> rejections,
  }) : rejections = List.unmodifiable(rejections);

  bool get isBlocked => state != AccountState.ok;

  /// Hay una apelación esperando respuesta
  bool get hasPendingAppeal =>
      rejections.any((r) => r.appeal?.status == AppealStatus.pending);

  @override
  List<Object?> get props => [
        state,
        restrictedUntil,
        activePoints,
        strikeCount,
        expiryDays,
        appealWindowDays,
        thresholds,
        inherited,
        rejections,
      ];
}
