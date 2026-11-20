import 'package:chismes/features/moderation/data/models/moderation_item_model.dart';
import 'package:chismes/features/moderation/domain/entities/moderation_item.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../moderation_fixtures.dart';

void main() {
  test('pendiente: mapea todos los campos a la entidad', () {
    final item = ModerationItemModel.fromJson(queueItemJson(
      priority: 'high',
      publishedAs: 'anonymous',
      source: 'reports',
      reasons: ['spam', 'harassment'],
      imagePreviewUrl: 'https://signed',
      audioQuarantinePath: 'quarantine/a.m4a',
    )).toEntity();

    expect(item.id, 'q-1');
    expect(item.gossipId, 'g-q-1');
    expect(item.authorId, 'author-1');
    expect(item.authorName, 'La Chismosa');
    expect(item.publishedAnonymously, isTrue);
    expect(item.source, ModerationSource.reports);
    expect(item.reasons, ['spam', 'harassment']);
    expect(item.highPriority, isTrue);
    expect(item.reportCount, 2);
    expect(item.autoHidden, isFalse);
    expect(item.status, ModerationQueueStatus.pending);
    expect(item.subject, 'Boda en el barrio');
    expect(item.displayImageUrl, 'https://signed');
    expect(item.hasAudio, isTrue);
    expect(item.interactions, 7);
    expect(item.contentCreatedAt, DateTime.utc(2026, 11, 19, 10));
    expect(item.queuedAt, DateTime.utc(2026, 11, 19, 10, 5));
    expect(item.decidedAt, isNull);
    expect(item.decisionSeverity, isNull);
  });

  test('decidido: fecha, gravedad, motivo y nota', () {
    final item = ModerationItemModel.fromJson(queueItemJson(
      status: 'rejected',
      decidedAt: '2026-11-20T08:00:00Z',
      decisionSeverity: 'high',
      decisionReason: 'harassment',
      decisionNote: 'Reincidente',
    )).toEntity();

    expect(item.status, ModerationQueueStatus.rejected);
    expect(item.decidedAt, DateTime.utc(2026, 11, 20, 8));
    expect(item.decisionSeverity, ModerationSeverity.high);
    expect(item.decisionReason, 'harassment');
    expect(item.decisionNote, 'Reincidente');
    expect(item.hasAudio, isFalse);
    expect(item.publishedAnonymously, isFalse);
  });

  test('campos opcionales ausentes toman valores por defecto', () {
    final json = queueItemJson()
      ..remove('reasons')
      ..remove('priority')
      ..remove('report_count')
      ..remove('auto_hidden')
      ..remove('published_as')
      ..remove('interactions')
      ..remove('author_username')
      ..remove('author_display_name');
    json['audio_url'] = 'https://public/a.m4a';

    final item = ModerationItemModel.fromJson(json).toEntity();

    expect(item.reasons, isEmpty);
    expect(item.highPriority, isFalse);
    expect(item.reportCount, 0);
    expect(item.autoHidden, isFalse);
    expect(item.publishedAnonymously, isFalse);
    expect(item.interactions, 0);
    expect(item.authorName, isNull);
    expect(item.hasAudio, isTrue);
  });
}
