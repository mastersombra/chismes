import 'package:chismes/features/moderation/data/models/account_status_model.dart';
import 'package:chismes/features/moderation/data/models/moderation_appeal_model.dart';
import 'package:chismes/features/moderation/domain/entities/account_status.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../sanctions_json_fixtures.dart';

void main() {
  group('AccountStatusModel', () {
    test('parsea estado, umbrales, rechazos y apelación', () {
      // Arrange
      final json = accountStatusJson(rejections: [
        rejectionJson(appeal: appealJson(status: 'accepted', decidedAt: '2026-11-21T10:00:00Z')),
      ]);

      // Act
      final status = AccountStatusModel(json).toEntity();

      // Assert
      expect(status.state, AccountState.restricted);
      expect(status.restrictedUntil, DateTime.parse('2026-11-22T10:00:00Z'));
      expect(status.activePoints, 4);
      expect(status.strikeCount, 1);
      expect(status.expiryDays, 90);
      expect(status.appealWindowDays, 14);
      expect(status.thresholds,
          const SanctionThresholds(restrictionShort: 3, restrictionLong: 6, suspension: 10));
      expect(status.inherited, isNull);
      expect(status.isBlocked, isTrue);
      final r = status.rejections.single;
      expect(r.queueId, 'q-1');
      expect(r.severity, ModerationSeverity.high);
      expect(r.reason, 'harassment');
      expect(r.points, 4);
      expect(r.sanction, SanctionKind.restriction);
      expect(r.sanctionEndsAt, DateTime.parse('2026-11-20T10:00:00Z'));
      expect(r.canAppeal, isTrue);
      expect(r.appeal!.status, AppealStatus.accepted);
      expect(r.appeal!.decidedAt, DateTime.parse('2026-11-21T10:00:00Z'));
      expect(status.hasPendingAppeal, isFalse);
    });

    test('heredadas y apelación pendiente', () {
      final status = AccountStatusModel(accountStatusJson(
        state: 'suspended',
        restrictedUntil: null,
        inherited: {
          'points': 6,
          'occurred_at': '2026-10-01T00:00:00Z',
          'expires_at': '2026-12-30T00:00:00Z',
          'sanction': 'suspension',
        },
        rejections: [rejectionJson(appeal: appealJson())],
      )).toEntity();

      expect(status.state, AccountState.suspended);
      expect(status.restrictedUntil, isNull);
      expect(status.inherited!.points, 6);
      expect(status.inherited!.sanction, SanctionKind.suspension);
      expect(status.inherited!.expiresAt, DateTime.parse('2026-12-30T00:00:00Z'));
      expect(status.hasPendingAppeal, isTrue);
    });

    test('rechazo anulado: sin puntos ni sanción', () {
      final r = AccountStatusModel.rejectionFromJson(rejectionJson(overturned: true, canAppeal: false));

      expect(r.overturned, isTrue);
      expect(r.points, isNull);
      expect(r.sanction, isNull);
      expect(r.sanctionEndsAt, isNull);
      expect(r.appeal, isNull);
    });

    test('valores por defecto con JSON mínimo', () {
      final status = AccountStatusModel(const {}).toEntity();

      expect(status.state, AccountState.ok);
      expect(status.activePoints, 0);
      expect(status.expiryDays, 90);
      expect(status.appealWindowDays, 14);
      expect(status.thresholds.restrictionShort, 3);
      expect(status.thresholds.restrictionLong, 6);
      expect(status.thresholds.suspension, 10);
      expect(status.rejections, isEmpty);
      expect(status.isBlocked, isFalse);
    });

    test('rechazo con campos opcionales ausentes usa defaults', () {
      final r = AccountStatusModel.rejectionFromJson({
        'queue_id': 'q-9',
        'gossip_id': 'g-9',
        'decided_at': '2026-11-19T10:00:00Z',
        'expires_at': '2027-02-17T10:00:00Z',
        'appeal_deadline': '2026-12-03T10:00:00Z',
      });

      expect(r.subject, '');
      expect(r.content, '');
      expect(r.severity, isNull);
      expect(r.overturned, isFalse);
      expect(r.canAppeal, isFalse);
      expect(AccountStatusModel.appealFromJson({'id': 'a', 'created_at': '2026-11-20T10:00:00Z'}).message, '');
    });

    test('enums con valores desconocidos', () {
      expect(AccountState.fromValue('banned'), AccountState.ok);
      expect(AccountState.fromValue(null), AccountState.ok);
      expect(SanctionKind.fromValue('x'), isNull);
      expect(AppealStatus.fromValue('x'), AppealStatus.pending);
    });
  });

  group('ModerationAppealModel', () {
    test('fromJson + toEntity con todos los campos', () {
      final appeal = ModerationAppealModel.fromJson(moderationAppealJson(status: 'accepted')).toEntity();

      expect(appeal.id, 'ap-1');
      expect(appeal.queueId, 'q-1');
      expect(appeal.gossipId, 'g-1');
      expect(appeal.authorId, 'u-1');
      expect(appeal.authorName, 'Pepito');
      expect(appeal.publishedAnonymously, isTrue);
      expect(appeal.status, AppealStatus.accepted);
      expect(appeal.isPending, isFalse);
      expect(appeal.decidedAt, DateTime.parse('2026-11-21T10:00:00Z'));
      expect(appeal.decisionNote, 'tiene razón');
      expect(appeal.originalSource, ModerationSource.reports);
      expect(appeal.originalReasons, ['harassment', 'spam']);
      expect(appeal.originalReportCount, 3);
      expect(appeal.originalSeverity, ModerationSeverity.high);
      expect(appeal.originalReason, 'harassment');
      expect(appeal.originalNote, 'nota interna');
      expect(appeal.originalDecidedAt, DateTime.parse('2026-11-19T10:00:00Z'));
      expect(appeal.originalDecidedBy, 'mod-1');
    });

    test('defaults: perfil, sin razones, pendiente', () {
      final appeal = ModerationAppealModel.fromJson({
        'id': 'ap-2',
        'queue_id': 'q-2',
        'gossip_id': 'g-2',
        'user_id': 'u-2',
        'status': 'pending',
        'created_at': '2026-11-20T10:00:00Z',
      }).toEntity();

      expect(appeal.publishedAnonymously, isFalse);
      expect(appeal.message, '');
      expect(appeal.subject, '');
      expect(appeal.originalSource, ModerationSource.reports);
      expect(appeal.originalReasons, isEmpty);
      expect(appeal.originalReportCount, 0);
      expect(appeal.originalSeverity, isNull);
      expect(appeal.originalDecidedAt, isNull);
      expect(appeal.decidedAt, isNull);
      expect(appeal.isPending, isTrue);
      expect(appeal.authorName, isNull);
    });

    test('authorName usa @username sin display name', () {
      final json = moderationAppealJson()..['author_display_name'] = '';
      expect(ModerationAppealModel.fromJson(json).toEntity().authorName, '@pepito');
    });

    test('igualdad por valor', () {
      final a = ModerationAppealModel.fromJson(moderationAppealJson()).toEntity();
      final b = ModerationAppealModel.fromJson(moderationAppealJson()).toEntity();
      expect(a, b);
    });
  });
}
