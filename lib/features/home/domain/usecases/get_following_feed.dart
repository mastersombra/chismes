import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/feed_cursor.dart';
import '../entities/paginated_gossips.dart';
import '../repositories/home_repository.dart';

/// Use case para obtener el feed de personas que sigo.
///
/// **Responsabilidad:**
/// - Delegar al repository la obtención del feed
/// - No contiene lógica de negocio
///
/// **Uso:**
/// ```dart
/// @injectable
/// class FollowingTabController {
///   final GetFollowingFeed _getFollowingFeed;
///
///   Future<void> loadFeed() async {
///     final result = await _getFollowingFeed(
///       userId: currentUser.id,
///     );
///
///     result.fold(
///       onFailure: (failure) => _handleError(failure),
///       onSuccess: (paginated) {
///         if (paginated.isEmpty) {
///           // Cargar recommended feed
///           _loadRecommended();
///         } else {
///           _gossips = paginated.data;
///         }
///       },
///     );
///   }
/// }
/// ```
@injectable
class GetFollowingFeed {
  final HomeRepository _repository;

  GetFollowingFeed(this._repository);

  /// Obtiene el feed de personas que sigo.
  ///
  /// Ver documentación completa en [HomeRepository.getFollowingFeed].
  Future<Result<Failure, PaginatedGossips>> call({
    required String userId,
    int pageSize = 20,
    FeedCursor? cursor,
  }) async {
    return await _repository.getFollowingFeed(
      userId: userId,
      pageSize: pageSize,
      cursor: cursor,
    );
  }
}
