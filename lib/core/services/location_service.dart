import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import '../logging/logging.dart';

/// Servicio para gestionar geolocalización y persistencia de ubicación
///
/// **POLÍTICA DE PRIVACIDAD Y MINIMIZACIÓN DE DATOS:**
///
/// 1. **Precisión mínima necesaria:**
///    - Usa LocationAccuracy.LOW (red/WiFi, no GPS alta precisión)
///    - Solo necesitamos detectar ciudad, no calle exacta
///    - Android: Solo permiso COARSE_LOCATION
///    - iOS: Solo permiso "When In Use" (no "Always")
///
/// 2. **Coordenadas GPS NUNCA se almacenan:**
///    - Las coordenadas se usan solo temporalmente para reverse geocoding
///    - Después de detectar ciudad, se descartan inmediatamente
///    - NUNCA se envían al servidor
///    - NUNCA se guardan en SharedPreferences
///
/// 3. **Solo se persiste la ciudad:**
///    - Se guarda: ciudad, región, país (nombres + IDs)
///    - NO se guardan: latitud, longitud, timestamp de ubicación
///
/// 4. **Logs seguros:**
///    - En RELEASE: Coordenadas NUNCA se loggean
///    - En DEBUG: Coordenadas solo en logs de nivel DEBUG (troubleshooting)
///    - Logs de nivel INFO NO contienen coordenadas
///
/// 5. **Consentimiento y control:**
///    - Usuario puede denegar permisos de ubicación
///    - Usuario puede elegir ciudad manualmente (sin GPS)
///    - Función clearDefaultLocation() permite "olvidar ubicación"
///
/// **Responsabilidades:**
/// - Detectar ubicación GPS del usuario (solo temporalmente)
/// - Convertir coordenadas a ciudad (reverse geocoding)
/// - Guardar/cargar ubicación por defecto del usuario (solo ciudad)
/// - Manejar permisos de ubicación
///
/// **Persistencia:**
/// - Guarda la última ubicación seleccionada/detectada (solo ciudad)
/// - Se usa como default en futuros chismes (UX tipo Uber/Mercado Libre)
@singleton
class LocationService {
  final AppLogger _logger;

  LocationService(this._logger);

  // Keys para SharedPreferences
  static const String _keyCountryId = 'default_country_id';
  static const String _keyRegionId = 'default_region_id';
  static const String _keyCityId = 'default_city_id';
  static const String _keyCountryName = 'default_country_name';
  static const String _keyRegionName = 'default_region_name';
  static const String _keyCityName = 'default_city_name';

  /// Límite para la petición de permisos. Si Android descarta la petición
  /// (p. ej. otra ya en curso), geolocator nunca completa el Future y la UI
  /// quedaría cargando para siempre. Amplio porque incluye el tiempo que el
  /// usuario tarda en responder el diálogo.
  static const Duration permissionRequestTimeout = Duration(seconds: 60);

  /// Límite para el reverse geocoding (servicio de la plataforma, sin límite propio)
  static const Duration geocodingTimeout = Duration(seconds: 10);

  /// Obtiene la posición GPS actual del usuario
  ///
  /// **Flujo:**
  /// 1. Verifica si el servicio de ubicación está habilitado
  /// 2. Verifica/solicita permisos
  /// 3. Obtiene coordenadas GPS
  ///
  /// **Retorna:**
  /// - `Position` con lat/lon si todo OK
  /// - `null` si:
  ///   - GPS deshabilitado
  ///   - Permisos denegados
  ///   - Error obtener ubicación
  Future<Position?> getCurrentPosition() async {
    try {
      // 1. Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _logger.w('Location service disabled');
        return null;
      }

      // 2. Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Solicitar permisos
        permission = await Geolocator.requestPermission()
            .timeout(permissionRequestTimeout);
        if (permission == LocationPermission.denied) {
          _logger.w('Location permissions denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _logger.w('Location permissions permanently denied');
        return null;
      }

      // 3. Obtener posición
      // ✅ MINIMIZACIÓN: Usar precisión LOW (suficiente para detectar ciudad)
      // No necesitamos alta precisión (calle exacta), solo nivel ciudad
      _logger.d('Getting GPS location');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 10),
      );

      // ✅ PRIVACIDAD: NO loggear coordenadas exactas (nivel INFO)
      // Solo confirmamos que se obtuvo ubicación sin exponer datos sensibles
      _logger.i('GPS location obtained');

