import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/account_status.dart';

/// Estado de la cuenta del usuario actual (Edge Function `account-status`).
///
/// Separado de [ModerationRepository]: cualquier usuario lo usa, sobre sí
/// mismo; las operaciones de moderador quedan fuera de su alcance.
abstract class AccountStatusRepository {
  Future<Result<Failure, AccountStatus>> getStatus();

  /// Apela un rechazo propio. `conflict` si ya se apeló o venció el plazo;
  /// `notFound` si el rechazo no existe o no es suyo.
  Future<Result<Failure, AccountAppeal>> submitAppeal({
    required String queueId,
    required String message,
  });
}
