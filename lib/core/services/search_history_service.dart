import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../logging/logging.dart';

/// Servicio para gestionar el historial de búsquedas del usuario.
///
/// Almacena las últimas búsquedas en SharedPreferences para mostrarlas
/// como sugerencias en futuras sesiones.
///
/// **Límite:** Máximo 10 búsquedas guardadas.
///
/// **Uso:**
/// ```dart
/// @injectable
/// class SearchController {
///   final SearchHistoryService _historyService;
///
///   SearchController(this._historyService);
///
///   Future<void> search(String query) async {
///     // Buscar...
///     await _historyService.addSearch(query);
///   }
///
///   Future<List<String>> getHistory() async {
///     return await _historyService.getHistory();
///   }
/// }
/// ```
@singleton
class SearchHistoryService {
  static const String _key = 'search_history';
  static const int _maxHistory = 10;

  final SharedPreferences _prefs;
  final AppLogger _logger;

  SearchHistoryService(this._prefs, this._logger);

  /// Agrega una búsqueda al historial.
  ///
  /// - Si la búsqueda ya existe, la mueve al inicio
  /// - Si el historial llega a más de 10, elimina la más antigua
  /// - Ignora queries vacías o solo espacios
  Future<void> addSearch(String query) async {
    try {
      final trimmed = query.trim();
      if (trimmed.isEmpty) return;

      final history = await getHistory();

      // Remover si ya existe (para moverla al inicio)
      history.remove(trimmed);

      // Agregar al inicio
      history.insert(0, trimmed);

      // Limitar a máximo 10
      if (history.length > _maxHistory) {
        history.removeRange(_maxHistory, history.length);
      }

      await _prefs.setStringList(_key, history);
      _logger.d('Search history updated', context: {'query': trimmed});
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to add search to history',
        error: error,
        stackTrace: stackTrace,
        context: {'query': query},
      );
    }
  }

  /// Obtiene el historial de búsquedas (más recientes primero).
  Future<List<String>> getHistory() async {
    try {
      final history = _prefs.getStringList(_key) ?? [];
      return List<String>.from(history);
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to get search history',
        error: error,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Elimina una búsqueda específica del historial.
  Future<void> removeSearch(String query) async {
    try {
      final history = await getHistory();
      history.remove(query);
      await _prefs.setStringList(_key, history);
      _logger.d('Search removed from history', context: {'query': query});
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to remove search from history',
        error: error,
        stackTrace: stackTrace,
        context: {'query': query},
      );
    }
  }

  /// Limpia todo el historial de búsquedas.
  Future<void> clearHistory() async {
    try {
      await _prefs.remove(_key);
      _logger.i('Search history cleared');
    } catch (error, stackTrace) {
      _logger.e(
        'Failed to clear search history',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
