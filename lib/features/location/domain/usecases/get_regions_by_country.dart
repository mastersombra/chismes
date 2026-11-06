import 'package:injectable/injectable.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/region.dart';
import '../repositories/location_repository.dart';

/// Use case para obtener regiones por país
@injectable
class GetRegionsByCountry {
  final LocationRepository repository;

  GetRegionsByCountry({required this.repository});

  Future<Result<Failure, List<Region>>> call(String countryId) {
    return repository.getRegionsByCountry(countryId);
  }
}
