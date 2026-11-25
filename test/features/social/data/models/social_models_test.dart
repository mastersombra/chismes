import 'package:chismes/core/social/gossip_author.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/social/data/models/follow_request_model.dart';
import 'package:chismes/features/social/data/models/social_page_model.dart';
import 'package:chismes/features/social/data/models/social_user_model.dart';
import 'package:chismes/features/social/data/models/user_gossip_model.dart';
import 'package:chismes/features/social/data/models/user_profile_model.dart';
import 'package:chismes/features/social/domain/entities/social_page.dart';
import 'package:chismes/features/social/domain/entities/social_user.dart';
import 'package:chismes/features/social/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../social_fixtures.dart';

void main() {
  group('SocialUserModel', () {
    test('fromJson/toEntity mapean todos los campos', () {
      final user = SocialUserModel.fromJson(userJson(
        avatarUrl: 'https://x/a.jpg',
        isFollowing: true,
      )).toEntity();

      expect(
        user,
        const SocialUser(
          id: kOtherUserId,
          username: 'ana',
          displayName: 'Ana Pérez',
          avatarUrl: 'https://x/a.jpg',
          isFollowing: true,
        ),
      );
    });

    test('sin is_following asume false; campos opcionales null', () {
      final user = SocialUserModel.fromJson({'id': 'u1'}).toEntity();

      expect(user.isFollowing, isFalse);
      expect(user.username, isNull);
      expect(user.name, '');
    });

    test('sin id lanza FormatException', () {
      expect(() => SocialUserModel.fromJson({'username': 'x'}), throwsFormatException);
    });

    test('listFromJson: null → vacía, no-lista → FormatException', () {
      expect(SocialUserModel.listFromJson(null), isEmpty);
      expect(SocialUserModel.listFromJson([userJson(), userJson(id: 'u2')]), hasLength(2));
      expect(() => SocialUserModel.listFromJson({'id': 'u1'}), throwsFormatException);
    });
  });

  group('UserProfileModel', () {
    test('perfil completo: todos los campos y relación', () {
      final profile = UserProfileModel.fromJson(profileJson(
        isPrivate: true,
        isFollowing: true,
        isFollowedBy: true,
        followersCount: 120,
        followingCount: 7,
        gossipsCount: 5,
      )).toEntity();

      expect(profile.id, kOtherUserId);
      expect(profile.bio, 'Hola, soy Ana');
      expect(profile.isPrivate, isTrue);
      expect(profile.canViewContent, isTrue);
      expect(profile.hasBlocked, isFalse);
      expect(profile.isFollowedBy, isTrue);
      expect(profile.followStatus, FollowStatus.following);
      expect(profile.followersCount, 120);
      expect(profile.followingCount, 7);
      expect(profile.gossipsCount, 5);
      expect(profile.canInteract, isTrue);
    });

    test('privada que no sigo: sin contenido y gossips_count null', () {
      final profile = UserProfileModel.fromJson(profileJson(
        isPrivate: true,
        canViewContent: false,
        gossipsCount: null,
      )).toEntity();

      expect(profile.canViewContent, isFalse);
      expect(profile.gossipsCount, isNull);
      expect(profile.followStatus, FollowStatus.none);
    });

    test('solicitud pendiente → FollowStatus.requested', () {
      final profile = UserProfileModel.fromJson(profileJson(
        isPrivate: true,
        canViewContent: false,
        isRequested: true,
      )).toEntity();

      expect(profile.followStatus, FollowStatus.requested);
    });

    test('bloqueado por mí: JSON reducido, sin contenido ni contadores', () {
      final profile = UserProfileModel.fromJson(blockedProfileJson()).toEntity();

      expect(profile.hasBlocked, isTrue);
      expect(profile.canViewContent, isFalse);
      expect(profile.bio, isNull);
      expect(profile.followersCount, 0);
      expect(profile.gossipsCount, isNull);
      expect(profile.isMe, isFalse);
      expect(profile.name, 'Ana Pérez');
    });

    test('perfil propio: is_me sin botones', () {
      final profile = UserProfileModel.fromJson(profileJson(isMe: true)).toEntity();

      expect(profile.isMe, isTrue);
      expect(profile.canInteract, isFalse);
    });

    test('contadores numéricos como num se convierten a int', () {
      final json = profileJson()..['followers_count'] = 3.0;

      expect(UserProfileModel.fromJson(json).toEntity().followersCount, 3);
    });

    test('tipo incorrecto lanza FormatException', () {
      final json = profileJson()..['is_me'] = 'yes';

      expect(() => UserProfileModel.fromJson(json), throwsFormatException);
    });
  });

  group('FollowRequestModel', () {
    test('fromJson/toEntity con usuario y fecha', () {
      final request = FollowRequestModel.fromJson({
        'user': userJson(),
        'created_at': '2026-11-21T08:00:00Z',
      }).toEntity();

      expect(request.user.id, kOtherUserId);
      expect(request.createdAt, DateTime.utc(2026, 11, 21, 8));
    });

    test('listFromJson: null → vacía; sin usuario → FormatException', () {
      expect(FollowRequestModel.listFromJson(null), isEmpty);
      expect(
        () => FollowRequestModel.listFromJson([
          {'created_at': '2026-11-21T08:00:00Z'},
        ]),
        throwsFormatException,
      );
      expect(() => FollowRequestModel.listFromJson('x'), throwsFormatException);
    });
  });

  group('SocialPageModel', () {
    test('página con cursor → SocialPage con SocialCursor', () {
      final page = SocialPageModel.fromJson({
        'data': [userJson()],
        'has_more': true,
        'next_cursor': {'created_at': '2026-11-20T10:00:00Z', 'id': 'last'},
      }, SocialUserModel.fromJson).toEntity((m) => m.toEntity());

      expect(page.items.single.id, kOtherUserId);
      expect(page.hasMore, isTrue);
      expect(
        page.nextCursor,
        SocialCursor(createdAt: DateTime.utc(2026, 11, 20, 10), id: 'last'),
      );
    });

    test('null (RPC sin respuesta) → página vacía', () {
      final page = SocialPageModel.fromJson(null, SocialUserModel.fromJson)
          .toEntity((m) => m.toEntity());

      expect(page, const SocialPage<SocialUser>.empty());
    });

    test('has_more sin cursor no pide más páginas', () {
      final page = SocialPageModel.fromJson(
        {'data': [], 'has_more': true, 'next_cursor': null},
        SocialUserModel.fromJson,
      ).toEntity((m) => m.toEntity());

      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });

    test('data con forma inválida lanza FormatException', () {
      expect(
        () => SocialPageModel.fromJson({'data': 'x'}, SocialUserModel.fromJson),
        throwsFormatException,
      );
      expect(
        () => SocialPageModel.fromJson({
          'data': [
            {'username': 'sin-id'},
          ],
        }, SocialUserModel.fromJson),
        throwsFormatException,
      );
    });
  });

  group('UserGossipModel', () {
    test('chisme con perfil → Gossip publicado y aprobado con autor', () {
      final gossip = UserGossipModel.fromJson(userGossipJson('g1')).toEntity();

      expect(gossip.id, 'g1');
      expect(gossip.countryId, 'CO');
      expect(gossip.regionId, 'co-antioquia');
      expect(gossip.status, GossipStatus.published);
      expect(gossip.moderationStatus, ModerationStatus.approved);
      expect(gossip.visibility, GossipVisibility.public);
      expect(gossip.publishedAs, PublishAs.profile);
      expect(
        gossip.author,
        const GossipAuthor(userId: kOtherUserId, username: 'ana', displayName: 'Ana Pérez'),
      );
    });

    test('anónimo (defensivo): sin autor; país/región faltantes → unknown', () {
      final json = userGossipJson('g2', publishedAs: 'anonymous')
        ..remove('country_id')
        ..remove('region_id');

      final gossip = UserGossipModel.fromJson(json).toEntity();

      expect(gossip.publishedAs, PublishAs.anonymous);
      expect(gossip.author, isNull);
      expect(gossip.countryId, 'unknown');
      expect(gossip.regionId, 'unknown');
    });

    test('sin subject lanza FormatException', () {
      final json = userGossipJson('g3')..remove('subject');

      expect(() => UserGossipModel.fromJson(json), throwsFormatException);
    });
  });
}