      // En DEBUG: Loggear coordenadas solo para troubleshooting
      // En RELEASE: Este log NO se ejecuta (kDebugMode = false)
      if (kDebugMode) {
        _logger.d('DEBUG: Coordinates obtained', context: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        });
      }

      return position;

    } catch (e) {
      _logger.w('Error getting GPS location', context: {'error': e.toString()});
      return null;
    }
  }

  /// Convierte coordenadas GPS a información de ciudad (reverse geocoding)
  ///
  /// **PRIVACIDAD:**
  /// - Las coordenadas GPS NUNCA se almacenan localmente
  /// - NUNCA se envían al servidor
  /// - Solo se usan para detectar la ciudad (reverse geocoding)
  /// - Después de detectar ciudad, las coordenadas se descartan
  ///
  /// **Parámetros:**
  /// - `latitude`: Latitud GPS (solo usada temporalmente)
  /// - `longitude`: Longitud GPS (solo usada temporalmente)
  ///
  /// **Retorna:**
  /// - `DetectedLocation` con ciudad, región, país si OK
  /// - `null` si no se puede determinar la ubicación
  ///
  /// **Nota:** Esta función retorna nombres (no IDs). El controller debe
  /// buscar el ID correspondiente en la lista de ciudades cargadas.
  Future<DetectedLocation?> getCityFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      // ✅ PRIVACIDAD: NO loggear coordenadas exactas
      _logger.d('Executing reverse geocoding');

      // En DEBUG: Loggear coordenadas solo para troubleshooting
      // En RELEASE: Este log NO se ejecuta
      if (kDebugMode) {
        _logger.d('DEBUG: Coordinates for geocoding', context: {
          'latitude': latitude,
          'longitude': longitude,
        });
      }

      final placemarks = await placemarkFromCoordinates(latitude, longitude)
          .timeout(geocodingTimeout);

      if (placemarks.isEmpty) {
        _logger.w('Location information not found');
        return null;
      }

      final place = placemarks.first;

      // Extraer información
      final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
      final region = place.administrativeArea; // Estado/Departamento
      final country = place.country;

      if (city == null || region == null || country == null) {
        _logger.w('Incomplete location information');
        return null;
      }

      final location = DetectedLocation(
        cityName: city,
        regionName: region,
        countryName: country,
      );

      _logger.i('Location detected', context: {
        'city': city,
        'region': region,
        'country': country,
      });
      return location;

    } catch (e) {
      _logger.w('Reverse geocoding error', context: {'error': e.toString()});
      return null;
    }
  }

  /// Guarda la ubicación por defecto del usuario
  ///
  /// **Cuándo se llama:**
  /// - Primera vez que se detecta ubicación GPS
  /// - Cuando usuario cambia manualmente la ciudad
  ///
  /// **Efecto:**
  /// - La próxima vez que cree un chisme, se usará esta ubicación por defecto
  ///
  /// **Modo Anónimo:**
  /// - Si el usuario activó modo anónimo, NO se guarda ubicación
  /// - Se pide ubicación cada vez que crea un chisme
  Future<void> saveDefaultLocation({
    required String countryId,
    required String regionId,
    required String cityId,
    required String countryName,
    required String regionName,
    required String cityName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ MODO ANÓNIMO: No guardar ubicación si está activado
      final anonymousMode = prefs.getBool('anonymous_mode') ?? false;
      if (anonymousMode) {
        _logger.i('Anonymous mode enabled: Not saving location');
        return;
      }

      await Future.wait([
        prefs.setString(_keyCountryId, countryId),
        prefs.setString(_keyRegionId, regionId),
        prefs.setString(_keyCityId, cityId),
        prefs.setString(_keyCountryName, countryName),
        prefs.setString(_keyRegionName, regionName),
        prefs.setString(_keyCityName, cityName),
      ]);

      _logger.i('Default location saved', context: {
        'cityName': cityName,
        'regionName': regionName,
        'countryName': countryName,
      });
    } catch (e) {
      _logger.w('Error saving default location', context: {'error': e.toString()});
    }
  }

  /// Carga la ubicación por defecto del usuario
  ///
  /// **Retorna:**
  /// - `SavedLocation` si hay ubicación guardada
  /// - `null` si es la primera vez (no hay ubicación guardada)
  Future<SavedLocation?> getDefaultLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final countryId = prefs.getString(_keyCountryId);
      final regionId = prefs.getString(_keyRegionId);
      final cityId = prefs.getString(_keyCityId);
      final countryName = prefs.getString(_keyCountryName);
      final regionName = prefs.getString(_keyRegionName);
      final cityName = prefs.getString(_keyCityName);

      // Si no hay ubicación guardada (primera vez)
      if (countryId == null || regionId == null || cityId == null) {
        _logger.d('No default location saved (first time)');
        return null;
      }

      final location = SavedLocation(
        countryId: countryId,
        regionId: regionId,
        cityId: cityId,
        countryName: countryName ?? '',
        regionName: regionName ?? '',
        cityName: cityName ?? '',
      );

      _logger.i('Default location loaded', context: {
        'cityName': location.cityName,
        'regionName': location.regionName,
      });
      return location;

    } catch (e) {
      _logger.w('Error loading default location', context: {'error': e.toString()});
      return null;
    }
  }

  /// Limpia la ubicación por defecto guardada
  ///
  /// **Útil para:**
  /// - Testing
  /// - Opción de "Olvidar mi ubicación" en settings
  Future<void> clearDefaultLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await Future.wait([
        prefs.remove(_keyCountryId),
        prefs.remove(_keyRegionId),
        prefs.remove(_keyCityId),
        prefs.remove(_keyCountryName),
        prefs.remove(_keyRegionName),
        prefs.remove(_keyCityName),
      ]);

      _logger.i('Default location removed');
    } catch (e) {
      _logger.w('Error removing default location', context: {'error': e.toString()});
    }
  }
}

/// Ubicación detectada por GPS (solo nombres, sin IDs)
class DetectedLocation {
  final String cityName;
  final String regionName;
  final String countryName;

  DetectedLocation({
    required this.cityName,
    required this.regionName,
    required this.countryName,
  });
}

/// Ubicación guardada en SharedPreferences (con IDs y nombres)
class SavedLocation {
  final String countryId;
  final String regionId;
  final String cityId;
  final String countryName;
  final String regionName;
  final String cityName;

  SavedLocation({
    required this.countryId,
    required this.regionId,
    required this.cityId,
    required this.countryName,
    required this.regionName,
    required this.cityName,
  });

  /// Texto para mostrar en UI: "Ciudad, Región, País"
  String get displayText => '$cityName, $regionName, $countryName';

  /// Texto compacto: "Ciudad, Región"
  String get compactText => '$cityName, $regionName';
}
