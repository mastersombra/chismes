import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/logging/logging.dart';

void main() {
  group('AppLogger', () {
    late AppLogger logger;
    late MockRemoteLogger mockRemoteLogger;
    late MockDeviceInfoProvider mockDeviceInfo;

    setUp(() {
      mockRemoteLogger = MockRemoteLogger();
      mockDeviceInfo = MockDeviceInfoProvider();
      logger = AppLogger(mockRemoteLogger, mockDeviceInfo);
    });

    tearDown(() {
      logger.close();
    });

    group('Constructor', () {
      test('debe crear instancia con dependencias', () {
        expect(logger, isNotNull);
        expect(logger, isA<AppLogger>());
      });
    });

    group('setUserId', () {
      test('debe incluir userId si está establecido', () async {
        // Arrange
        logger.setUserId('user-123');

        // Act
        logger.e('Error with user');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.first.userId, 'user-123');
      });

      test('debe permitir userId null', () {
        // Act & Assert
        expect(() => logger.setUserId(null), returnsNormally);
      });

      test('debe cambiar userId múltiples veces', () async {
        // Arrange
        logger.setUserId('user1');
        logger.e('Error 1');
        await Future.delayed(const Duration(milliseconds: 50));

        logger.setUserId('user2');
        logger.e('Error 2');
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(mockRemoteLogger.logs[0].userId, 'user1');
        expect(mockRemoteLogger.logs[1].userId, 'user2');
      });

      test('debe permitir establecer userId a null después de tener uno', () async {
        // Arrange
        logger.setUserId('user123');
        logger.e('Error 1');
        await Future.delayed(const Duration(milliseconds: 50));

        logger.setUserId(null);
        logger.e('Error 2');
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(mockRemoteLogger.logs[0].userId, 'user123');
        expect(mockRemoteLogger.logs[1].userId, isNull);
      });
    });

    group('Métodos de logging - d()', () {
      test('debe loguear debug', () {
        // Act
        logger.d('Test debug message');

        // Assert - No se persiste (debug no debería persistir)
        expect(mockRemoteLogger.logs, isEmpty);
      });

      test('debe loguear debug con error', () {
        // Arrange
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;

        // Act
        logger.d('Debug with error', error: error, stackTrace: stackTrace);

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
      });

      test('debe loguear debug con context', () {
        // Act
        logger.d('Debug with context', context: {'key': 'value'});

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
      });

      test('debe loguear debug con todo', () {
        // Act
        logger.d(
          'Debug complete',
          error: Exception('Error'),
          stackTrace: StackTrace.current,
          context: {'operation': 'test'},
        );

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
      });
    });

    group('Métodos de logging - i()', () {
      test('debe loguear info', () {
        // Act
        logger.i('Test info message');

        // Assert - No se persiste (info no debería persistir)
        expect(mockRemoteLogger.logs, isEmpty);
      });

      test('debe loguear info con error', () {
        // Act
        logger.i('Info with error', error: Exception('Test'));

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
      });

      test('debe loguear info con context', () {
        // Act
        logger.i('Info with context', context: {'operation': 'test'});

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
      });

      test('debe loguear info completo', () {
        // Act
        logger.i(
          'Info complete',
          error: Exception('Error'),
          stackTrace: StackTrace.current,
          context: {'key': 'value'},
        );

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
      });
    });

    group('Métodos de logging - w()', () {
      test('debe loguear warning', () {
        // Act
        logger.w('Test warning message');

        // Assert - No se persiste (warning no debería persistir)
        expect(mockRemoteLogger.logs, isEmpty);
      });

      test('debe loguear warning con error', () {
        // Act
        logger.w('Warning with error', error: Exception('Test'));

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
      });

      test('debe loguear warning con context', () {
        // Act
        logger.w('Warning with context', context: {'reason': 'cache_miss'});

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
      });

      test('debe loguear warning completo', () {
        // Act
        logger.w(
          'Warning complete',
          error: Exception('Error'),
          stackTrace: StackTrace.current,
          context: {'operation': 'cache', 'action': 'clear'},
        );

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
      });
    });

    group('Métodos de logging - e()', () {
      test('debe loguear y persistir error', () async {
        // Act
        logger.e('Test error message');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Error SÍ se persiste
        expect(mockRemoteLogger.logs.length, 1);
        expect(mockRemoteLogger.logs.first.level, LogLevel.error);
        expect(mockRemoteLogger.logs.first.message, 'Test error message');
      });

      test('debe loguear error con exception', () async {
        // Arrange
        final error = Exception('Test exception');
        final stackTrace = StackTrace.current;

        // Act
        logger.e('Error occurred', error: error, stackTrace: stackTrace);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.length, 1);
        final logEntry = mockRemoteLogger.logs.first;
        expect(logEntry.error, error);
        expect(logEntry.stackTrace, stackTrace);
      });

      test('debe incluir context en el log', () async {
        // Arrange
        final context = {
          'gossipId': '123',
          'cityId': 'MED',
        };

        // Act
        logger.e('Error with context', context: context);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.first.context, context);
      });

      test('debe incluir deviceInfo', () async {
        // Act
        logger.e('Error with device info');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final logEntry = mockRemoteLogger.logs.first;
        expect(logEntry.deviceInfo, isNotNull);
        expect(logEntry.deviceInfo!['os'], 'TestOS');
      });

      test('debe loguear error completo', () async {
        // Arrange
        logger.setUserId('user123');
        final error = Exception('Complete error');
        final stackTrace = StackTrace.current;
        final context = {'operation': 'test', 'step': '2'};

        // Act
        logger.e(
          'Error complete',
          error: error,
          stackTrace: stackTrace,
          context: context,
        );
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final logEntry = mockRemoteLogger.logs.first;
        expect(logEntry.level, LogLevel.error);
        expect(logEntry.message, 'Error complete');
        expect(logEntry.error, error);
        expect(logEntry.stackTrace, stackTrace);
        expect(logEntry.context, context);
        expect(logEntry.userId, 'user123');
        expect(logEntry.deviceInfo, isNotNull);
      });
    });

    group('Métodos de logging - f()', () {
      test('debe loguear y persistir fatal', () async {
        // Act
        logger.f('Test fatal message');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Fatal SÍ se persiste
        expect(mockRemoteLogger.logs.length, 1);
        expect(mockRemoteLogger.logs.first.level, LogLevel.fatal);
        expect(mockRemoteLogger.logs.first.message, 'Test fatal message');
      });

      test('debe loguear fatal con exception', () async {
        // Arrange
        final error = StateError('Fatal state');
        final stackTrace = StackTrace.current;

        // Act
        logger.f('Fatal crash', error: error, stackTrace: stackTrace);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.length, 1);
        final logEntry = mockRemoteLogger.logs.first;
        expect(logEntry.error, error);
        expect(logEntry.stackTrace, stackTrace);
      });

      test('debe loguear fatal con context', () async {
        // Arrange
        final context = {'screen': 'home', 'action': 'load'};

        // Act
        logger.f('App crashed', context: context);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.first.context, context);
      });

      test('debe loguear fatal completo', () async {
        // Arrange
        logger.setUserId('user456');
        final error = StateError('Complete fatal');
        final stackTrace = StackTrace.current;
        final context = {'screen': 'gossip', 'lastAction': 'create'};

        // Act
        logger.f(
          'Fatal complete',
          error: error,
          stackTrace: stackTrace,
          context: context,
        );
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        final logEntry = mockRemoteLogger.logs.first;
        expect(logEntry.level, LogLevel.fatal);
        expect(logEntry.message, 'Fatal complete');
        expect(logEntry.error, error);
        expect(logEntry.stackTrace, stackTrace);
        expect(logEntry.context, context);
        expect(logEntry.userId, 'user456');
        expect(logEntry.deviceInfo, isNotNull);
      });
    });

    group('Persistencia selectiva', () {
      test('debug NO debe persistir', () async {
        // Act
        logger.d('Debug');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
        expect(mockDeviceInfo.callCount, 0);
      });

      test('info NO debe persistir', () async {
        // Act
        logger.i('Info');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
        expect(mockDeviceInfo.callCount, 0);
      });

      test('warning NO debe persistir', () async {
        // Act
        logger.w('Warning');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs, isEmpty);
        expect(mockDeviceInfo.callCount, 0);
      });

      test('error SÍ debe persistir', () async {
        // Act
        logger.e('Error');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.length, 1);
        expect(mockDeviceInfo.callCount, 1);
      });

      test('fatal SÍ debe persistir', () async {
        // Act
        logger.f('Fatal');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.length, 1);
        expect(mockDeviceInfo.callCount, 1);
      });
    });

    group('Manejo de errores', () {
      test('debe manejar error al obtener device info', () async {
        // Arrange
        mockDeviceInfo.shouldThrow = true;

        // Act & Assert - No debe propagar el error
        await expectLater(() async {
          logger.e('Test error');
          await Future.delayed(const Duration(milliseconds: 100));
        }, returnsNormally);
      });

      test('debe continuar funcionando después de un error', () async {
        // Arrange
        mockDeviceInfo.shouldThrow = true;

        // Act - Primera llamada falla
        logger.e('Error 1');
        await Future.delayed(const Duration(milliseconds: 50));

        // Segunda llamada exitosa
        mockDeviceInfo.shouldThrow = false;
        logger.e('Error 2');
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - Segunda llamada debe funcionar
        expect(mockDeviceInfo.callCount, 2);
      });
    });

    group('Múltiples logs concurrentes', () {
      test('debe manejar múltiples logs de diferentes niveles', () async {
        // Act
        logger.d('Debug');
        logger.i('Info');
        logger.w('Warning');
        logger.e('Error');
        logger.f('Fatal');

        await Future.delayed(const Duration(milliseconds: 200));

        // Assert - Solo error y fatal deben persistir
        expect(mockRemoteLogger.logs.length, 2);
        expect(mockRemoteLogger.logs[0].level, LogLevel.error);
        expect(mockRemoteLogger.logs[1].level, LogLevel.fatal);
      });

      test('debe manejar múltiples errors concurrentes', () async {
        // Act
        for (var i = 0; i < 5; i++) {
          logger.e('Error $i');
        }

        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        expect(mockRemoteLogger.logs.length, 5);
        expect(mockDeviceInfo.callCount, 5);
      });

      test('debe manejar mix de logs que persisten y no persisten', () async {
        // Act
        logger.i('Info 1');
        logger.e('Error 1');
        logger.d('Debug 1');
        logger.f('Fatal 1');
        logger.w('Warning 1');
        logger.e('Error 2');

        await Future.delayed(const Duration(milliseconds: 200));

        // Assert - Solo 3 deben persistir (error 1, fatal, error 2)
        expect(mockRemoteLogger.logs.length, 3);
      });
    });

    group('Casos de uso reales', () {
      test('debe loguear operación exitosa típica', () {
        // Act
        logger.i('Usuario creó gossip', context: {
          'gossipId': 'abc123',
          'cityId': 'MED',
          'hasImage': true,
        });

        // Assert - Info no persiste
        expect(mockRemoteLogger.logs, isEmpty);
      });

      test('debe loguear error de red típico', () async {
        // Arrange
        final error = Exception('Connection timeout');
        final stackTrace = StackTrace.current;

        // Act
        logger.e(
          'Failed to fetch gossips',
          error: error,
          stackTrace: stackTrace,
          context: {
            'operation': 'fetchGossips',
            'timeout': 30,
          },
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.length, 1);
      });

      test('debe loguear crash típico', () async {
        // Arrange
        final error = StateError('Invalid state');
        final stackTrace = StackTrace.current;
        logger.setUserId('user123');

        // Act
        logger.f(
          'App crashed',
          error: error,
          stackTrace: stackTrace,
          context: {
            'screen': 'home',
            'action': 'load',
          },
        );

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.length, 1);
        expect(mockRemoteLogger.logs.first.userId, 'user123');
      });

      test('debe loguear warning de cache', () {
        // Act
        logger.w('Cache version mismatch, clearing', context: {
          'expectedVersion': 2,
          'foundVersion': 1,
        });

        // Assert - Warning no persiste
        expect(mockRemoteLogger.logs, isEmpty);
      });

      test('debe loguear debug durante desarrollo', () {
        // Act
        logger.d('Cache loaded', context: {
          'itemCount': 42,
          'loadTime': 125,
        });

        // Assert - Debug no persiste
        expect(mockRemoteLogger.logs, isEmpty);
      });
    });

    group('close', () {
      test('debe ser seguro de llamar close()', () {
        // Act & Assert
        expect(() => logger.close(), returnsNormally);
      });

      test('debe ser seguro de llamar close() múltiples veces', () {
        // Act & Assert
        expect(() {
          logger.close();
          logger.close();
          logger.close();
        }, returnsNormally);
      });
    });

    group('Edge cases', () {
      test('debe manejar mensaje vacío', () async {
        // Act
        logger.e('');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Debe persistir aunque el mensaje esté vacío
        expect(mockRemoteLogger.logs.length, 1);
      });

      test('debe manejar mensaje muy largo', () async {
        // Arrange
        final longMessage = 'A' * 10000;

        // Act
        logger.e(longMessage);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.length, 1);
        expect(mockRemoteLogger.logs.first.message.length, 10000);
      });

      test('debe manejar context muy grande', () async {
        // Arrange
        final largeContext = Map.fromEntries(
          List.generate(100, (i) => MapEntry('key$i', 'value$i')),
        );

        // Act
        logger.e('Error', context: largeContext);
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.length, 1);
        expect(mockRemoteLogger.logs.first.context?.length, 100);
      });

      test('debe manejar userId muy largo', () async {
        // Arrange
        final longUserId = 'user_${'a' * 1000}';
        logger.setUserId(longUserId);

        // Act
        logger.e('Error');
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(mockRemoteLogger.logs.first.userId?.length, 1005);
      });

      test('debe manejar diferentes tipos de errores', () async {
        // Act
        logger.e('Exception', error: Exception('Test'));
        logger.e('Error', error: ArgumentError('Invalid'));
        logger.e('String', error: 'String error');
        logger.e('Number', error: 42);
        logger.e('Null', error: null);

        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        expect(mockRemoteLogger.logs.length, 5);
      });
    });
  });

  group('LogLevel', () {
    test('fromString debe convertir correctamente', () {
      expect(LogLevel.fromString('debug'), LogLevel.debug);
      expect(LogLevel.fromString('info'), LogLevel.info);
      expect(LogLevel.fromString('warning'), LogLevel.warning);
      expect(LogLevel.fromString('error'), LogLevel.error);
      expect(LogLevel.fromString('fatal'), LogLevel.fatal);
    });

    test('fromString debe retornar info si no encuentra', () {
      expect(LogLevel.fromString('invalid'), LogLevel.info);
    });

    test('shouldPersist solo para error y fatal', () {
      expect(LogLevel.debug.shouldPersist, isFalse);
      expect(LogLevel.info.shouldPersist, isFalse);
      expect(LogLevel.warning.shouldPersist, isFalse);
      expect(LogLevel.error.shouldPersist, isTrue);
      expect(LogLevel.fatal.shouldPersist, isTrue);
    });

    test('emoji debe retornar correcto', () {
      expect(LogLevel.debug.emoji, '🔍');
      expect(LogLevel.info.emoji, 'ℹ️');
      expect(LogLevel.warning.emoji, '⚠️');
      expect(LogLevel.error.emoji, '❌');
      expect(LogLevel.fatal.emoji, '💥');
    });
  });

  group('LogEntry', () {
    test('toJson debe serializar correctamente', () {
      final entry = LogEntry(
        level: LogLevel.error,
        message: 'Test error',
        errorType: 'TestException',
        context: {'key': 'value'},
        userId: 'user-123',
        deviceInfo: {'os': 'iOS'},
      );

      final json = entry.toJson();

      expect(json['level'], 'error');
      expect(json['message'], 'Test error');
      expect(json['error_type'], 'TestException');
      expect(json['context'], {'key': 'value'});
      expect(json['user_id'], 'user-123');
      expect(json['device_info'], {'os': 'iOS'});
    });

    test('toString debe formatearse correctamente', () {
      final entry = LogEntry(
        level: LogLevel.error,
        message: 'Test error',
        errorType: 'TestException',
      );

      final string = entry.toString();

      expect(string, contains('❌'));
      expect(string, contains('[ERROR]'));
      expect(string, contains('Test error'));
      expect(string, contains('Type: TestException'));
    });
  });
}

/// Mock de RemoteLogger para tests
class MockRemoteLogger implements RemoteLogger {
  final List<LogEntry> logs = [];

  @override
  Future<void> log(LogEntry entry) async {
    logs.add(entry);
  }
}

/// Mock de DeviceInfoProvider para tests
class MockDeviceInfoProvider extends DeviceInfoProvider {
  int callCount = 0;
  bool shouldThrow = false;

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    callCount++;

    if (shouldThrow) {
      throw Exception('Device info error');
    }

    return {
      'os': 'TestOS',
      'osVersion': '1.0',
      'device': 'TestDevice',
      'appVersion': '1.0.0',
    };
  }
}
