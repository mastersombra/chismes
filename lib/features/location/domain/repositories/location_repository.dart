import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/country.dart';
import '../entities/region.dart';
import '../entities/city.dart';

/// Repositorio para datos de ubicación (países, regiones, ciudades)
///
/// ⚠️ EVOLUCIÓN FUTURA PARA PRODUCCIÓN:
///
/// Actualmente MockLocationRepository devuelve todo en memoria.
/// Para producción con millones de usuarios, no descargar países/regiones/ciudades
/// cada vez que se abre "Agregar chisme".
///
/// La ubicación es relativamente estable (cambia muy raramente).
///
/// Arquitectura futura recomendada:
///
/// Remote (Firestore)
///   ↓
/// Cache local (Hive/SharedPreferences)
///   ↓
/// UI
///
/// Estrategia de caché:
/// - Primera vez: descargar del servidor y guardar en caché local
/// - Aperturas siguientes: usar caché local (instantáneo)
/// - Refrescar: cuando sea necesario (ej: cada 7 días, o manualmente)
/// - Invalidar: si el servidor indica que hay nueva versión
///
/// Beneficios con millones de usuarios:
/// - Reducción drástica de llamadas a Firestore
/// - UI instantánea (sin espera de red)
/// - Ahorro de ancho de banda
/// - Mejor experiencia de usuario
///
/// Implementación futura:
/// - LocationRepository implementa estrategia de caché
/// - RemoteDataSource: Firestore
/// - LocalDataSource: Hive/SharedPreferences
/// - CacheManager: controla TTL y invalidación
abstract class LocationRepository {
  Future<Result<Failure, List<Country>>> getCountries();
  Future<Result<Failure, List<Region>>> getRegionsByCountry(String countryId);
  Future<Result<Failure, List<City>>> getCitiesByRegion(String regionId);

  /// Busca ciudades por nombre (optimizado para autocomplete)
  ///
  /// **Ventajas sobre getCitiesByRegion:**
  /// - Solo retorna ciudades que coinciden con el query
  /// - Búsqueda inteligente con índices
  /// - Límite de resultados configurable
  ///
  /// **Parámetros:**
  /// - [query]: Texto de búsqueda
  /// - [regionId]: Filtrar por región (opcional)
  /// - [maxResults]: Máximo de resultados (default: 20)
  Future<Result<Failure, List<City>>> searchCities({
    required String query,
    String? regionId,
    int maxResults = 20,
  });
}
