import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/report_reason.dart';
import '../repositories/gossip_repository.dart';

/// UseCase para reportar un gossip inapropiado
///
/// Permite a los usuarios reportar contenido que viole las reglas de la comunidad.
/// El reporte se envía al Edge Function que valida y registra en la base de datos.
///
/// **Reglas:**
/// - Un usuario solo puede reportar un gossip una vez (unique constraint)
/// - Después de 3 reportes únicos, el gossip se marca automáticamente como 'flagged'
/// - Los reportes quedan registrados para revisión de moderadores
@injectable
class ReportGossip {
  final GossipRepository _repository;

  ReportGossip(this._repository);

  /// Reporta un gossip
  ///
  /// [gossipId]: ID del gossip a reportar
  /// [reason]: Razón del reporte
  /// [details]: Detalles adicionales opcionales
  ///
  /// Retorna:
  /// - Success: si el reporte se registró correctamente
  /// - Failure: si hubo error (ej: usuario ya reportó este gossip)
  Future<Result<Failure, void>> call({
    required String gossipId,
    required ReportReason reason,
    String? details,
  }) async {
    return _repository.reportGossip(
      gossipId: gossipId,
      reason: reason,
      details: details,
    );
  }
}
