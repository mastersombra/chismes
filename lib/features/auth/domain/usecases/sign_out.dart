import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: Cerrar sesión
///
/// Cierra la sesión del usuario actual.
@injectable
class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  /// Ejecuta el caso de uso
  ///
  /// Returns:
  /// - Success: void (sesión cerrada)
  /// - Failure: NetworkFailure
  Future<Result<Failure, void>> call() async {
    return _repository.signOut();
  }
}
