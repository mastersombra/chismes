import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/services/profile_service.dart';
import '../../domain/repositories/social_repository.dart';

/// [ProfileService] real: los contadores salen de `get_user_profile`.
@Singleton(as: ProfileService)
class SocialProfileService implements ProfileService {
  final SocialRepository _repository;

  SocialProfileService(this._repository);

  @override
  Future<int> getFollowingCount(String userId) async {
    final result = await _repository.getUserProfile(userId);
    return switch (result) {
      Success(value: final profile) => profile.followingCount,
      ResultFailure(error: final failure) => throw failure,
    };
  }
}
