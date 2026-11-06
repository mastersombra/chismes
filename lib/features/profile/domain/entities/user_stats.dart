/// Estadísticas del usuario
class UserStats {
  final int gossipsCount;
  final int commentsCount;
  final int followersCount;
  final int followingCount;
  final DateTime? lastActivityAt;

  const UserStats({
    required this.gossipsCount,
    required this.commentsCount,
    required this.followersCount,
    required this.followingCount,
    this.lastActivityAt,
  });

  UserStats copyWith({
    int? gossipsCount,
    int? commentsCount,
    int? followersCount,
    int? followingCount,
    DateTime? lastActivityAt,
  }) {
    return UserStats(
      gossipsCount: gossipsCount ?? this.gossipsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  @override
  String toString() {
    return 'UserStats(gossips: $gossipsCount, comments: $commentsCount, '
        'followers: $followersCount, following: $followingCount)';
  }
}
