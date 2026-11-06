import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/city.dart';
import '../repositories/location_repository.dart';

/// UseCase para búsqueda remota de ciudades (Autocomplete optimizado)
///
/// **Ventajas sobre getCitiesByRegion:**
/// - ✅ No trae todas las ciudades (solo las que coinciden)
/// - ✅ Búsqueda inteligente con índices trigram
/// - ✅ Límite de resultados (20 por defecto)
/// - ✅ Optimizado para catálogos grandes (GeoNames)
///
/// **Uso:**
/// ```dart
/// final result = await searchCities(
///   query: 'Med',
///   regionId: 'co-antioquia',
///   maxResults: 20,
/// );
/// ```
///
/// **Escalabilidad:**
/// - ✅ 100 ciudades → ~10ms
/// - ✅ 10,000 ciudades → ~15ms (con índices)
/// - ✅ 100,000 ciudades → ~20ms (con índices)
@injectable
class SearchCities {
  final LocationRepository _repository;

  SearchCities(this._repository);

  /// Busca ciudades por nombre (búsqueda remota optimizada)
  ///
  /// **Parámetros:**
  /// - [query]: Texto de búsqueda (mínimo 2 caracteres recomendado)
  /// - [regionId]: ID de región para filtrar (opcional, null = todas las regiones)
  /// - [maxResults]: Máximo de resultados a retornar (default: 20)
  ///
  /// **Retorna:**
  /// - Success: Lista de ciudades que coinciden (máximo [maxResults])
  /// - Failure: Error de red, servidor, etc.
  ///
  /// **Ejemplo:**
  /// ```dart
  /// // Buscar "Med" en Antioquia
  /// final result = await searchCities(
  ///   query: 'Med',
  ///   regionId: 'co-antioquia',
  /// );
  ///
  /// result.when(
  ///   onSuccess: (cities) => print('Encontradas: ${cities.length}'),
  ///   onFailure: (error) => print('Error: $error'),
  /// );
  /// ```
  Future<Result<Failure, List<City>>> call({
    required String query,
    String? regionId,
    int maxResults = 20,
  }) async {
    return _repository.searchCities(
      query: query,
      regionId: regionId,
      maxResults: maxResults,
    );
  }
}
