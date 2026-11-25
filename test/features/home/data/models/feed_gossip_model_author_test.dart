import 'package:chismes/core/social/gossip_author.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/home/data/models/feed_gossip_model.dart';
import 'package:chismes/features/home/presentation/widgets/feed_gossip_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({
  required String publishedAs,
  String? createdBy,
  String? username,
  String? displayName,
}) =>
    {
      'id': 'g1',
      'subject': 'Asunto',
      'content': 'Contenido',
      'city_id': 'MED',
      'created_at': '2026-11-20T10:00:00.000Z',
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'published_as': publishedAs,
      'created_by': createdBy,
      'author_username': username,
      'author_display_name': displayName,
      'author_avatar_url': null,
      'image_url': null,
      'score': 1,
      'is_from_my_city': null,
      'is_trending': false,
    };

void main() {
  group('FeedGossipModel - autor', () {
    test('chisme con perfil: el autor llega a FeedGossip y al Gossip del adaptador', () {
      final feed = FeedGossipModel.fromJson(_json(
        publishedAs: 'profile',
        createdBy: 'u1',
        username: 'ana',
        displayName: 'Ana',
      )).toEntity();

      const expected = GossipAuthor(userId: 'u1', username: 'ana', displayName: 'Ana');
      expect(feed.author, expected);

      final gossip = FeedGossipAdapter.toGossip(feed);
      expect(gossip.author, expected);
      expect(gossip.publishedAs, PublishAs.profile);
    });

    test('chisme anónimo: sin autor ni en FeedGossip ni en el Gossip adaptado', () {
      final feed = FeedGossipModel.fromJson(_json(publishedAs: 'anonymous')).toEntity();

      expect(feed.author, isNull);
      expect(FeedGossipAdapter.toGossip(feed).author, isNull);
    });

    test('toJson incluye los campos author_*', () {
      final json = FeedGossipModel.fromJson(_json(
        publishedAs: 'profile',
        createdBy: 'u1',
        username: 'ana',
        displayName: 'Ana',
      )).toJson();

      expect(json['author_username'], 'ana');
      expect(json['author_display_name'], 'Ana');
      expect(json.containsKey('author_avatar_url'), isTrue);
    });
  });
}
