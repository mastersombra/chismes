import '../../domain/entities/account_status.dart';
import '../../domain/entities/moderation_item.dart';

/// `status` de `account-status` (snake_case, igual que `get_account_status`)
///
/// Se parsea directo a la entidad: es solo lectura y no se cachea.
class AccountStatusModel {
  final Map<String, dynamic> json;

  const AccountStatusModel(this.json);

  AccountStatus toEntity() {
    final thresholds = json['thresholds'] as Map<String, dynamic>? ?? const {};
    final inherited = json['inherited'] as Map<String, dynamic>?;
    final rejections = json['rejections'] as List<dynamic>? ?? const [];

    return AccountStatus(
      state: AccountState.fromValue(json['state'] as String?),
      restrictedUntil: _date(json['restricted_until']),
      activePoints: _int(json['active_points']),
      strikeCount: _int(json['strike_count']),
      expiryDays: _int(json['expiry_days'], 90),
      appealWindowDays: _int(json['appeal_window_days'], 14),
      thresholds: SanctionThresholds(
        restrictionShort: _int(thresholds['restriction_short'], 3),
        restrictionLong: _int(thresholds['restriction_long'], 6),
        suspension: _int(thresholds['suspension'], 10),
      ),
      inherited: inherited == null
          ? null
          : InheritedStrikes(
              points: _int(inherited['points']),
              occurredAt: DateTime.parse(inherited['occurred_at'] as String),
              expiresAt: DateTime.parse(inherited['expires_at'] as String),
              sanction: SanctionKind.fromValue(inherited['sanction'] as String?),
            ),
      rejections: rejections
          .map((r) => rejectionFromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  static AccountRejection rejectionFromJson(Map<String, dynamic> json) {
    final appeal = json['appeal'] as Map<String, dynamic>?;
    return AccountRejection(
      queueId: json['queue_id'] as String,
      gossipId: json['gossip_id'] as String,
      subject: json['subject'] as String? ?? '',
      content: json['content'] as String? ?? '',
      severity: ModerationSeverity.fromValue(json['severity'] as String?),
      reason: json['reason'] as String?,
      decidedAt: DateTime.parse(json['decided_at'] as String),
      overturned: json['overturned'] as bool? ?? false,
      points: (json['points'] as num?)?.toInt(),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      sanction: SanctionKind.fromValue(json['sanction'] as String?),
      sanctionEndsAt: _date(json['sanction_ends_at']),
      appealDeadline: DateTime.parse(json['appeal_deadline'] as String),
      canAppeal: json['can_appeal'] as bool? ?? false,
      appeal: appeal == null ? null : appealFromJson(appeal),
    );
  }

  static AccountAppeal appealFromJson(Map<String, dynamic> json) {
    return AccountAppeal(
      id: json['id'] as String,
      status: AppealStatus.fromValue(json['status'] as String?),
      message: json['message'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      decidedAt: _date(json['decided_at']),
    );
  }

  static int _int(dynamic value, [int fallback = 0]) => (value as num?)?.toInt() ?? fallback;

  static DateTime? _date(dynamic value) => value is String ? DateTime.parse(value) : null;
}
