/// JSON de prueba de sanciones y apelaciones, como lo devuelven
/// `account-status` y `moderation-review` (tests de data)
library;

Map<String, dynamic> appealJson({
  String id = 'ap-1',
  String status = 'pending',
  String? decidedAt,
}) =>
    {
      'id': id,
      'status': status,
      'message': 'No era un insulto, era un chiste',
      'created_at': '2026-11-20T10:00:00Z',
      'decided_at': decidedAt,
    };

Map<String, dynamic> rejectionJson({
  String queueId = 'q-1',
  Map<String, dynamic>? appeal,
  bool overturned = false,
  bool canAppeal = true,
}) =>
    {
      'queue_id': queueId,
      'gossip_id': 'g-1',
      'subject': 'Asunto',
      'content': 'Contenido',
      'severity': 'high',
      'reason': 'harassment',
      'decided_at': '2026-11-19T10:00:00Z',
      'overturned': overturned,
      'points': overturned ? null : 4,
      'expires_at': '2027-02-17T10:00:00Z',
      'sanction': overturned ? null : 'restriction',
      'sanction_ends_at': overturned ? null : '2026-11-20T10:00:00Z',
      'appeal_deadline': '2026-12-03T10:00:00Z',
      'can_appeal': canAppeal,
      'appeal': appeal,
    };

Map<String, dynamic> accountStatusJson({
  String state = 'restricted',
  String? restrictedUntil = '2026-11-22T10:00:00Z',
  Map<String, dynamic>? inherited,
  List<Map<String, dynamic>>? rejections,
}) =>
    {
      'state': state,
      'restricted_until': restrictedUntil,
      'active_points': 4,
      'strike_count': 1,
      'expiry_days': 90,
      'appeal_window_days': 14,
      'thresholds': {'restriction_short': 3, 'restriction_long': 6, 'suspension': 10},
      'inherited': inherited,
      'rejections': rejections ?? [rejectionJson()],
    };

Map<String, dynamic> moderationAppealJson({
  String id = 'ap-1',
  String status = 'pending',
  String publishedAs = 'anonymous',
}) =>
    {
      'id': id,
      'queue_id': 'q-1',
      'gossip_id': 'g-1',
      'user_id': 'u-1',
      'author_username': 'pepito',
      'author_display_name': 'Pepito',
      'published_as': publishedAs,
      'message': 'No era un insulto',
      'status': status,
      'created_at': '2026-11-20T10:00:00Z',
      'decided_at': status == 'pending' ? null : '2026-11-21T10:00:00Z',
      'decision_note': status == 'pending' ? null : 'tiene razón',
      'subject': 'Asunto',
      'content': 'Contenido',
      'original_source': 'reports',
      'original_reasons': ['harassment', 'spam'],
      'original_report_count': 3,
      'original_severity': 'high',
      'original_reason': 'harassment',
      'original_note': 'nota interna',
      'original_decided_at': '2026-11-19T10:00:00Z',
      'original_decided_by': 'mod-1',
    };
