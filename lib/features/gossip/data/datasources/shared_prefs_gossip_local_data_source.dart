import 'dart:convert';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/logging/logging.dart';
import '../models/gossip_model.dart';
import 'gossip_local_data_source.dart';

/// Implementación de GossipLocalDataSource usando SharedPreferences
///
/// **Propósito:**
/// - Cache persistente de gossips para funcionalidad offline
/// - Mejora el tiempo de carga inicial (lee de cache mientras actualiza de red)
/// - Permite usar la app sin conexión (muestra último contenido cacheado)
///
/// **Estrategia de cache:**
/// - Write-through: guarda en cache cada vez que se obtienen datos del remoto
/// - Cache-aside: si falla el remoto, lee del cache
/// - No tiene TTL: el cache se actualiza cada vez que hay conexión
///
/// **Capacidad:**
/// - Guarda ~50-100 gossips recientes
/// - Tamaño estimado: ~100KB (1KB por gossip × 100)
/// - SharedPreferences puede manejar hasta ~1MB sin problemas
///
/// **Formato de almacenamiento:**
/// - Key: 'cached_gossips'
/// - Value: JSON array de gossips: '[{...}, {...}]'
/// - Serialización: GossipModel.toJson() / fromJson()
///
/// **Manejo de errores:**
/// - Si los datos están corruptos → devuelve lista vacía y limpia el cache
/// - Si no hay cache → devuelve lista vacía (no es error)
/// - Logs descriptivos para debugging
///
/// **Producción:**
/// - Este es el data source usado en producción (tiene @Singleton)
/// - MockGossipLocalDataSource solo se usa en tests
@Singleton(as: GossipLocalDataSource)
class SharedPrefsGossipLocalDataSource implements GossipLocalDataSource {
  final AppLogger _logger;

  SharedPrefsGossipLocalDataSource(this._logger);

  /// Key para SharedPreferences
  static const String _cacheKey = 'cached_gossips';

  /// Metadata del cache (útil para futuras mejoras)
  static const String _cacheTimestampKey = 'cached_gossips_timestamp';
  static const String _cacheVersionKey = 'cached_gossips_version';
  static const int _cacheVersion = 1; // Incrementar si cambia formato

  /// Obtiene todos los gossips desde el cache local
  ///
  /// **Retorna:**
  /// - Lista de gossips si hay cache válido
  /// - Lista vacía si:
  ///   - No hay cache (primera vez)
  ///   - Cache está corrupto (limpia automáticamente)
  ///   - Error al leer (limpia automáticamente)
  ///
  /// **Performance:**
  /// - ~10-50ms para 100 gossips
  /// - Mucho más rápido que llamar a Supabase (~2-3s)
  @override
  Future<List<GossipModel>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar versión del cache
      final version = prefs.getInt(_cacheVersionKey) ?? 0;
      if (version != _cacheVersion) {
        _logger.w(
          'Cache version mismatch, clearing cache',
          context: {'expected': _cacheVersion, 'found': version},
        );
        await clear();
        return [];
      }

      final jsonString = prefs.getString(_cacheKey);

      // No hay cache (primera vez)
      if (jsonString == null || jsonString.isEmpty) {
        _logger.d('No hay cache de gossips (primera vez o cache limpio)');
        return [];
      }

      // Deserializar JSON
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final gossips = jsonList
          .map((json) => GossipModel.fromJson(json as Map<String, dynamic>))
          .toList();

      final timestamp = prefs.getString(_cacheTimestampKey) ?? 'desconocido';
      _logger.i(
        'Cache cargado exitosamente',
        context: {'count': gossips.length, 'timestamp': timestamp},
      );

