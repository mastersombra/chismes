import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: Iniciar sesión con Apple OAuth
///
/// Inicia el flujo de OAuth con Apple y autentica al usuario.
@injectable
class SignInWithAppleUseCase {
  final AuthRepository _repository;

  SignInWithAppleUseCase(this._repository);

  /// Ejecuta el caso de uso
  ///
  /// Returns:
  /// - Success: Usuario autenticado con Apple
  /// - Failure: OAuthCancelledFailure, NetworkFailure
  Future<Result<Failure, User>> call() async {
    return _repository.signInWithApple();
  }
}
