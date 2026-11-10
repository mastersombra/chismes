import '../../domain/entities/create_gossip_input.dart';
import '../../domain/entities/gossip_query.dart';
import '../../domain/entities/report_reason.dart';
import '../models/gossip_model.dart';

/// Fuente de datos remota para Gossip
/// Implementaciones: Supabase, REST API, etc.
abstract class GossipRemoteDataSource {
  /// Obtiene gossips desde el servidor con filtros y paginación
  ///
  /// En producción (Firestore), esto se traduce a:
  /// - where(...) para filtros de ubicación y estado
  /// - orderBy(...) para ordenamiento
  /// - limit(...) para tamaño de página
  /// - startAfter(...) para paginación con cursor
  Future<List<GossipModel>> getGossips(GossipQuery query);

  /// Crea un nuevo gossip con imagen (atómico)
  ///
  /// Envía gossip + imagen a Edge Function moderate-gossip
  /// que hace todo en una operación atómica:
  /// 1. Sube imagen a Storage
  /// 2. Modera contenido
  /// 3. Inserta gossip con image_url
  /// 4. Rollback si falla cualquier paso
  ///
  /// **Parámetros:**
  /// - input: Datos del gossip
  /// - imageBase64: Imagen en base64 (opcional)
  ///
  /// **Retorna:** Gossip creado con URLs de imagen incluidas
  Future<GossipModel> createWithImage(
    CreateGossipInput input,
    String? imageBase64,
  );

  /// Reporta un gossip llamando al Edge Function report-gossip
  ///
  /// **Parámetros:**
  /// - gossipId: ID del gossip a reportar
  /// - reason: Razón del reporte
  /// - details: Detalles adicionales opcionales
  ///
  /// **Lanza:** Exception si la llamada falla
  Future<void> reportGossip({
    required String gossipId,
    required ReportReason reason,
    String? details,
  });

  /// Busca gossips por texto en servidor usando función RPC.
  ///
  /// **Parámetros:**
  /// - query: Texto a buscar en subject y content
  /// - cityId: Filtro opcional por ciudad
  /// - limit: Máximo resultados (default: 20, max: 100)
  ///
  /// **Retorna:** Lista de gossips coincidentes
  ///
  /// **Performance:**
  /// - Búsqueda ejecutada en servidor (PostgreSQL)
  /// - Solo descarga resultados coincidentes
  /// - Más rápido que descargar todo y filtrar en cliente
  Future<List<GossipModel>> searchGossips({
    required String query,
    String? cityId,
    int limit = 20,
  });
}
