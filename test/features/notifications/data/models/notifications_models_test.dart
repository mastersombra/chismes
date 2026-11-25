import 'package:chismes/features/notifications/data/models/app_notification_model.dart';
import 'package:chismes/features/notifications/data/models/notification_page_model.dart';
import 'package:chismes/features/notifications/domain/entities/app_notification.dart';
import 'package:chismes/features/notifications/domain/entities/notification_page.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../notifications_fixtures.dart';

void main() {
  group('AppNotificationModel', () {
    test('social: deserializa actor y convierte a entidad', () {
      final model = AppNotificationModel.fromJson(notificationJson(
        type: 'follow_request',
        actor: actorJson(displayName: 'Beto Gómez', avatarUrl: 'https://x/a.jpg', isFollowing: true),
      ));

      final entity = model.toEntity()!;

      expect(entity.id, 'n1');
      expect(entity.type, NotificationType.followRequest);
      expect(entity.createdAt, DateTime.parse(kCreatedAt));
      expect(entity.isRead, isFalse);
      expect(
        entity.actor,
        const NotificationActor(
          id: kActorId,
          username: 'beto',
          displayName: 'Beto Gómez',
          avatarUrl: 'https://x/a.jpg',
          isFollowing: true,
        ),
      );
      expect(entity.gossip, isNull);
      expect(entity.reason, isNull);
    });

    test('de la cuenta: deserializa chisme y motivo', () {
      final entity = AppNotificationModel.fromJson(notificationJson(
        type: 'gossip_rejected',
        isRead: true,
        gossip: {'id': kGossipId, 'subject': 'La fiesta'},
        reason: 'spam',
      )).toEntity()!;

      expect(entity.type, NotificationType.gossipRejected);
      expect(entity.isRead, isTrue);
      expect(entity.actor, isNull);
      expect(entity.gossip, const NotificationGossip(id: kGossipId, subject: 'La fiesta'));
      expect(entity.reason, 'spam');
    });

    test('is_read ausente → no leída; subject null → vacío; is_following ausente → false', () {
      final json = notificationJson(
        type: 'gossip_approved',
        gossip: {'id': kGossipId, 'subject': null},
      )..remove('is_read');
      final entity = AppNotificationModel.fromJson(json).toEntity()!;
      expect(entity.isRead, isFalse);
      expect(entity.gossip!.subject, '');

      final actor = NotificationActorModel.fromJson({'id': kActorId}).toEntity();
      expect(actor.isFollowing, isFalse);
      expect(actor.username, isNull);
    });

    test('tipo desconocido → toEntity null (se ignora)', () {
      final model = AppNotificationModel.fromJson(notificationJson(type: 'new_reaction'));

      expect(model.toEntity(), isNull);
    });

    test('todos los tipos conocidos se convierten', () {
      for (final type in NotificationType.values) {
        final model = AppNotificationModel.fromJson(notificationJson(type: type.value));
        expect(model.toEntity()!.type, type);
      }
    });

    test('JSON inválido → FormatException', () {
      expect(
        () => AppNotificationModel.fromJson({'id': 1}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AppNotificationModel.fromJson(notificationJson(actor: {'id': 2})),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => AppNotificationModel.fromJson(notificationJson(gossip: {'subject': 'x'})),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('NotificationPageModel', () {
    test('null → página vacía sin más', () {
      final page = NotificationPageModel.fromJson(null).toEntity();

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('con cursor: hay más y omite los tipos desconocidos', () {
      final page = NotificationPageModel.fromJson(pageJson(
        [
          notificationJson(id: 'a'),
          notificationJson(id: 'b', type: 'future_type'),
          notificationJson(id: 'c', type: 'appeal_accepted', gossip: {'id': kGossipId, 'subject': 's'}),
        ],
        hasMore: true,
        nextCursor: {'created_at': kCreatedAt, 'id': 'c'},
      )).toEntity();

      expect(page.items.map((n) => n.id), ['a', 'c']);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, NotificationCursor(createdAt: DateTime.parse(kCreatedAt), id: 'c'));
    });

    test('has_more sin cursor → no hay más (evita bucle)', () {
      final page = NotificationPageModel.fromJson(pageJson([], hasMore: true)).toEntity();

      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('data/has_more ausentes → vacío', () {
      final model = NotificationPageModel.fromJson(const {});

      expect(model.data, isEmpty);
      expect(model.hasMore, isFalse);
    });

    test('forma inválida → FormatException', () {
      expect(
        () => NotificationPageModel.fromJson({'data': 'x'}),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => NotificationPageModel.fromJson({'data': [notificationJson()..['id'] = 3]}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('entidades', () {
    test('NotificationType.fromValue e isSocial', () {
      expect(NotificationType.fromValue('new_follower'), NotificationType.newFollower);
      expect(NotificationType.fromValue('nope'), isNull);
      expect(NotificationType.fromValue(null), isNull);
      expect(
        NotificationType.values.where((t) => t.isSocial),
        [NotificationType.newFollower, NotificationType.followRequest, NotificationType.followAccepted],
      );
    });

    test('NotificationActor: handle y name', () {
      expect(const NotificationActor(id: 'x', username: 'beto').handle, '@beto');
      expect(const NotificationActor(id: 'x', username: 'beto').name, '@beto');
      expect(const NotificationActor(id: 'x', username: 'beto', displayName: 'Beto').name, 'Beto');
      expect(const NotificationActor(id: 'x').handle, isNull);
      expect(const NotificationActor(id: 'x').name, '');
    });

    test('igualdad por valor', () {
      expect(tNotification(), tNotification());
      expect(tCursor, NotificationCursor(createdAt: DateTime.utc(2026, 11, 20), id: 'last'));
      expect(notificationPage([tNotification()]), notificationPage([tNotification()]));
      expect(tGossip, const NotificationGossip(id: kGossipId, subject: 'La fiesta de Ana'));
    });
  });
}
