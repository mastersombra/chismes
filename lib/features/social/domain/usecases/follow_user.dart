import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/follow_result.dart';
import '../repositories/social_repository.dart';

/// Sigue a un usuario (o le envía solicitud si su cuenta es privada)
@injectable
class FollowUser {
  final SocialRepository _repository;

  FollowUser(this._repository);

  Future<Result<Failure, FollowResult>> call(String userId) => _repository.followUser(userId);
}
