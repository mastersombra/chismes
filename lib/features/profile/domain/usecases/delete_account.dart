import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/profile_repository.dart';

/// Caso de uso para eliminar la cuenta del usuario (irreversible)
///
/// Borra la cuenta, el perfil, todos sus chismes y su media. Si tuvo
/// contenido rechazado por moderación, el servidor guarda solo un registro
/// anónimo de esas faltas (ver `supabase/migrations/014_account_deletion.sql`).
@injectable
class DeleteAccount {
  final ProfileRepository _repository;

  DeleteAccount(this._repository);

  Future<Result<Failure, void>> call() {
    return _repository.deleteAccount();
  }
}
