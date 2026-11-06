import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../repositories/home_repository.dart';

/// Use case para verificar cuántos chismes nuevos hay.
///
/// **Responsabilidad:**
/// - Delegar al repository la verificación de chismes nuevos
/// - Usado para el banner "X nuevos chismes · Tap aquí"
///
/// **Uso:**
/// ```dart
/// @injectable
/// class PopularTabController {
///   final CheckNewGossips _checkNewGossips;
///   Timer? _pollingTimer;
///
///   void startPolling() {
///     _pollingTimer = Timer.periodic(Duration(seconds: 60), (_) async {
///       if (!_isAppInForeground || !_isOnHomeScreen) return;
///
///       final result = await _checkNewGossips(
///         userId: currentUser?.id,
///         cityId: currentCity?.id,
///         since: _lastLoadTime,
///       );
///
///       result.fold(
///         onFailure: (_) {}, // Silently fail
///         onSuccess: (count) {
///           if (count > 0) {
///             _showBanner(count);
///           }
///         },
///       );
///     });
///   }
/// }
/// ```
@injectable
class CheckNewGossips {
  final HomeRepository _repository;

  CheckNewGossips(this._repository);

  /// Verifica cuántos chismes nuevos hay desde un timestamp.
  ///
  /// Ver documentación completa en [HomeRepository.checkNewGossips].
  Future<Result<Failure, int>> call({
    required String? userId,
    required String? cityId,
    required DateTime since,
  }) async {
    return await _repository.checkNewGossips(
      userId: userId,
      cityId: cityId,
      since: since,
    );
  }
}
