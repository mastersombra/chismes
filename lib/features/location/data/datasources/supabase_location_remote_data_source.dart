import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/logging/logging.dart';
import '../../domain/entities/country.dart';
import '../../domain/entities/region.dart';
import '../../domain/entities/city.dart';

/// Data source para obtener ubicaciones desde Supabase
///
/// **Responsabilidades:**
/// - Consultar tablas: countries, regions, cities
/// - Usar funciones SQL: search_cities(), find_nearest_city()
/// - Manejo de errores de red y Supabase
@singleton
class SupabaseLocationRemoteDataSource {
  final SupabaseClient _supabase;
  final AppLogger _logger;

  SupabaseLocationRemoteDataSource(this._supabase, this._logger);

  /// Obtiene todos los países
  ///
  /// **Query:**
  /// ```sql
  /// SELECT * FROM countries ORDER BY name
  /// ```
  Future<List<Country>> getCountries() async {
    try {
      final response = await _supabase
          .from('countries')
          .select()
          .order('name');

      return (response as List)
          .map((json) => Country.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error obteniendo países', error: e);
      rethrow;
    }
  }

  /// Obtiene regiones (departamentos) de un país
  ///
  /// **Query:**
  /// ```sql
  /// SELECT * FROM regions
  /// WHERE country_id = 'CO'
  /// ORDER BY name
  /// ```
  Future<List<Region>> getRegionsByCountry(String countryId) async {
    try {
      final response = await _supabase
          .from('regions')
          .select()
          .eq('country_id', countryId)
          .order('name');

      return (response as List)
          .map((json) => Region.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error obteniendo regiones', error: e, context: {'countryId': countryId});
      rethrow;
    }
  }

  /// Obtiene ciudades de una región
  ///
  /// **Query:**
  /// ```sql
  /// SELECT * FROM cities
  /// WHERE region_id = 'co-antioquia'
  /// ORDER BY population DESC, name
  /// ```
  ///
  /// **Nota:** Ordena por población (ciudades grandes primero)
  Future<List<City>> getCitiesByRegion(String regionId) async {
    try {
      final response = await _supabase
          .from('cities')
          .select()
          .eq('region_id', regionId)
          .order('population', ascending: false)
          .order('name');

      return (response as List)
          .map((json) => City.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error obteniendo ciudades', error: e, context: {'regionId': regionId});
      rethrow;
    }
  }

  /// Busca ciudades por nombre (Autocomplete)
  ///
  /// **Usa función SQL:** `search_cities(query, region_id, max_results)`
  ///
  /// **Ventajas:**
  /// - Búsqueda inteligente (similaridad de texto)
  /// - Prioriza: 1) Coincidencia exacta, 2) Población, 3) Similitud
  /// - Rápido con índices trigram
  ///
  /// **Ejemplo:**
  /// ```dart
  /// searchCities('Med', 'co-antioquia')
  /// // Retorna: [Medellín, Medina, ...]
  /// ```
  Future<List<City>> searchCities(
    String query,
    String? regionId, {
    int maxResults = 20,
  }) async {
    try {
      final response = await _supabase.rpc(
        'search_cities',
        params: {
          'search_query': query,
          'region_filter': regionId,
          'max_results': maxResults,
        },
      );

      if (response == null) {
        return [];
      }

      return (response as List)
          .map((json) => City.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.e('Error buscando ciudades', error: e, context: {
        'query': query,
        'regionId': regionId,
        'maxResults': maxResults,
      });
      rethrow;
    }
  }

  /// Encuentra la ciudad más cercana a coordenadas GPS (Reverse Geocoding)
  ///
  /// **Usa función SQL:** `find_nearest_city(lat, lon, max_distance_km)`
  ///
  /// **Ventajas:**
  /// - Sin API externa (sin límites de requests)
  /// - Rápido con índice espacial
  /// - Máximo 50km de búsqueda por defecto
  ///
  /// **Ejemplo:**
  /// ```dart
  /// findNearestCity(6.2518, -75.5636)
  /// // Retorna: Medellín (distance_km: 0.02)
  /// ```
  ///
  /// **Retorna:**
  /// - `Map` con ciudad + distancia si encuentra
  /// - `null` si no encuentra ciudad en radio de 50km
  Future<Map<String, dynamic>?> findNearestCity(
    double latitude,
    double longitude, {
    int maxDistanceKm = 50,
  }) async {
    try {
      final response = await _supabase.rpc(
        'find_nearest_city',
        params: {
          'target_lat': latitude,
          'target_lon': longitude,
          'max_distance_km': maxDistanceKm,
        },
      );

      if (response == null || response is! List || response.isEmpty) {
        _logger.w('No se encontró ciudad cercana', context: {
          'latitude': latitude,
          'longitude': longitude,
          'maxDistanceKm': maxDistanceKm,
        });
        return null;
      }

      // La función retorna una lista con 1 elemento (la ciudad más cercana)
      final result = response[0] as Map<String, dynamic>;

      return {
        'city': City.fromJson(result),
        'region_name': result['region_name'] as String,
        'country_name': result['country_name'] as String,
        'distance_km': result['distance_km'] as num,
      };
    } catch (e) {
      _logger.e('Error en reverse geocoding', error: e, context: {
        'latitude': latitude,
        'longitude': longitude,
        'maxDistanceKm': maxDistanceKm,
      });
      rethrow;
    }
  }
}
