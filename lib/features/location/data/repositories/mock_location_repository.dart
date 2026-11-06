import 'package:injectable/injectable.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/country.dart';
import '../../domain/entities/region.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/location_repository.dart';

// Mock repository - Solo para testing
// Para usar este en lugar de Supabase, cambiar en injection_container.dart
@Named('mock')
@Singleton(as: LocationRepository)
class MockLocationRepository implements LocationRepository {
  @override
  Future<Result<Failure, List<Country>>> getCountries() async {
    return Result.success(const [
      Country(
        id: 'co',
        code: 'CO',
        name: 'Colombia',
      ),
      Country(
        id: 'br',
        code: 'BR',
        name: 'Brasil',
      ),
      Country(
        id: 'pe',
        code: 'PE',
        name: 'Perú',
      ),
      Country(
        id: 'ec',
        code: 'EC',
        name: 'Ecuador',
      ),
    ]);
  }

  @override
  Future<Result<Failure, List<Region>>> getRegionsByCountry(String countryId) async {
    const regions = [
      // Colombia
      Region(
        id: 'antioquia',
        countryId: 'co',
        name: 'Antioquia',
        type: 'department',
      ),
      Region(
        id: 'cundinamarca',
        countryId: 'co',
        name: 'Cundinamarca',
        type: 'department',
      ),
      Region(
        id: 'valle',
        countryId: 'co',
        name: 'Valle del Cauca',
        type: 'department',
      ),
      Region(
        id: 'atlantico',
        countryId: 'co',
        name: 'Atlántico',
        type: 'department',
      ),
      // Brasil
      Region(
        id: 'sao-paulo',
        countryId: 'br',
        name: 'São Paulo',
        type: 'state',
      ),
      Region(
        id: 'rio-de-janeiro',
        countryId: 'br',
        name: 'Rio de Janeiro',
        type: 'state',
      ),
      // Perú
      Region(
        id: 'lima',
        countryId: 'pe',
        name: 'Lima',
        type: 'department',
      ),
      // Ecuador
      Region(
        id: 'pichincha',
        countryId: 'ec',
        name: 'Pichincha',
        type: 'province',
      ),
    ];

    final filtered = regions
        .where((region) => region.countryId == countryId)
        .toList();
    
    return Result.success(filtered);
  }

  @override
  Future<Result<Failure, List<City>>> getCitiesByRegion(String regionId) async {
    const cities = [
      // Colombia - Antioquia
      City(
        id: 'medellin',
        regionId: 'antioquia',
        name: 'Medellín',
      ),
      City(
        id: 'envigado',
        regionId: 'antioquia',
        name: 'Envigado',
      ),
      City(
        id: 'bello',
        regionId: 'antioquia',
        name: 'Bello',
      ),
      // Colombia - Cundinamarca
      City(
        id: 'bogota',
        regionId: 'cundinamarca',
        name: 'Bogotá',
      ),
      City(
        id: 'soacha',
        regionId: 'cundinamarca',
        name: 'Soacha',
      ),
      // Colombia - Valle del Cauca
      City(
        id: 'cali',
        regionId: 'valle',
        name: 'Cali',
      ),
      // Colombia - Atlántico
      City(
        id: 'barranquilla',
        regionId: 'atlantico',
        name: 'Barranquilla',
      ),
      // Brasil - São Paulo
      City(
        id: 'sao-paulo-city',
        regionId: 'sao-paulo',
        name: 'São Paulo',
      ),
      City(
        id: 'campinas',
        regionId: 'sao-paulo',
        name: 'Campinas',
      ),
      // Brasil - Rio de Janeiro
      City(
        id: 'rio-de-janeiro-city',
        regionId: 'rio-de-janeiro',
        name: 'Rio de Janeiro',
      ),
      // Perú - Lima
      City(
        id: 'lima-city',
        regionId: 'lima',
        name: 'Lima',
      ),
      // Ecuador - Pichincha
      City(
        id: 'quito',
        regionId: 'pichincha',
        name: 'Quito',
      ),
    ];

    final filtered = cities
        .where((city) => city.regionId == regionId)
        .toList();

    return Result.success(filtered);
  }

  @override
  Future<Result<Failure, List<City>>> searchCities({
    required String query,
    String? regionId,
    int maxResults = 20,
  }) async {
    const cities = [
      // Colombia - Antioquia
      City(id: 'medellin', regionId: 'antioquia', name: 'Medellín'),
      City(id: 'envigado', regionId: 'antioquia', name: 'Envigado'),
      City(id: 'bello', regionId: 'antioquia', name: 'Bello'),
      // Colombia - Cundinamarca
      City(id: 'bogota', regionId: 'cundinamarca', name: 'Bogotá'),
      City(id: 'soacha', regionId: 'cundinamarca', name: 'Soacha'),
      // Colombia - Valle del Cauca
      City(id: 'cali', regionId: 'valle', name: 'Cali'),
      // Colombia - Atlántico
      City(id: 'barranquilla', regionId: 'atlantico', name: 'Barranquilla'),
      // Brasil - São Paulo
      City(id: 'sao-paulo-city', regionId: 'sao-paulo', name: 'São Paulo'),
      City(id: 'campinas', regionId: 'sao-paulo', name: 'Campinas'),
      // Brasil - Rio de Janeiro
      City(id: 'rio-de-janeiro-city', regionId: 'rio-de-janeiro', name: 'Rio de Janeiro'),
      // Perú - Lima
      City(id: 'lima-city', regionId: 'lima', name: 'Lima'),
      // Ecuador - Pichincha
      City(id: 'quito', regionId: 'pichincha', name: 'Quito'),
    ];

    // Filtrar por región si se especifica
    var filtered = regionId != null
        ? cities.where((city) => city.regionId == regionId)
        : cities;

    // Buscar por nombre (case-insensitive)
    final lowerQuery = query.toLowerCase();
    filtered = filtered.where((city) {
      return city.name.toLowerCase().contains(lowerQuery);
    });

    // Limitar resultados
    final results = filtered.take(maxResults).toList();

    return Result.success(results);
  }
}
