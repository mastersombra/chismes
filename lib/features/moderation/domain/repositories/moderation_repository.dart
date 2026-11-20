import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
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
}
