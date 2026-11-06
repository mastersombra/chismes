import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: Obtener usuario actual
///
/// Obtiene el usuario actualmente autenticado de forma asíncrona.
@injectable
class GetCurrentUserUseCase {
  final AuthRepository _repository;

  GetCurrentUserUseCase(this._repository);

  /// Ejecuta el caso de uso
  ///
  /// Returns:
  /// - Success: Usuario actual o null si no hay sesión
  /// - Failure: NetworkFailure
  Future<Result<Failure, User?>> call() async {
    return _repository.getCurrentUser();
  }
}
