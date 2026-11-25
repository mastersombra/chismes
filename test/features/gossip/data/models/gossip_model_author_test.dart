import 'package:chismes/core/social/gossip_author.dart';
import 'package:chismes/features/gossip/data/models/gossip_model.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _json({
  String publishedAs = 'profile',
  String? createdBy = 'u1',
  Map<String, dynamic> extra = const {},
}) =>
    {
      'id': 'g1',
      'country_id': 'CO',
      'region_id': 'co-antioquia',
      'city_id': 'MED',
      'subject': 'Asunto',
      'content': 'Contenido',
      'published_as': publishedAs,
      'status': 'published',
      'moderation_status': 'approved',
      'visibility': 'public',
      'created_at': '2026-11-20T10:00:00.000Z',
      'created_by': createdBy,
      ...extra,
    };

void main() {
  group('GossipModel - autor (public_gossips, migración 018)', () {
    test('chisme con perfil: lee author_* y arma GossipAuthor en toEntity', () {
      final model = GossipModel.fromJson(_json(extra: {
        'author_username': 'ana',
        'author_display_name': 'Ana',
        'author_avatar_url': 'https://x/a.jpg',
      }));

      expect(model.authorUsername, 'ana');
      expect(
        model.toEntity().author,
        const GossipAuthor(
          userId: 'u1',
          username: 'ana',
          displayName: 'Ana',
          avatarUrl: 'https://x/a.jpg',
        ),
      );
    });

    test('chisme anónimo: sin autor aunque el JSON trajera datos', () {
      final model = GossipModel.fromJson(_json(
        publishedAs: 'anonymous',
        extra: {'author_username': 'ana', 'author_display_name': 'Ana'},
      ));

      expect(model.toEntity().author, isNull);
    });

    test('caché vieja sin claves author_* se lee sin error y sin autor', () {
      final model = GossipModel.fromJson(_json());

      expect(model.authorUsername, isNull);
      expect(model.authorDisplayName, isNull);
      expect(model.authorAvatarUrl, isNull);
      expect(model.toEntity().author, isNull);
    });

    test('author_* con tipo incorrecto lanza FormatException', () {
      expect(
        () => GossipModel.fromJson(_json(extra: {'author_username': 42})),
        throwsA(isA<FormatException>()),
      );
    });

    test('toJson/fromJson/fromEntity conservan el autor (caché local)', () {
      final entity = GossipModel.fromJson(_json(extra: {
        'author_username': 'ana',
        'author_display_name': 'Ana',
      })).toEntity();

      final json = GossipModel.fromEntity(entity).toJson();
      final roundTrip = GossipModel.fromJson(json).toEntity();

      expect(json['author_username'], 'ana');
      expect(json['author_display_name'], 'Ana');
      expect(json['author_avatar_url'], isNull);
      expect(roundTrip.author, entity.author);
      expect(roundTrip, entity);
    });
  });
}
