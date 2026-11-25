import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/social_repository.dart';

/// Quita a un usuario de mis seguidores
@injectable
class RemoveFollower {
  final SocialRepository _repository;

  RemoveFollower(this._repository);

  Future<Result<Failure, void>> call(String followerId) => _repository.removeFollower(followerId);
}
