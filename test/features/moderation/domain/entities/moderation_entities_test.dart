import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:chismes/features/moderation/domain/entities/review_decision.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../moderation_fixtures.dart';

void main() {
  group('enums fromValue', () {
    test('ModerationQueueStatus: valores conocidos y fallback a pending', () {
      expect(ModerationQueueStatus.fromValue('approved'), ModerationQueueStatus.approved);
      expect(ModerationQueueStatus.fromValue('rejected'), ModerationQueueStatus.rejected);
      expect(ModerationQueueStatus.fromValue('raro'), ModerationQueueStatus.pending);
    });

    test('ModerationSource: valores del CHECK y fallback', () {
      expect(ModerationSource.fromValue('ai_unavailable'), ModerationSource.aiUnavailable);
      expect(ModerationSource.fromValue('reports'), ModerationSource.reports);
      expect(ModerationSource.fromValue('otro'), ModerationSource.aiReview);
    });

    test('ModerationSeverity y RejectReason: null si no existe', () {
      expect(ModerationSeverity.fromValue('critical'), ModerationSeverity.critical);
      expect(ModerationSeverity.fromValue(null), isNull);
      expect(ModerationSeverity.fromValue('extrema'), isNull);
      expect(RejectReason.fromValue('sexual_content'), RejectReason.sexualContent);
      expect(RejectReason.fromValue('texto libre'), isNull);
    });
  });

  group('ModerationItem', () {
    test('authorName: display name > @username > null', () {
      expect(moderationItem().authorName, 'La Chismosa');
      expect(moderationItem(authorDisplayName: '').authorName, '@chismosa');
      expect(moderationItem(authorDisplayName: null, authorUsername: null).authorName, isNull);
    });

    test('displayImageUrl: prefiere la de cuarentena (pendiente)', () {
      expect(moderationItem(imagePreviewUrl: 'signed', imageUrl: 'public').displayImageUrl, 'signed');
      expect(moderationItem(imageUrl: 'public').displayImageUrl, 'public');
      expect(moderationItem().displayImageUrl, isNull);
    });

    test('isPending y reasons inmutables', () {
      expect(moderationItem().isPending, isTrue);
      expect(moderationItem(status: ModerationQueueStatus.rejected).isPending, isFalse);
      expect(() => moderationItem().reasons.add('x'), throwsUnsupportedError);
    });

    test('igualdad por valor', () {
      expect(moderationItem(), moderationItem());
      expect(moderationItem(), isNot(moderationItem(id: 'q-2')));
    });
  });

  group('ReviewDecision', () {
    test('approve no lleva gravedad ni motivo', () {
      const decision = ReviewDecision.approve(queueId: 'q-1', note: 'ok');
      expect(decision.approve, isTrue);
      expect(decision.severity, isNull);
      expect(decision.reason, isNull);
      expect(decision.note, 'ok');
    });

    test('reject lleva gravedad', () {
      const decision = ReviewDecision.reject(
        queueId: 'q-1',
        severity: ModerationSeverity.high,
        reason: RejectReason.harassment,
      );
      expect(decision.approve, isFalse);
      expect(decision.severity, ModerationSeverity.high);
      expect(
        decision,
        const ReviewDecision.reject(
          queueId: 'q-1',
          severity: ModerationSeverity.high,
          reason: RejectReason.harassment,
        ),
      );
    });
  });
}
