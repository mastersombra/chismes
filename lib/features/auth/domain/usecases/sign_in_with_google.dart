import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// Caso de uso: Iniciar sesión con Google OAuth
///
/// Inicia el flujo de OAuth con Google y autentica al usuario.
@injectable
class SignInWithGoogleUseCase {
  final AuthRepository _repository;

  SignInWithGoogleUseCase(this._repository);

  /// Ejecuta el caso de uso
  ///
  /// Returns:
  /// - Success: Usuario autenticado con Google
  /// - Failure: OAuthCancelledFailure, NetworkFailure
  Future<Result<Failure, User>> call() async {
    return _repository.signInWithGoogle();
  }
}
