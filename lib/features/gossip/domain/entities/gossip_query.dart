import 'gossip.dart';

/// DTO para consultas de gossips con filtros y paginación.
///
/// Diseñado para producción con millones de usuarios. Permite filtrar en el
/// servidor (Firestore/API) en lugar de descargar todos los registros y filtrar
/// en el cliente.
///
/// Ejemplo de uso:
/// ```dart
/// final query = GossipQuery(
///   cityId: 'medellin',
///   status: GossipStatus.published,
///   visibility: GossipVisibility.public,
///   limit: 20,
///   orderBy: 'createdAt',
///   descending: true,
/// );
/// ```
class GossipQuery {
  /// Filtros de ubicación (mutuamente excluyentes en producción)
  final String? countryId;
  final String? regionId;
  final String? cityId;

  /// Filtros de estado
  final GossipStatus? status;
  final GossipVisibility? visibility;

  /// Paginación (Keyset Pagination)
  final int limit;

  /// Cursor para keyset pagination (timestamp + id)
  /// Format: "timestamp,id" ejemplo: "2024-01-01T00:00:00.000Z,uuid-here"
  final String? cursor;

  /// Timestamp del último registro (para keyset)
  final DateTime? lastCreatedAt;

  /// ID del último registro (para keyset)
  final String? lastId;

  /// Ordenamiento
  final String orderBy;
  final bool descending;

  const GossipQuery({
    this.countryId,
    this.regionId,
    this.cityId,
    this.status,
    this.visibility,
    this.limit = 20,
    this.cursor,
    this.lastCreatedAt,
    this.lastId,
    this.orderBy = 'createdAt',
    this.descending = true,
  });

  /// Constructor para query por defecto (superficie pública)
  factory GossipQuery.defaultPublic() {
    return const GossipQuery(
      status: GossipStatus.published,
      visibility: GossipVisibility.public,
      limit: 20,
      orderBy: 'createdAt',
      descending: true,
    );
  }

  /// Constructor para query por ciudad
  factory GossipQuery.byCity(String cityId) {
    return GossipQuery(
      cityId: cityId,
      status: GossipStatus.published,
      visibility: GossipVisibility.public,
      limit: 20,
      orderBy: 'createdAt',
      descending: true,
    );
  }

  /// Constructor para query por región
  factory GossipQuery.byRegion(String regionId) {
    return GossipQuery(
      regionId: regionId,
      status: GossipStatus.published,
      visibility: GossipVisibility.public,
      limit: 20,
      orderBy: 'createdAt',
      descending: true,
    );
  }

  /// Constructor para query por país
  factory GossipQuery.byCountry(String countryId) {
    return GossipQuery(
      countryId: countryId,
      status: GossipStatus.published,
      visibility: GossipVisibility.public,
      limit: 20,
      orderBy: 'createdAt',
      descending: true,
    );
  }

  /// Copia con cursor para paginación (infinite scroll)
  ///
  /// **Keyset Pagination:** Usa (created_at, id) como cursor compuesto
  /// Esto es más eficiente que OFFSET y evita duplicados/saltos
  GossipQuery copyWithCursor(String cursor) {
    return GossipQuery(
      countryId: countryId,
      regionId: regionId,
      cityId: cityId,
      status: status,
      visibility: visibility,
      limit: limit,
      cursor: cursor,
      orderBy: orderBy,
      descending: descending,
    );
  }

  /// Copia con último registro (keyset pagination)
  ///
  /// Uso:
  /// ```dart
  /// final query = GossipQuery.defaultPublic();
  /// final result = await getGossips(query);
  ///
  /// // Siguiente página
  /// if (result.isSuccess && result.data.isNotEmpty) {
  ///   final lastGossip = result.data.last;
  ///   final nextQuery = query.copyWithLast(
  ///     lastGossip.createdAt,
  ///     lastGossip.id,
  ///   );
  /// }
  /// ```
  GossipQuery copyWithLast(DateTime lastCreatedAt, String lastId) {
    return GossipQuery(
      countryId: countryId,
      regionId: regionId,
      cityId: cityId,
      status: status,
      visibility: visibility,
      limit: limit,
      lastCreatedAt: lastCreatedAt,
      lastId: lastId,
      orderBy: orderBy,
      descending: descending,
    );
  }

  @override
  String toString() {
    return 'GossipQuery(countryId: $countryId, regionId: $regionId, cityId: $cityId, '
        'status: $status, visibility: $visibility, limit: $limit, cursor: $cursor, '
        'orderBy: $orderBy, descending: $descending)';
  }
}
