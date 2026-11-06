import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/feed_cursor.dart';
import '../entities/paginated_gossips.dart';
import '../repositories/home_repository.dart';

/// Use case para obtener el feed recomendado (fallback de Following).
///
/// **Responsabilidad:**
/// - Delegar al repository la obtención del feed recomendado
/// - Usa el mismo algoritmo que Popular pero típicamente con menos items
///
/// **Uso:**
/// ```dart
/// @injectable
/// class FollowingTabController {
///   final GetRecommendedFeed _getRecommendedFeed;
///
///   Future<void> _loadRecommended() async {
///     final result = await _getRecommendedFeed(
///       userId: currentUser?.id,
///       cityId: currentCity?.id,
///       pageSize: 20,
///     );
///
///     result.fold(
///       onFailure: (failure) => _handleError(failure),
///       onSuccess: (paginated) {
///         _recommendedGossips = paginated.data;
///         _state = FollowingTabState.loadedRecommended;
///       },
///     );
///   }
/// }
/// ```
@injectable
class GetRecommendedFeed {
  final HomeRepository _repository;

  GetRecommendedFeed(this._repository);

  /// Obtiene el feed recomendado.
  ///
  /// Ver documentación completa en [HomeRepository.getRecommendedFeed].
  Future<Result<Failure, PaginatedGossips>> call({
    required String? userId,
    required String? cityId,
    int pageSize = 20,
    FeedCursor? cursor,
  }) async {
    return await _repository.getRecommendedFeed(
      userId: userId,
      cityId: cityId,
      pageSize: pageSize,
      cursor: cursor,
    );
  }
}
