import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/profile_settings.dart';
import '../repositories/profile_repository.dart';

/// Caso de uso para actualizar configuraciones del usuario
@injectable
class UpdateSettings {
  final ProfileRepository _repository;

  UpdateSettings(this._repository);

  Future<Result<Failure, void>> call(
    String userId,
    ProfileSettings settings,
  ) {
    return _repository.updateSettings(userId, settings);
  }
}
