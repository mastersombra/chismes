import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../entities/feed_cursor.dart';
import '../entities/paginated_gossips.dart';

/// Repository para el Home Feed.
///
/// Define los contratos para obtener los diferentes feeds:
/// - Popular: Algoritmo de ranking multi-factor
/// - Following: Chismes de personas que sigo
/// - Recommended: Fallback cuando Following está vacío
/// - CheckNew: Verificar chismes nuevos para el banner
///
/// **Implementación:** Ver `HomeRepositoryImpl` en data layer.
abstract class HomeRepository {
  /// Obtiene el feed popular con algoritmo de ranking.
  ///
  /// **Algoritmo (pesos 40/30/20/10):**
  /// - 40% Ciudad (local=100, trending=50, otras=20)
  /// - 30% Interacciones (likes*1 + comments*2 + shares*3)
  /// - 20% Velocity (interacciones / horas)
  /// - 10% Decay (penalización por antigüedad)
  ///
  /// **Filtro de virales:**
  /// Chismes de otras ciudades solo aparecen si:
  /// - likes > 1000 OR
  /// - comments > 200 OR
  /// - shares > 100 OR
  /// - total interacciones > 500
  ///
  /// **Parámetros:**
  /// - `userId`: ID del usuario (nullable)
  /// - `cityId`: ID de la ciudad del usuario (nullable)
  /// - `pageSize`: Chismes por página (default: 20)
  /// - `cursor`: Cursor de la página anterior (null = primera página)
  ///
  /// **Returns:**
  /// - `Success<PaginatedGossips>`: Feed con chismes paginados
  /// - `Failure`: Error de servidor, red, etc.
  ///
  /// **Ejemplo:**
  /// ```dart
  /// // Primera página
  /// final result = await repository.getPopularFeed(
  ///   userId: currentUser.id,
  ///   cityId: currentUser.cityId,
  /// );
  ///
  /// // Segunda página
  /// final nextResult = await repository.getPopularFeed(
  ///   userId: currentUser.id,
  ///   cityId: currentUser.cityId,
  ///   cursor: result.getOrNull()!.nextCursor,
  /// );
  /// ```
  Future<Result<Failure, PaginatedGossips>> getPopularFeed({
    required String? userId,
    required String? cityId,
    int pageSize = 20,
    FeedCursor? cursor,
  });

  /// Obtiene el feed de personas que sigo.
  ///
  /// **Ordenamiento:** Más recientes primero (created_at DESC)
  ///
  /// **Filtro:**
  /// - Solo chismes de personas que sigo (tabla `user_follows`)
  /// - Status: published
  /// - Moderation: approved
  /// - Visibility: public o followers
  ///
  /// **Parámetros:**
  /// - `userId`: ID del usuario actual (requerido)
  /// - `pageSize`: Chismes por página (default: 20)
  /// - `cursor`: Cursor de la página anterior (null = primera página)
  ///
  /// **Returns:**
  /// - `Success<PaginatedGossips>`: Feed con chismes paginados
  /// - `Failure`: Error de servidor, red, etc.
  ///
  /// **Nota:** Si no sigue a nadie o no hay chismes, retorna lista vacía.
  /// El controller debe manejar el fallback a recommended feed.
  Future<Result<Failure, PaginatedGossips>> getFollowingFeed({
    required String userId,
    int pageSize = 20,
    FeedCursor? cursor,
  });

  /// Obtiene feed recomendado (fallback de Following).
  ///
  /// Usa el mismo algoritmo que Popular pero con menos items.
  ///
  /// **Uso:**
  /// - Tab "Siguiendo" cuando no hay chismes de quienes sigo
  /// - Mostrar badge "Recomendados para ti 💡"
  ///
  /// **Parámetros:**
  /// - `userId`: ID del usuario (nullable)
  /// - `cityId`: ID de la ciudad del usuario (nullable)
  /// - `pageSize`: Chismes por página (default: 20)
  /// - `cursor`: Cursor de la página anterior (null = primera página)
  ///
  /// **Returns:**
  /// - `Success<PaginatedGossips>`: Feed con chismes paginados
  /// - `Failure`: Error de servidor, red, etc.
  Future<Result<Failure, PaginatedGossips>> getRecommendedFeed({
    required String? userId,
    required String? cityId,
    int pageSize = 20,
    FeedCursor? cursor,
  });

  /// Verifica cuántos chismes nuevos hay desde un timestamp.
  ///
  /// **Uso:**
  /// - Banner "X nuevos chismes · Tap aquí"
  /// - Polling cada 60 segundos (solo si app en foreground)
  ///
  /// **Parámetros:**
  /// - `userId`: ID del usuario (nullable)
  /// - `cityId`: ID de la ciudad del usuario (nullable)
  /// - `since`: Timestamp desde cuándo buscar nuevos
  ///
  /// **Returns:**
  /// - `Success<int>`: Cantidad de chismes nuevos
  /// - `Failure`: Error de servidor, red, etc.
  ///
  /// **Ejemplo:**
  /// ```dart
  /// final result = await repository.checkNewGossips(
  ///   userId: currentUser.id,
  ///   cityId: currentUser.cityId,
  ///   since: _lastLoadTime,
  /// );
  ///
  /// result.fold(
  ///   onFailure: (_) => {},
  ///   onSuccess: (count) {
  ///     if (count > 0) {
  ///       _showBanner(count);
  ///     }
  ///   },
  /// );
  /// ```
  Future<Result<Failure, int>> checkNewGossips({
    required String? userId,
    required String? cityId,
    required DateTime since,
  });
}
