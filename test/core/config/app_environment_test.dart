import 'package:chismes/core/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment.parse', () {
    test('sin ENV definido es dev', () {
      expect(AppEnvironment.parse(''), AppEnvironment.dev);
    });

    test('reconoce dev, staging y prod', () {
      expect(AppEnvironment.parse('dev'), AppEnvironment.dev);
      expect(AppEnvironment.parse('staging'), AppEnvironment.staging);
      expect(AppEnvironment.parse('prod'), AppEnvironment.prod);
    });

    test('un valor desconocido lanza ArgumentError con los válidos', () {
      expect(
        () => AppEnvironment.parse('produccion'),
        throwsA(isA<ArgumentError>().having((e) => e.message, 'message',
            contains('dev, staging, prod'))),
      );
    });
  });

  test('current es dev cuando los tests no pasan --dart-define=ENV', () {
    expect(AppEnvironment.current, AppEnvironment.dev);
  });

  test('isProd solo es true para prod', () {
    expect(AppEnvironment.values.where((e) => e.isProd), [AppEnvironment.prod]);
  });
}
