import '../../domain/entities/social_user.dart';

/// Usuario de las listas sociales (`social_user_json` en la migración 018):
/// `{id, username, display_name, avatar_url, is_following}`
class SocialUserModel {
  final String id;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final bool isFollowing;

  const SocialUserModel({
    required this.id,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.isFollowing = false,
  });

  /// Lanza [FormatException] si falta el id o un campo tiene otro tipo
  factory SocialUserModel.fromJson(Map<String, dynamic> json) {
    try {
      return SocialUserModel(
        id: json['id'] as String,
        username: json['username'] as String?,
        displayName: json['display_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        isFollowing: json['is_following'] as bool? ?? false,
      );
    } catch (e) {
      throw FormatException('Error deserializando SocialUserModel: $e');
    }
  }

  /// Lista JSON (`[...]`); null → vacía
  static List<SocialUserModel> listFromJson(dynamic json) {
    if (json == null) return const [];
    if (json is! List) {
      throw FormatException('Expected a JSON list of users, got ${json.runtimeType}');
    }
    return json
        .map((item) => SocialUserModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  SocialUser toEntity() => SocialUser(
        id: id,
        username: username,
        displayName: displayName,
        avatarUrl: avatarUrl,
        isFollowing: isFollowing,
      );
}
