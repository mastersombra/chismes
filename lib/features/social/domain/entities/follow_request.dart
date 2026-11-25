import 'package:equatable/equatable.dart';

import 'social_user.dart';

/// Solicitud pendiente para seguir mi cuenta privada
class FollowRequest extends Equatable {
  /// Quién la hizo
  final SocialUser user;
  final DateTime createdAt;

  const FollowRequest({required this.user, required this.createdAt});

  @override
  List<Object?> get props => [user, createdAt];
}
