import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/user_profile.dart';
import '../repositories/social_repository.dart';

/// Perfil de un usuario visto por mí
@injectable
class GetUserProfile {
  final SocialRepository _repository;

  GetUserProfile(this._repository);

  Future<Result<Failure, UserProfile>> call(String userId) => _repository.getUserProfile(userId);
}
