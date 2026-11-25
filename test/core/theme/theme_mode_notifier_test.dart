import 'package:chismes/core/theme/theme_mode_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const key = 'app_theme_mode';

  Future<ThemeModeNotifier> create([Map<String, Object> values = const {}]) async {
    SharedPreferences.setMockInitialValues(values);
    return ThemeModeNotifier(await SharedPreferences.getInstance());
  }

  group('ThemeModeNotifier', () {
    test('sin preferencia guardada usa el tema del sistema', () async {
      // Act
      final notifier = await create();

      // Assert
      expect(notifier.mode, ThemeMode.system);
    });

    test('carga el tema guardado', () async {
      // Act
      final dark = await create({key: 'dark'});
      final light = await create({key: 'light'});

      // Assert
      expect(dark.mode, ThemeMode.dark);
      expect(light.mode, ThemeMode.light);
    });

    test('un valor desconocido vuelve a sistema', () async {
      // Act
      final notifier = await create({key: 'sepia'});

      // Assert
      expect(notifier.mode, ThemeMode.system);
    });

    test('setMode guarda, actualiza y notifica', () async {
      // Arrange
      final notifier = await create();
      var notifications = 0;
      notifier.addListener(() => notifications++);

      // Act
      await notifier.setMode(ThemeMode.dark);

      // Assert
      expect(notifier.mode, ThemeMode.dark);
      expect(notifications, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(key), 'dark');
    });

    test('setMode con el mismo tema no notifica ni guarda', () async {
      // Arrange
      final notifier = await create({key: 'light'});
      var notifications = 0;
      notifier.addListener(() => notifications++);

      // Act
      await notifier.setMode(ThemeMode.light);

      // Assert
      expect(notifications, 0);
      expect(notifier.mode, ThemeMode.light);
    });

    test('la preferencia sobrevive a una nueva instancia', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await ThemeModeNotifier(prefs).setMode(ThemeMode.light);

      // Act
      final reloaded = ThemeModeNotifier(prefs);

      // Assert
      expect(reloaded.mode, ThemeMode.light);
    });
  });
}
