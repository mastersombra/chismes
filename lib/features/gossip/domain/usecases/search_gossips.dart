import 'package:injectable/injectable.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/gossip.dart';
import '../repositories/gossip_repository.dart';

/// Use case para buscar gossips por texto usando búsqueda en servidor.
///
/// **Ventajas sobre búsqueda cliente:**
/// - Solo descarga resultados relevantes (vs descargar todos y filtrar)
/// - Más rápido con grandes volúmenes (>1000 gossips)
/// - Gasta menos data y batería
/// - Búsqueda case-insensitive ejecutada en servidor (PostgreSQL)
///
/// **Uso:**
/// ```dart
/// @injectable
/// class SearchController {
///   final SearchGossips _searchGossips;
///
///   Future<void> search(String query) async {
///     final result = await _searchGossips(query: query);
///
///     result.fold(
///       onFailure: (failure) => _handleError(failure),
///       onSuccess: (gossips) => _updateResults(gossips),
///     );
///   }
/// }
/// ```
@injectable
class SearchGossips {
  final GossipRepository repository;

  SearchGossips({required this.repository});

  /// Busca gossips por texto.
  ///
  /// **Parámetros:**
  /// - query: Texto a buscar (min 2 caracteres recomendado)
  /// - cityId: Filtro opcional por ciudad
  /// - limit: Máximo resultados (default: 20, max: 100)
  ///
  /// **Retorna:**
  /// - Success: Lista de gossips coincidentes
  /// - Failure: Error de red, servidor, etc.
  Future<Result<Failure, List<Gossip>>> call({
    required String query,
    String? cityId,
    int limit = 20,
  }) async {
    // Validar query mínimo
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Result.success([]);
    }

    return await repository.searchGossips(
      query: trimmed,
      cityId: cityId,
      limit: limit,
    );
  }
}
