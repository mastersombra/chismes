import 'dart:async';

import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/moderation/domain/entities/account_status.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_appeal.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:chismes/features/moderation/domain/entities/review_decision.dart';
import 'package:chismes/features/moderation/domain/repositories/account_status_repository.dart';
import 'package:chismes/features/moderation/domain/repositories/moderation_repository.dart';

/// Fixtures y fakes escritos a mano para sanciones y apelaciones (sin mockito
/// generado: no requieren build_runner).

AccountAppeal accountAppeal({
  String id = 'ap-1',
  AppealStatus status = AppealStatus.pending,
  String message = 'No era un insulto, era un chiste',
}) {
  return AccountAppeal(
    id: id,
    status: status,
    message: message,
    createdAt: DateTime.utc(2026, 11, 20, 10),
    decidedAt: status == AppealStatus.pending ? null : DateTime.utc(2026, 11, 20, 12),
  );
}

AccountRejection accountRejection({
  String queueId = 'q-1',
  String subject = 'Boda en el barrio',
  ModerationSeverity? severity = ModerationSeverity.medium,
  String? reason = 'harassment',
  bool overturned = false,
  int? points = 2,
  SanctionKind? sanction = SanctionKind.warning,
  bool canAppeal = true,
  AccountAppeal? appeal,
}) {
  return AccountRejection(
    queueId: queueId,
    gossipId: 'g-$queueId',
    subject: subject,
    content: 'Dicen que se casan el sábado',
    severity: severity,
    reason: reason,
    decidedAt: DateTime.utc(2026, 11, 19, 10),
    overturned: overturned,
    points: points,
    expiresAt: DateTime.utc(2027, 2, 17, 10),
    sanction: sanction,
    sanctionEndsAt: null,
    appealDeadline: DateTime.utc(2026, 12, 3, 10),
    canAppeal: canAppeal,
    appeal: appeal,
  );
}

AccountStatus accountStatus({
  AccountState state = AccountState.ok,
  DateTime? restrictedUntil,
  int activePoints = 0,
  InheritedStrikes? inherited,
  List<AccountRejection> rejections = const [],
}) {
  return AccountStatus(
    state: state,
    restrictedUntil: restrictedUntil,
    activePoints: activePoints,
    strikeCount: rejections.length,
    expiryDays: 90,
    appealWindowDays: 14,
    thresholds: const SanctionThresholds(restrictionShort: 3, restrictionLong: 6, suspension: 10),
    inherited: inherited,
    rejections: rejections,
  );
}

ModerationAppeal moderationAppeal({
  String id = 'ap-1',
  AppealStatus status = AppealStatus.pending,
  String subject = 'Boda en el barrio',
  String message = 'No era un insulto, era un chiste',
  bool publishedAnonymously = false,
  String? authorDisplayName = 'La Chismosa',
  String? authorUsername = 'chismosa',
  ModerationSeverity? originalSeverity = ModerationSeverity.high,
  String? originalReason = 'harassment',
  String? originalNote = 'nota del rechazo',
  List<String> originalReasons = const ['spam'],
  int originalReportCount = 3,
  String? decisionNote,
}) {
  final decided = status != AppealStatus.pending;
  return ModerationAppeal(
    id: id,
    queueId: 'q-$id',
    gossipId: 'g-$id',
    authorId: 'author-1',
    authorUsername: authorUsername,
    authorDisplayName: authorDisplayName,
    publishedAnonymously: publishedAnonymously,
    message: message,
    status: status,
    createdAt: DateTime.utc(2026, 11, 20, 10),
    decidedAt: decided ? DateTime.utc(2026, 11, 20, 12) : null,
    decisionNote: decisionNote,
    subject: subject,
    content: 'Dicen que se casan el sábado',
    originalSource: ModerationSource.reports,
    originalReasons: originalReasons,
    originalReportCount: originalReportCount,
    originalSeverity: originalSeverity,
    originalReason: originalReason,
    originalNote: originalNote,
    originalDecidedAt: DateTime.utc(2026, 11, 19, 10),
    originalDecidedBy: 'mod-1',
  );
}

/// [AccountStatusRepository] programable
class FakeAccountStatusRepository implements AccountStatusRepository {
  /// Respuestas de getStatus en orden (la última se repite)
  final List<Result<Failure, AccountStatus>> statusResults = [];
  Result<Failure, AccountAppeal> appealResult = Result.success(accountAppeal());

  /// Si se asigna, getStatus espera a que se complete (estado de carga)
  Completer<void>? statusGate;

  int statusCalls = 0;
  final List<(String, String)> appeals = [];

  @override
  Future<Result<Failure, AccountStatus>> getStatus() async {
    final gate = statusGate;
    if (gate != null) await gate.future;
    final index = statusCalls < statusResults.length ? statusCalls : statusResults.length - 1;
    statusCalls++;
    return statusResults[index];
  }

  @override
  Future<Result<Failure, AccountAppeal>> submitAppeal({
    required String queueId,
    required String message,
  }) async {
    appeals.add((queueId, message));
    return appealResult;
  }
}

/// [ModerationRepository] programable (cola + apelaciones)
class FakeModerationRepository implements ModerationRepository {
  /// Respuesta por (estado, offset); si no hay, lista vacía
  final Map<(AppealStatus, int), Result<Failure, List<ModerationAppeal>>> appealPages = {};
  final List<(AppealStatus, int)> appealCalls = [];

  Result<Failure, void> decideAppealResult = Result.success(null);
  final List<AppealDecision> appealDecisions = [];

  /// Cola: respuesta por estado (para el panel)
  final Map<ModerationQueueStatus, Result<Failure, List<ModerationItem>>> queue = {};
  final List<ModerationQueueStatus> queueCalls = [];

  @override
  Future<Result<Failure, List<ModerationAppeal>>> getAppeals({
    required AppealStatus status,
    required int limit,
    int offset = 0,
  }) async {
    appealCalls.add((status, offset));
    return appealPages[(status, offset)] ?? Result.success(const []);
  }

  @override
  Future<Result<Failure, void>> decideAppeal(AppealDecision decision) async {
    appealDecisions.add(decision);
    return decideAppealResult;
  }

  @override
  Future<Result<Failure, List<ModerationItem>>> getQueue({
    required ModerationQueueStatus status,
    required int limit,
    int offset = 0,
  }) async {
    queueCalls.add(status);
    return queue[status] ?? Result.success(const []);
  }

  @override
  Future<Result<Failure, void>> decide(ReviewDecision decision) async => Result.success(null);
}
