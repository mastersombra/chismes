import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/account_status.dart';
import '../entities/moderation_appeal.dart';
import '../entities/moderation_item.dart';
import '../entities/review_decision.dart';

/// Cola de revisión humana (Edge Function `moderation-review`).
///
/// Solo moderadores (`app_metadata.role = 'moderator'`): el servidor responde
/// `forbidden` a cualquier otro usuario.
abstract class ModerationRepository {
  /// Pendientes: prioridad alta primero, luego los más antiguos.
  /// Aprobados / rechazados: la decisión más reciente primero.
  Future<Result<Failure, List<ModerationItem>>> getQueue({
    required ModerationQueueStatus status,
    required int limit,
    int offset = 0,
  });

  /// Aplica la decisión. `conflict` si otro moderador ya la decidió.
  Future<Result<Failure, void>> decide(ReviewDecision decision);

  /// Apelaciones. Pendientes: las más antiguas primero. Decididas: la más
  /// reciente primero.
  Future<Result<Failure, List<ModerationAppeal>>> getAppeals({
    required AppealStatus status,
    required int limit,
    int offset = 0,
  });

  /// Acepta (anula la falta y republica el texto) o rechaza una apelación.
  /// `conflict` si ya se decidió; `insufficientPermissions` si se exige otro
  /// moderador y quien decide es el que rechazó.
  Future<Result<Failure, void>> decideAppeal(AppealDecision decision);
}
