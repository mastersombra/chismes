import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/profile_repository.dart';

/// Caso de uso para cerrar sesión
@injectable
class SignOut {
  final ProfileRepository _repository;

  SignOut(this._repository);

  Future<Result<Failure, void>> call() {
    return _repository.signOut();
  }
}
