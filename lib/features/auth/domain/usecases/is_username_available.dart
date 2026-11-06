import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/auth_repository.dart';
import '../validators/auth_validator.dart';

/// Caso de uso: Verificar disponibilidad de username
///
/// Verifica si un username está disponible para uso.
@injectable
class IsUsernameAvailableUseCase {
  final AuthRepository _repository;

  IsUsernameAvailableUseCase(this._repository);

  /// Ejecuta el caso de uso
  ///
  /// [username] Username a verificar
  ///
  /// Returns:
  /// - Success: true si disponible, false si ya existe
  /// - Failure: ValidationFailure, NetworkFailure
  Future<Result<Failure, bool>> call(String username) async {
    // Validación de formato
    final validation = AuthValidator.validateUsername(username);
    if (validation != null) {
      return Result.failure(validation);
    }

    // Verificar disponibilidad
    return _repository.isUsernameAvailable(username);
  }
}
