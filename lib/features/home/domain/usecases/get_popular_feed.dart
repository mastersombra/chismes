import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/feed_cursor.dart';
import '../entities/paginated_gossips.dart';
import '../repositories/home_repository.dart';

/// Use case para obtener el feed popular.
///
/// **Responsabilidad:**
/// - Delegar al repository la obtención del feed
/// - No contiene lógica de negocio (está en el algoritmo SQL)
///
/// **Uso:**
/// ```dart
/// @injectable
/// class PopularTabController {
///   final GetPopularFeed _getPopularFeed;
///
///   Future<void> loadFeed() async {
///     final result = await _getPopularFeed(
///       userId: currentUser?.id,
///       cityId: currentCity?.id,
///     );
///
///     result.fold(
///       onFailure: (failure) => _handleError(failure),
///       onSuccess: (paginated) => _gossips = paginated.data,
///     );
///   }
/// }
/// ```
@injectable
class GetPopularFeed {
  final HomeRepository _repository;

  GetPopularFeed(this._repository);

  /// Obtiene el feed popular con algoritmo de ranking.
  ///
  /// Ver documentación completa en [HomeRepository.getPopularFeed].
  Future<Result<Failure, PaginatedGossips>> call({
    required String? userId,
    required String? cityId,
    int pageSize = 20,
    FeedCursor? cursor,
  }) async {
    return await _repository.getPopularFeed(
      userId: userId,
      cityId: cityId,
      pageSize: pageSize,
      cursor: cursor,
    );
  }
}
