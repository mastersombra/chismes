import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/social/gossip_author.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/social/domain/entities/follow_request.dart';
import 'package:chismes/features/social/domain/entities/follow_result.dart';
import 'package:chismes/features/social/domain/entities/social_page.dart';
import 'package:chismes/features/social/domain/entities/social_user.dart';
import 'package:chismes/features/social/domain/entities/user_profile.dart';
import 'package:mockito/mockito.dart';

/// Datos de prueba del feature social (JSON del servidor y entidades)

const kOtherUserId = '11111111-1111-1111-1111-111111111111';
const kMyUserId = '99999999-9999-9999-9999-999999999999';

Map<String, dynamic> userJson({
  String id = kOtherUserId,
  String? username = 'ana',
  String? displayName = 'Ana Pérez',
  String? avatarUrl,
  bool isFollowing = false,
}) =>
    {
      'id': id,
      'username': username,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'is_following': isFollowing,
    };

/// Perfil completo (no bloqueado) como lo manda `get_user_profile`
Map<String, dynamic> profileJson({
  String id = kOtherUserId,
  bool isMe = false,
  bool isPrivate = false,
  bool canViewContent = true,
  bool isFollowing = false,
  bool isFollowedBy = false,
  bool isRequested = false,
  int followersCount = 10,
  int followingCount = 4,
  int? gossipsCount = 3,
  String? bio = 'Hola, soy Ana',
}) =>
    {
      'id': id,
      'username': 'ana',
      'display_name': 'Ana Pérez',
      'avatar_url': null,
      'bio': bio,
      'is_me': isMe,
      'is_private': isPrivate,
      'can_view_content': canViewContent,
      'has_blocked': false,
      'is_following': isFollowing,
      'is_followed_by': isFollowedBy,
      'is_requested': isRequested,
      'followers_count': followersCount,
      'following_count': followingCount,
      'gossips_count': gossipsCount,
    };

/// Perfil de alguien que YO bloqueé: solo datos básicos + has_blocked
Map<String, dynamic> blockedProfileJson({String id = kOtherUserId}) => {
      'id': id,
      'username': 'ana',
      'display_name': 'Ana Pérez',
      'avatar_url': null,
      'has_blocked': true,
    };

/// Chisme con perfil como lo manda `get_user_gossips`
Map<String, dynamic> userGossipJson(String id, {String publishedAs = 'profile'}) => {
      'id': id,
      'subject': 'Asunto $id',
      'content': 'Contenido $id',
      'country_id': 'CO',
      'region_id': 'co-antioquia',
      'city_id': 'MED',
      'city_name': 'Medellín',
      'created_at': '2026-11-20T10:00:00.000Z',
      'likes': 0,
      'comments': 0,
      'shares': 0,
      'published_as': publishedAs,
      'created_by': publishedAs == 'profile' ? kOtherUserId : null,
      'author_username': publishedAs == 'profile' ? 'ana' : null,
      'author_display_name': publishedAs == 'profile' ? 'Ana Pérez' : null,
      'author_avatar_url': null,
      'image_url': null,
      'score': 0,
      'is_from_my_city': null,
      'is_trending': false,
    };

const tUser = SocialUser(id: kOtherUserId, username: 'ana', displayName: 'Ana Pérez');
const tUser2 = SocialUser(id: 'u2', username: 'beto', displayName: 'Beto');

UserProfile tProfile({
  String id = kOtherUserId,
  bool isMe = false,
  bool isPrivate = false,
  bool canViewContent = true,
  bool hasBlocked = false,
  bool isFollowing = false,
  bool isFollowedBy = false,
  bool isRequested = false,
  int followersCount = 10,
  int followingCount = 4,
  int? gossipsCount = 3,
  String? bio = 'Hola, soy Ana',
}) =>
    UserProfile(
      id: id,
      username: 'ana',
      displayName: 'Ana Pérez',
      bio: hasBlocked ? null : bio,
      isMe: isMe,
      isPrivate: isPrivate,
      canViewContent: canViewContent && !hasBlocked,
      hasBlocked: hasBlocked,
      isFollowing: isFollowing,
      isFollowedBy: isFollowedBy,
      isRequested: isRequested,
      followersCount: hasBlocked ? 0 : followersCount,
      followingCount: hasBlocked ? 0 : followingCount,
      gossipsCount: hasBlocked ? null : gossipsCount,
    );

Gossip tProfileGossip(String id) => Gossip(
      id: id,
      countryId: 'CO',
      regionId: 'co-antioquia',
      cityId: 'MED',
      subject: 'Asunto $id',
      content: 'Contenido $id',
      publishedAs: PublishAs.profile,
      status: GossipStatus.published,
      moderationStatus: ModerationStatus.approved,
      visibility: GossipVisibility.public,
      createdAt: DateTime.utc(2026, 11, 20, 10),
      createdBy: kOtherUserId,
      author: const GossipAuthor(
        userId: kOtherUserId,
        username: 'ana',
        displayName: 'Ana Pérez',
      ),
    );

final tCursor = SocialCursor(createdAt: DateTime.utc(2026, 11, 20, 10), id: 'last');

SocialPage<T> page<T>(List<T> items, {bool hasMore = false}) => SocialPage<T>(
      items: items,
      hasMore: hasMore,
      nextCursor: hasMore ? tCursor : null,
    );

final tRequest = FollowRequest(user: tUser, createdAt: DateTime.utc(2026, 11, 21));

/// Dummies de `Result` para los mocks de SocialRepository (Result es sealed:
/// mockito no puede inventarlos). Llamar en setUp/setUpAll.
void provideSocialDummies() {
  const failure = Failure(code: ErrorCode.unknownError);
  provideDummy<Result<Failure, void>>(Result.failure(failure));
  provideDummy<Result<Failure, FollowResult>>(Result.failure(failure));
  provideDummy<Result<Failure, UserProfile>>(Result.failure(failure));
  provideDummy<Result<Failure, SocialPage<SocialUser>>>(Result.failure(failure));
  provideDummy<Result<Failure, SocialPage<Gossip>>>(Result.failure(failure));
  provideDummy<Result<Failure, List<FollowRequest>>>(Result.failure(failure));
  provideDummy<Result<Failure, List<SocialUser>>>(Result.failure(failure));
}