      return gossips;
    } catch (error, stackTrace) {
      // Cache corrupto o error al deserializar
      _logger.e(
        'Error leyendo cache de gossips',
        error: error,
        stackTrace: stackTrace,
        context: {'operation': 'getAll'},
      );

      // Limpiar cache corrupto
      try {
        await clear();
        _logger.i('Cache corrupto limpiado');
      } catch (clearError, clearStackTrace) {
        _logger.e(
          'Error limpiando cache corrupto',
          error: clearError,
          stackTrace: clearStackTrace,
        );
      }

      // Devolver lista vacía (no propagar error, el repositorio usará remoto)
      return [];
    }
  }

  /// Guarda un gossip en el cache local (agrega al inicio)
  ///
  /// **Estrategia:**
  /// - Carga cache actual
  /// - Inserta nuevo gossip al inicio
  /// - Guarda de vuelta
  ///
  /// **Nota:** No se usa mucho, normalmente se usa `saveAll()`.
  /// Se mantiene por compatibilidad con la interfaz.
  @override
  Future<void> save(GossipModel gossip) async {
    try {
      // Cargar cache actual
      final currentGossips = await getAll();

      // Insertar al inicio (más reciente primero)
      currentGossips.insert(0, gossip);

      // Guardar de vuelta
      await saveAll(currentGossips);

      _logger.d('Gossip agregado al cache', context: {'gossipId': gossip.id});
    } catch (error, stackTrace) {
      // Log del error pero no propagar (cache no debe bloquear operaciones)
      _logger.e(
        'Error guardando gossip en cache',
        error: error,
        stackTrace: stackTrace,
        context: {'gossipId': gossip.id, 'operation': 'save'},
      );
    }
  }

  /// Guarda una lista de gossips en el cache local (reemplaza todo)
  ///
  /// **Estrategia:**
  /// - Reemplaza todo el cache con la nueva lista
  /// - Se llama después de obtener datos del remoto
  ///
  /// **Límite de tamaño:**
  /// - Limita a 100 gossips para no exceder capacidad de SharedPreferences
  /// - En producción, puedes ajustar este límite según necesites
  ///
  /// **Performance:**
  /// - ~20-80ms para 100 gossips
  /// - Asíncrono, no bloquea UI
  @override
  Future<void> saveAll(List<GossipModel> gossips) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Limitar tamaño del cache (evitar exceder capacidad)
      const maxCacheSize = 100;
      final gossipsToCache = gossips.length > maxCacheSize
          ? gossips.sublist(0, maxCacheSize)
          : gossips;

      if (gossips.length > maxCacheSize) {
        _logger.w(
          'Cache limitado a máximo permitido',
          context: {'limit': maxCacheSize, 'requested': gossips.length},
        );
      }

      // Serializar a JSON
      final jsonList = gossipsToCache.map((g) => g.toJson()).toList();
      final jsonString = jsonEncode(jsonList);

      // Guardar en SharedPreferences
      final timestamp = DateTime.now().toIso8601String();
      await Future.wait([
        prefs.setString(_cacheKey, jsonString),
        prefs.setString(_cacheTimestampKey, timestamp),
        prefs.setInt(_cacheVersionKey, _cacheVersion),
      ]);

      final sizeKB = (jsonString.length / 1024).toStringAsFixed(2);
      _logger.i(
        'Cache guardado exitosamente',
        context: {
          'count': gossipsToCache.length,
          'sizeKB': sizeKB,
          'timestamp': timestamp,
        },
      );
    } catch (error, stackTrace) {
      // Log del error pero no propagar (cache no debe bloquear operaciones)
      _logger.e(
        'Error guardando cache de gossips',
        error: error,
        stackTrace: stackTrace,
        context: {'operation': 'saveAll', 'count': gossips.length},
      );
    }
  }

  /// Limpia todo el cache local
  ///
  /// **Casos de uso:**
  /// - Testing
  /// - Logout de usuario
  /// - Opción de "Limpiar cache" en settings
  /// - Cache corrupto (limpieza automática)
  @override
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.remove(_cacheKey),
        prefs.remove(_cacheTimestampKey),
        prefs.remove(_cacheVersionKey),
      ]);

      _logger.i('Cache de gossips limpiado');
    } catch (error, stackTrace) {
      _logger.e(
        'Error limpiando cache de gossips',
        error: error,
        stackTrace: stackTrace,
        context: {'operation': 'clear'},
      );
    }
  }

  /// Obtiene información del cache (útil para debugging/settings)
  ///
  /// **Uso futuro:**
  /// - Mostrar en pantalla de settings: "Cache: 50 gossips, 75 KB, hace 2 horas"
  /// - Debugging: ver si el cache está funcionando
  Future<CacheInfo?> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonString = prefs.getString(_cacheKey);
      if (jsonString == null) return null;

      final timestamp = prefs.getString(_cacheTimestampKey);
      final version = prefs.getInt(_cacheVersionKey) ?? 0;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final count = jsonList.length;
      final sizeKB = (jsonString.length / 1024).toStringAsFixed(2);

      return CacheInfo(
        count: count,
        sizeKB: sizeKB,
        timestamp: timestamp,
        version: version,
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Error obteniendo info del cache',
        error: error,
        stackTrace: stackTrace,
        context: {'operation': 'getCacheInfo'},
      );
      return null;
    }
  }
}

/// Información del cache (para debugging/settings)
class CacheInfo {
  final int count;
  final String sizeKB;
  final String? timestamp;
  final int version;

  CacheInfo({
    required this.count,
    required this.sizeKB,
    this.timestamp,
    required this.version,
  });

  @override
  String toString() {
    final time = timestamp != null
        ? DateTime.parse(timestamp!).toLocal().toString()
        : 'desconocido';
    return '$count gossips, $sizeKB KB, guardado: $time, version: $version';
  }
}
