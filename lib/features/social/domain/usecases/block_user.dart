import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/social_repository.dart';

/// Bloquea a un usuario (corta el seguimiento en ambos sentidos)
@injectable
class BlockUser {
  final SocialRepository _repository;

  BlockUser(this._repository);

  Future<Result<Failure, void>> call(String userId) => _repository.blockUser(userId);
}
