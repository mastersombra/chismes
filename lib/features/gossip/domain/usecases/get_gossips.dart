import 'package:injectable/injectable.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/gossip.dart';
import '../entities/gossip_query.dart';
import '../repositories/gossip_repository.dart';

@injectable
class GetGossips {
  final GossipRepository repository;

  GetGossips({required this.repository});

  Future<Result<Failure, List<Gossip>>> call([GossipQuery? query]) async {
    final effectiveQuery = query ?? GossipQuery.defaultPublic();
    final result = await repository.getGossips(effectiveQuery);

    // ✅ MEJORADO: Ahora el filtrado se hace en el servidor vía GossipQuery
    // Mantenemos este filtrado como validación adicional de seguridad
    // (defense in depth), pero la carga principal debería venir filtrada
    // del servidor.
    //
    // Inicio y Buscar son superficies públicas: nunca deben recibir contenido
    // pendiente, marcado, rechazado, oculto o eliminado. Una futura cola de
    // administración puede usar queries específicos con autorización de server.
    return result.map(
      (gossips) => gossips
          .where(
            (gossip) =>
                gossip.status == GossipStatus.published &&
                gossip.moderationStatus == ModerationStatus.approved &&
                gossip.visibility == GossipVisibility.public,
          )
          .toList(),
    );
  }
}
