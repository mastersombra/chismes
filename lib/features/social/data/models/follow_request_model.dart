import '../../domain/entities/follow_request.dart';
import 'social_user_model.dart';

/// Item de `get_follow_requests`: `{user: {...}, created_at}`
class FollowRequestModel {
  final SocialUserModel user;
  final String createdAt;

  const FollowRequestModel({required this.user, required this.createdAt});

  /// Lanza [FormatException] si falta el usuario o la fecha
  factory FollowRequestModel.fromJson(Map<String, dynamic> json) {
    try {
      return FollowRequestModel(
        user: SocialUserModel.fromJson(json['user'] as Map<String, dynamic>),
        createdAt: json['created_at'] as String,
      );
    } catch (e) {
      throw FormatException('Error deserializando FollowRequestModel: $e');
    }
  }

  /// Lista JSON (`[...]`); null → vacía
  static List<FollowRequestModel> listFromJson(dynamic json) {
    if (json == null) return const [];
    if (json is! List) {
      throw FormatException('Expected a JSON list of requests, got ${json.runtimeType}');
    }
    return json
        .map((item) => FollowRequestModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  FollowRequest toEntity() => FollowRequest(
        user: user.toEntity(),
        createdAt: DateTime.parse(createdAt),
      );
}
