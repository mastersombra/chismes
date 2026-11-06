import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/user_stats.dart';
import '../repositories/profile_repository.dart';

/// Caso de uso para obtener estadísticas del usuario
@injectable
class GetUserStats {
  final ProfileRepository _repository;

  GetUserStats(this._repository);

  Future<Result<Failure, UserStats>> call(String userId) {
    return _repository.getUserStats(userId);
  }
}
