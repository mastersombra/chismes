import 'package:injectable/injectable.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/city.dart';
import '../repositories/location_repository.dart';

/// Use case para obtener ciudades por región
@injectable
class GetCitiesByRegion {
  final LocationRepository repository;

  GetCitiesByRegion({required this.repository});

  Future<Result<Failure, List<City>>> call(String regionId) {
    return repository.getCitiesByRegion(regionId);
  }
}
