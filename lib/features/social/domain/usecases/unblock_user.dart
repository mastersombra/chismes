import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/social_repository.dart';

/// Desbloquea a un usuario
@injectable
class UnblockUser {
  final SocialRepository _repository;

  UnblockUser(this._repository);

  Future<Result<Failure, void>> call(String userId) => _repository.unblockUser(userId);
}
