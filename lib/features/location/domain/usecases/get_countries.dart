import 'package:injectable/injectable.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/country.dart';
import '../repositories/location_repository.dart';

/// Use case para obtener todos los países
@injectable
class GetCountries {
  final LocationRepository repository;

  GetCountries({required this.repository});

  Future<Result<Failure, List<Country>>> call() {
    return repository.getCountries();
  }
}
