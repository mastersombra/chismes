import 'package:injectable/injectable.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/error_handler.dart';
import '../../domain/entities/country.dart';
import '../../domain/entities/region.dart';
import '../../domain/entities/city.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/supabase_location_remote_data_source.dart';

/// Implementación de LocationRepository usando Supabase
///
/// **Reemplaza:** MockLocationRepository
///
/// **Responsabilidades:**
/// - Orquestar llamadas al datasource
/// - Convertir excepciones a Failure
/// - Retornar `Result<Failure, Data>`
@Singleton(as: LocationRepository)
class SupabaseLocationRepository implements LocationRepository {
  final SupabaseLocationRemoteDataSource _remoteDataSource;

  SupabaseLocationRepository(this._remoteDataSource);

  @override
  Future<Result<Failure, List<Country>>> getCountries() async {
    try {
      final countries = await _remoteDataSource.getCountries();
      return Result.success(countries);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handleError(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<Failure, List<Region>>> getRegionsByCountry(String countryId) async {
    try {
      final regions = await _remoteDataSource.getRegionsByCountry(countryId);
      return Result.success(regions);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handleError(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<Failure, List<City>>> getCitiesByRegion(String regionId) async {
    try {
      final cities = await _remoteDataSource.getCitiesByRegion(regionId);
      return Result.success(cities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handleError(e, stackTrace);
      return Result.failure(failure);
    }
  }

  @override
  Future<Result<Failure, List<City>>> searchCities({
    required String query,
    String? regionId,
    int maxResults = 20,
  }) async {
    try {
      final cities = await _remoteDataSource.searchCities(
        query,
        regionId,
        maxResults: maxResults,
      );
      return Result.success(cities);
    } catch (e, stackTrace) {
      final failure = ErrorHandler.handleError(e, stackTrace);
      return Result.failure(failure);
    }
  }
}
