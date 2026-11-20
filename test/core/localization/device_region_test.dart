import 'dart:ui';

import 'package:chismes/core/localization/device_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final region = DeviceRegion();

  tearDown(binding.platformDispatcher.clearLocalesTestValue);

  group('DeviceRegion.countryCode', () {
    test('toma el país del locale del sistema', () {
      binding.platformDispatcher.localesTestValue = const [Locale('es', 'CO')];
      expect(region.countryCode, 'CO');
    });

    test('usa el primer locale que tenga país', () {
      binding.platformDispatcher.localesTestValue = const [
        Locale('es'),
        Locale('en', 'us'),
      ];
      expect(region.countryCode, 'US');
    });

    test('null si ningún locale informa país', () {
      binding.platformDispatcher.localesTestValue = const [Locale('es')];
      expect(region.countryCode, isNull);
    });
  });
}
