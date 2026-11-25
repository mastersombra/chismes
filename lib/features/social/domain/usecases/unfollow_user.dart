import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/social_repository.dart';

/// Deja de seguir a un usuario o cancela la solicitud pendiente
@injectable
class UnfollowUser {
  final SocialRepository _repository;

  UnfollowUser(this._repository);

  Future<Result<Failure, void>> call(String userId) => _repository.unfollowUser(userId);
}
