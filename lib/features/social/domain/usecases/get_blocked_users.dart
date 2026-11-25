import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/social_user.dart';
import '../repositories/social_repository.dart';

/// Usuarios que bloqueé
@injectable
class GetBlockedUsers {
  final SocialRepository _repository;

  GetBlockedUsers(this._repository);

  Future<Result<Failure, List<SocialUser>>> call() => _repository.getBlockedUsers();
}
