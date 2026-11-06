import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/gossip.dart';
import '../entities/create_gossip_input.dart';
import '../entities/gossip_query.dart';
import '../entities/report_reason.dart';

/// Repositorio para operaciones de Gossip
///
/// ✅ CORREGIDO PARA PRODUCCIÓN:
///
/// Ahora usa getGossips(GossipQuery) con filtros y paginación, diseñado para
/// millones de usuarios. El query permite filtrar en el servidor (Firestore/API)
/// en lugar de descargar todos los registros y filtrar en el cliente.
///
/// En Firestore:
/// - where(...) para filtros de ubicación y estado
/// - orderBy(...) para ordenamiento
/// - limit(...) para tamaño de página
/// - startAfter(...) para paginación con cursor
///
/// Ejemplo de uso:
/// ```dart
/// final query = GossipQuery.defaultPublic();
/// final result = await repository.getGossips(query);
/// ```
abstract class GossipRepository {
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query);

  /// Crea un gossip con imagen (atómico y seguro)
  ///
  /// Envía gossip + imagen a Edge Function que hace todo atómicamente:
  /// 1. Upload a cuarentena (privado)
  /// 2. Validar MIME real, dimensiones, tamaño
  /// 3. Moderar contenido
  /// 4. Si aprueba: Mover a público + INSERT gossip
  /// 5. Si rechaza: Eliminar de cuarentena
  ///
  /// **Ventajas:**
  /// - ✅ 100% atómico (todo o nada)
  /// - ✅ 0% archivos huérfanos
  /// - ✅ Validación MIME real (no confía en cliente)
  /// - ✅ Cuarentena privada
  /// - ✅ storage_path como fuente de verdad
  ///
  /// **Parámetros:**
  /// - input: Datos del gossip
  /// - imageBase64: Imagen en base64 (opcional)
  ///
  /// **Retorna:** Gossip creado con URLs de imagen incluidas
  Future<Result<Failure, Gossip>> createWithImage(
    CreateGossipInput input,
    String? imageBase64,
  );

  /// Reporta un gossip como inapropiado
  ///
  /// Envía el reporte al Edge Function que:
  /// 1. Valida que el usuario esté autenticado
  /// 2. Registra el reporte en la tabla `gossip_reports`
  /// 3. Incrementa `report_count` en el gossip
  /// 4. Si llega a 3+ reportes únicos, marca el gossip como 'flagged'
  ///
  /// **Constraint:** Un usuario solo puede reportar un gossip una vez
  ///
  /// **Parámetros:**
  /// - gossipId: ID del gossip a reportar
  /// - reason: Razón del reporte
  /// - details: Detalles adicionales opcionales
  ///
  /// **Retorna:** Success si el reporte se registró correctamente
  Future<Result<Failure, void>> reportGossip({
    required String gossipId,
    required ReportReason reason,
    String? details,
  });
}
