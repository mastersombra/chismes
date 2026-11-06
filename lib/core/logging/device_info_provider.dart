import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Proveedor de información del dispositivo para logging
///
/// Obtiene información útil para diagnosticar bugs:
/// - OS y versión
/// - Modelo de dispositivo
/// - Versión de la app
/// - Locale
@singleton
class DeviceInfoProvider {
  Map<String, dynamic>? _cachedInfo;

  /// Obtiene información del dispositivo
  ///
  /// **Cache:** Se cachea después de la primera llamada
  /// porque esta info no cambia durante la ejecución
  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_cachedInfo != null) {
      return _cachedInfo!;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();

      Map<String, dynamic> info = {
        'appVersion': packageInfo.version,
        'appBuildNumber': packageInfo.buildNumber,
        'packageName': packageInfo.packageName,
      };

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        info.addAll({
          'os': 'Android',
          'osVersion': androidInfo.version.release,
          'sdkInt': androidInfo.version.sdkInt,
          'device': androidInfo.model,
          'brand': androidInfo.brand,
          'manufacturer': androidInfo.manufacturer,
          'isPhysicalDevice': androidInfo.isPhysicalDevice,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        info.addAll({
          'os': 'iOS',
          'osVersion': iosInfo.systemVersion,
          'device': iosInfo.model,
          'name': iosInfo.name,
          'isPhysicalDevice': iosInfo.isPhysicalDevice,
        });
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        info.addAll({
          'os': 'macOS',
          'osVersion': macInfo.osRelease,
          'device': macInfo.model,
          'arch': macInfo.arch,
        });
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        info.addAll({
          'os': 'Linux',
          'osVersion': linuxInfo.version,
          'device': linuxInfo.name,
        });
      } else if (Platform.isWindows) {
        final windowsInfo = await deviceInfo.windowsInfo;
        info.addAll({
          'os': 'Windows',
          'osVersion': '${windowsInfo.majorVersion}.${windowsInfo.minorVersion}',
          'device': windowsInfo.computerName,
        });
      }

      _cachedInfo = info;
      return info;
    } catch (error) {
      debugPrint('⚠️ Error obteniendo device info: $error');
      return {
        'os': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'error': 'Could not get detailed device info',
      };
    }
  }

  /// Limpia el cache (útil para tests)
  @visibleForTesting
  void clearCache() {
    _cachedInfo = null;
  }
}
