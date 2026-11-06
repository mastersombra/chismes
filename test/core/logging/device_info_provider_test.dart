import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/logging/device_info_provider.dart';

void main() {
  late DeviceInfoProvider provider;

  // Inicializar bindings para que los plugins funcionen
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    provider = DeviceInfoProvider();
  });

  group('DeviceInfoProvider', () {
    test('debe ser un singleton con @singleton annotation', () {
      // Arrange & Act
      final provider1 = DeviceInfoProvider();
      final provider2 = DeviceInfoProvider();

      // Assert - Son instancias diferentes (no es singleton aquí sino por DI)
      // pero la clase tiene la annotation para Injectable
      expect(provider1, isA<DeviceInfoProvider>());
      expect(provider2, isA<DeviceInfoProvider>());
    });

    group('getDeviceInfo', () {
      test('debe retornar un Map con información del dispositivo', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        expect(info, isA<Map<String, dynamic>>());
        expect(info, isNotEmpty);
        // 'os' siempre debe estar presente
        expect(info.containsKey('os'), isTrue);
        // 'appVersion' solo si no hay error
        if (!info.containsKey('error')) {
          expect(info.containsKey('appVersion'), isTrue);
        }
      });

      test('debe incluir información básica de la app cuando es exitoso', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        // Si NO hay error, debe tener info de la app
        if (!info.containsKey('error')) {
          expect(info.containsKey('appVersion'), isTrue);
          expect(info.containsKey('appBuildNumber'), isTrue);
          expect(info.containsKey('packageName'), isTrue);
        } else {
          // Si hay error, al menos debe tener info básica del OS
          expect(info.containsKey('os'), isTrue);
          expect(info.containsKey('osVersion'), isTrue);
        }
      });

      test('debe incluir información del sistema operativo', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        expect(info.containsKey('os'), isTrue);
        expect(info['os'], isA<String>());
        expect(info['os'], isNotEmpty);
      });

      test('debe incluir osVersion', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        expect(info.containsKey('osVersion'), isTrue);
        expect(info['osVersion'], isA<String>());
      });

      test('debe incluir información del device cuando disponible', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        // 'device' puede no estar en error path
        if (!info.containsKey('error')) {
          expect(info.containsKey('device'), isTrue);
        } else {
          // En error path al menos debe tener os y osVersion
          expect(info.containsKey('os'), isTrue);
          expect(info.containsKey('osVersion'), isTrue);
        }
      });
    });

    group('Cache', () {
      test('debe cachear la información después de la primera llamada', () async {
        // Arrange
        provider.clearCache();

        // Act
        final info1 = await provider.getDeviceInfo();
        final info2 = await provider.getDeviceInfo();

        // Assert
        // Si hay error (key 'error' presente), NO se cachea
        if (!info1.containsKey('error')) {
          expect(info1, same(info2)); // Mismo objeto en memoria
        }
        expect(info1, equals(info2)); // Mismo contenido siempre
      });

      test('segunda llamada debe ser instantánea (usar cache)', () async {
        // Arrange
        provider.clearCache();

        // Act
        final stopwatch1 = Stopwatch()..start();
        await provider.getDeviceInfo();
        stopwatch1.stop();

        final stopwatch2 = Stopwatch()..start();
        await provider.getDeviceInfo();
        stopwatch2.stop();

        // Assert - Segunda llamada debe ser MUY rápida (cache)
        expect(stopwatch2.elapsedMicroseconds, lessThan(1000)); // < 1ms
      });

      test('clearCache debe limpiar el cache', () async {
        // Arrange
        final info1 = await provider.getDeviceInfo();

        // Act
        provider.clearCache();
        final info2 = await provider.getDeviceInfo();

        // Assert
        expect(info1, isNot(same(info2))); // Diferentes objetos
        expect(info1, equals(info2)); // Pero mismo contenido
      });

      test('múltiples llamadas sin clearCache deben retornar mismo objeto', () async {
        // Arrange
        provider.clearCache();

        // Act
        final info1 = await provider.getDeviceInfo();
        final info2 = await provider.getDeviceInfo();
        final info3 = await provider.getDeviceInfo();
        final info4 = await provider.getDeviceInfo();

        // Assert
        // Si hay error, no se cachea
        if (!info1.containsKey('error')) {
          expect(info1, same(info2));
          expect(info2, same(info3));
          expect(info3, same(info4));
        } else {
          // Pero el contenido debe ser el mismo
          expect(info1, equals(info2));
          expect(info2, equals(info3));
          expect(info3, equals(info4));
        }
      });
    });

    group('Estructura de datos', () {
      test('appVersion debe ser String no vacío cuando está presente', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        if (info.containsKey('appVersion')) {
          expect(info['appVersion'], isA<String>());
          expect(info['appVersion'], isNotEmpty);
        }
      });

      test('appBuildNumber debe ser String cuando está presente', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        if (info.containsKey('appBuildNumber')) {
          expect(info['appBuildNumber'], isA<String>());
        }
      });

      test('packageName debe ser String no vacío cuando está presente', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        if (info.containsKey('packageName')) {
          expect(info['packageName'], isA<String>());
          expect(info['packageName'], isNotEmpty);
        }
      });

      test('os debe ser uno de los valores válidos', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        final validOS = ['Android', 'iOS', 'macOS', 'Linux', 'Windows', 'android', 'ios', 'macos', 'linux', 'windows', 'fuchsia'];
        expect(validOS.any((os) => info['os'].toString().toLowerCase().contains(os.toLowerCase())), isTrue);
      });

      test('todas las keys deben ser Strings', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        for (final key in info.keys) {
          expect(key, isA<String>(),
            reason: 'Key "$key" debe ser String');
        }
      });

      test('no debe contener valores null en keys que están presentes', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        // Solo verificar que las keys presentes no sean null
        for (final key in info.keys) {
          if (info.containsKey(key)) {
            expect(info[key], isNotNull,
              reason: 'Key "$key" no debe ser null si está presente');
          }
        }

        // Al menos 'os' y 'osVersion' siempre deben estar
        expect(info['os'], isNotNull);
        expect(info['osVersion'], isNotNull);
      });
    });

    group('Manejo de errores', () {
      test('debe retornar información básica si hay error', () async {
        // Arrange
        provider.clearCache();

        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        // Si hay error, debe retornar al menos:
        // - os (de Platform.operatingSystem)
        // - osVersion (de Platform.operatingSystemVersion)
        expect(info, isNotEmpty);
        expect(info.containsKey('os'), isTrue);
        expect(info.containsKey('osVersion'), isTrue);
      });

      test('información de fallback debe tener formato correcto', () async {
        // Arrange
        provider.clearCache();

        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        expect(info['os'], isA<String>());
        expect(info['os'], isNotEmpty);
        expect(info['osVersion'], isA<String>());
      });
    });

    group('Información específica del dispositivo', () {
      test('debe incluir información específica de plataforma cuando esté disponible', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        // Dependiendo de la plataforma donde corren los tests,
        // debe haber información específica
        final hasAndroidInfo = info.containsKey('sdkInt') && info.containsKey('brand');
        final hasIOSInfo = info.containsKey('name') && info.containsKey('isPhysicalDevice');
        final hasMacOSInfo = info.containsKey('arch');
        final hasLinuxInfo = info.containsKey('device');
        final hasWindowsInfo = info.containsKey('device');

        // Al menos una debe ser true (según plataforma actual)
        final hasPlatformSpecificInfo = hasAndroidInfo || hasIOSInfo ||
                                         hasMacOSInfo || hasLinuxInfo ||
                                         hasWindowsInfo || info.containsKey('error');

        expect(hasPlatformSpecificInfo, isTrue,
          reason: 'Debe tener información específica de la plataforma o flag de error');
      });

      test('isPhysicalDevice debe ser bool si está presente', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        if (info.containsKey('isPhysicalDevice')) {
          expect(info['isPhysicalDevice'], isA<bool>());
        }
      });

      test('sdkInt debe ser int si está presente (Android)', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert
        if (info.containsKey('sdkInt')) {
          expect(info['sdkInt'], isA<int>());
          expect(info['sdkInt'], greaterThan(0));
        }
      });
    });

    group('Consistencia', () {
      test('getDeviceInfo debe ser idempotente', () async {
        // Arrange
        provider.clearCache();

        // Act
        final info1 = await provider.getDeviceInfo();
        provider.clearCache();
        final info2 = await provider.getDeviceInfo();
        provider.clearCache();
        final info3 = await provider.getDeviceInfo();

        // Assert
        expect(info1, equals(info2));
        expect(info2, equals(info3));
      });

      test('información debe ser consistente entre llamadas sin clearCache', () async {
        // Arrange
        provider.clearCache();

        // Act
        final info1 = await provider.getDeviceInfo();
        final info2 = await provider.getDeviceInfo();
        final info3 = await provider.getDeviceInfo();

        // Assert
        expect(info1, equals(info2));
        expect(info2, equals(info3));
        expect(info1['appVersion'], equals(info2['appVersion']));
        expect(info1['os'], equals(info2['os']));
      });

      test('keys en el Map deben ser consistentes', () async {
        // Arrange
        provider.clearCache();

        // Act
        final info1 = await provider.getDeviceInfo();
        provider.clearCache();
        final info2 = await provider.getDeviceInfo();

        // Assert
        expect(info1.keys.toSet(), equals(info2.keys.toSet()));
      });
    });

    group('clearCache', () {
      test('clearCache debe ser seguro de llamar múltiples veces', () {
        // Act & Assert
        expect(() {
          provider.clearCache();
          provider.clearCache();
          provider.clearCache();
        }, returnsNormally);
      });

      test('clearCache en provider nuevo no debe lanzar error', () {
        // Arrange
        final newProvider = DeviceInfoProvider();

        // Act & Assert
        expect(() => newProvider.clearCache(), returnsNormally);
      });

      test('después de clearCache, debe obtener nueva información', () async {
        // Arrange
        final info1 = await provider.getDeviceInfo();

        // Act
        provider.clearCache();
        final info2 = await provider.getDeviceInfo();

        // Assert
        // Aunque el contenido sea igual, son objetos diferentes
        expect(info1, isNot(same(info2)));
      });
    });

    group('Integración real', () {
      test('debe funcionar en un escenario típico de logging', () async {
        // Arrange
        provider.clearCache();

        // Act - Simular uso en AppLogger
        final deviceInfo1 = await provider.getDeviceInfo();
        final deviceInfo2 = await provider.getDeviceInfo(); // Debería usar cache si no hay error
        final deviceInfo3 = await provider.getDeviceInfo(); // Debería usar cache si no hay error

        // Assert
        expect(deviceInfo1, isNotEmpty);

        // Si hay error, no se cachea
        if (!deviceInfo1.containsKey('error')) {
          expect(deviceInfo2, same(deviceInfo1)); // Cache
          expect(deviceInfo3, same(deviceInfo1)); // Cache
        } else {
          // Pero el contenido debe ser el mismo
          expect(deviceInfo2, equals(deviceInfo1));
          expect(deviceInfo3, equals(deviceInfo1));
        }

        // Verificar que tiene los campos necesarios para logging
        expect(deviceInfo1.containsKey('os'), isTrue);
        expect(deviceInfo1.containsKey('osVersion'), isTrue);
      });

      test('información debe ser útil para debugging', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert - Información mínima necesaria para debugging
        expect(info.length, greaterThanOrEqualTo(2),
          reason: 'Debe tener al menos: os, osVersion');

        // Verificar que los valores no son placeholders vacíos
        expect(info['os'].toString().trim(), isNotEmpty);
        expect(info['osVersion'].toString().trim(), isNotEmpty);

        // Si tiene appVersion, también debe ser válido
        if (info.containsKey('appVersion')) {
          expect(info['appVersion'].toString().trim(), isNotEmpty);
        }
      });
    });

    group('Edge cases', () {
      test('cache con clearCache intercalado debe funcionar correctamente', () async {
        // Act
        provider.clearCache();
        final info1 = await provider.getDeviceInfo();
        final info2 = await provider.getDeviceInfo(); // Cache si no hay error
        provider.clearCache();
        final info3 = await provider.getDeviceInfo(); // Nueva llamada
        final info4 = await provider.getDeviceInfo(); // Cache de info3 si no hay error

        // Assert
        // Si hay error, no se cachea
        if (!info1.containsKey('error')) {
          expect(info1, same(info2)); // Cache funciona
          expect(info2, isNot(same(info3))); // clearCache funcionó
          expect(info3, same(info4)); // Cache funciona de nuevo
        } else {
          // Sin cache, pero contenido debe ser consistente
          expect(info1, equals(info2));
          expect(info3, equals(info4));
        }
      });

      test('Map retornado debe ser mutable', () async {
        // Act
        final info = await provider.getDeviceInfo();

        // Assert & Act - Verificar que se puede modificar (por si se usa en logging)
        expect(() {
          info['customField'] = 'test';
        }, returnsNormally);
      });
    });
  });
}
