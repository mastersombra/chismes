import '../../domain/entities/user_stats.dart';

/// Modelo de estadísticas del usuario (Data Layer)
class UserStatsModel {
  final int gossipsCount;
  final int commentsCount;
  final int followersCount;
  final int followingCount;
  final String? lastActivityAt;

  const UserStatsModel({
    required this.gossipsCount,
    required this.commentsCount,
    required this.followersCount,
    required this.followingCount,
    this.lastActivityAt,
  });

  /// Convierte el modelo a entidad de dominio
  UserStats toEntity() {
    return UserStats(
      gossipsCount: gossipsCount,
      commentsCount: commentsCount,
      followersCount: followersCount,
      followingCount: followingCount,
      lastActivityAt: lastActivityAt != null
          ? DateTime.parse(lastActivityAt!)
          : null,
    );
  }

  /// Crea un modelo desde JSON de Supabase
  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    return UserStatsModel(
      gossipsCount: json['gossips_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      lastActivityAt: json['last_activity_at'] as String?,
    );
  }

  /// Convierte el modelo a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'gossips_count': gossipsCount,
      'comments_count': commentsCount,
      'followers_count': followersCount,
      'following_count': followingCount,
      'last_activity_at': lastActivityAt,
    };
  }
}
