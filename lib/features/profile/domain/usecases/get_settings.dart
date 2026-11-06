import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/profile_settings.dart';
import '../repositories/profile_repository.dart';

/// Caso de uso para obtener configuraciones del usuario
@injectable
class GetSettings {
  final ProfileRepository _repository;

  GetSettings(this._repository);

  Future<Result<Failure, ProfileSettings>> call(String userId) {
    return _repository.getSettings(userId);
  }
}
