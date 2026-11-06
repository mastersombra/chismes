import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/logging/log_entry.dart';
import 'package:chismes/core/logging/log_level.dart';

void main() {
  group('LogEntry', () {
    group('Constructor', () {
      test('debe crear instancia con campos requeridos', () {
        // Arrange & Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test message',
        );

        // Assert
        expect(entry.level, LogLevel.info);
        expect(entry.message, 'Test message');
        expect(entry.errorType, isNull);
        expect(entry.error, isNull);
        expect(entry.stackTrace, isNull);
        expect(entry.context, isNull);
        expect(entry.userId, isNull);
        expect(entry.deviceInfo, isNull);
        expect(entry.timestamp, isA<DateTime>());
      });

      test('debe crear instancia con todos los campos', () {
        // Arrange
        final timestamp = DateTime(2026, 10, 20, 10, 30);
        final stackTrace = StackTrace.current;
        final context = {'key': 'value'};
        final deviceInfo = {'os': 'Android'};
        final error = Exception('Test error');

        // Act
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Error occurred',
          errorType: 'CustomError',
          error: error,
          stackTrace: stackTrace,
          context: context,
          userId: 'user123',
          deviceInfo: deviceInfo,
          timestamp: timestamp,
        );

        // Assert
        expect(entry.level, LogLevel.error);
        expect(entry.message, 'Error occurred');
        expect(entry.errorType, 'CustomError');
        expect(entry.error, error);
        expect(entry.stackTrace, stackTrace);
        expect(entry.context, context);
        expect(entry.userId, 'user123');
        expect(entry.deviceInfo, deviceInfo);
        expect(entry.timestamp, timestamp);
      });

      test('debe usar DateTime.now() si timestamp no se proporciona', () {
        // Arrange
        final before = DateTime.now();

        // Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
        );
        final after = DateTime.now();

        // Assert
        expect(entry.timestamp.isAfter(before.subtract(Duration(seconds: 1))), isTrue);
        expect(entry.timestamp.isBefore(after.add(Duration(seconds: 1))), isTrue);
      });

      test('debe usar timestamp proporcionado', () {
        // Arrange
        final customTimestamp = DateTime(2020, 1, 1, 12, 0);

        // Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          timestamp: customTimestamp,
        );

        // Assert
        expect(entry.timestamp, customTimestamp);
      });
    });

    group('Campos opcionales', () {
      test('errorType debe ser null si no se proporciona', () {
        // Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
        );

        // Assert
        expect(entry.errorType, isNull);
      });

      test('error debe ser null si no se proporciona', () {
        // Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
        );

        // Assert
        expect(entry.error, isNull);
      });

      test('stackTrace debe ser null si no se proporciona', () {
        // Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
        );

        // Assert
        expect(entry.stackTrace, isNull);
      });

      test('context debe ser null si no se proporciona', () {
        // Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
        );

        // Assert
        expect(entry.context, isNull);
      });

      test('userId debe ser null si no se proporciona', () {
        // Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
        );

        // Assert
        expect(entry.userId, isNull);
      });

      test('deviceInfo debe ser null si no se proporciona', () {
        // Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
        );

        // Assert
        expect(entry.deviceInfo, isNull);
      });
    });

    group('toJson', () {
      test('debe serializar campos básicos correctamente', () {
        // Arrange
        final timestamp = DateTime(2026, 10, 20, 10, 30);
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test message',
          timestamp: timestamp,
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['level'], 'info');
        expect(json['message'], 'Test message');
        expect(json['created_at'], '2026-10-20T10:30:00.000');
      });

      test('debe serializar todos los campos cuando están presentes', () {
        // Arrange
        final timestamp = DateTime(2026, 10, 20);
        final stackTrace = StackTrace.fromString('Stack trace line');
        final context = {'operation': 'test', 'id': 123};
        final deviceInfo = {'os': 'Android', 'version': '11'};

        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Error occurred',
          errorType: 'CustomError',
          error: Exception('Test'),
          stackTrace: stackTrace,
          context: context,
          userId: 'user123',
          deviceInfo: deviceInfo,
          timestamp: timestamp,
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['level'], 'error');
        expect(json['message'], 'Error occurred');
        expect(json['error_type'], 'CustomError');
        expect(json['stack_trace'], contains('Stack trace line'));
        expect(json['user_id'], 'user123');
        expect(json['device_info'], deviceInfo);
        expect(json['context'], context);
        expect(json['created_at'], startsWith('2026-10-20'));
      });

      test('debe usar error.runtimeType si errorType no se proporciona', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Error',
          error: Exception('Test error'),
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['error_type'], contains('Exception'));
      });

      test('debe ser null en error_type si errorType y error son null', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'No error',
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['error_type'], isNull);
      });

      test('debe serializar stackTrace como string', () {
        // Arrange
        final stackTrace = StackTrace.fromString('Line 1\nLine 2\nLine 3');
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Error',
          stackTrace: stackTrace,
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['stack_trace'], isA<String>());
        expect(json['stack_trace'], contains('Line 1'));
        expect(json['stack_trace'], contains('Line 2'));
      });

      test('stack_trace debe ser null si no se proporciona', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'No stack',
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['stack_trace'], isNull);
      });

      test('debe usar snake_case para keys de Supabase', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Test',
          errorType: 'TestError',
          userId: 'user123',
          deviceInfo: {'os': 'Android'},
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json.containsKey('error_type'), isTrue);
        expect(json.containsKey('stack_trace'), isTrue);
        expect(json.containsKey('user_id'), isTrue);
        expect(json.containsKey('device_info'), isTrue);
        expect(json.containsKey('created_at'), isTrue);
        // camelCase keys NO deben existir
        expect(json.containsKey('errorType'), isFalse);
        expect(json.containsKey('stackTrace'), isFalse);
        expect(json.containsKey('userId'), isFalse);
        expect(json.containsKey('deviceInfo'), isFalse);
      });

      test('debe serializar timestamp en formato ISO8601', () {
        // Arrange
        final timestamp = DateTime(2026, 10, 20, 15, 30, 45, 123);
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          timestamp: timestamp,
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['created_at'], isA<String>());
        expect(json['created_at'], contains('2026-10-20'));
        expect(json['created_at'], contains('T'));
      });

      test('context debe ser Map<String, dynamic> serializable', () {
        // Arrange
        final context = {
          'string': 'value',
          'int': 42,
          'bool': true,
          'null': null,
          'list': [1, 2, 3],
          'map': {'nested': 'value'},
        };

        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          context: context,
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['context'], context);
        expect(json['context']['string'], 'value');
        expect(json['context']['int'], 42);
        expect(json['context']['bool'], true);
        expect(json['context']['list'], [1, 2, 3]);
      });

      test('deviceInfo debe ser Map<String, dynamic> serializable', () {
        // Arrange
        final deviceInfo = {
          'os': 'Android',
          'version': '11',
          'model': 'Pixel 5',
          'isPhysical': true,
        };

        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          deviceInfo: deviceInfo,
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['device_info'], deviceInfo);
        expect(json['device_info']['os'], 'Android');
        expect(json['device_info']['model'], 'Pixel 5');
      });
    });

    group('copyWith', () {
      test('debe crear copia con cambios en level', () {
        // Arrange
        final original = LogEntry(
          level: LogLevel.info,
          message: 'Original',
        );

        // Act
        final copy = original.copyWith(level: LogLevel.error);

        // Assert
        expect(copy.level, LogLevel.error);
        expect(copy.message, 'Original'); // Sin cambios
      });

      test('debe crear copia con cambios en message', () {
        // Arrange
        final original = LogEntry(
          level: LogLevel.info,
          message: 'Original',
        );

        // Act
        final copy = original.copyWith(message: 'Modified');

        // Assert
        expect(copy.level, LogLevel.info); // Sin cambios
        expect(copy.message, 'Modified');
      });

      test('debe crear copia con cambios en errorType', () {
        // Arrange
        final original = LogEntry(
          level: LogLevel.error,
          message: 'Error',
          errorType: 'TypeError',
        );

        // Act
        final copy = original.copyWith(errorType: 'NetworkError');

        // Assert
        expect(copy.errorType, 'NetworkError');
      });

      test('debe crear copia con cambios en error', () {
        // Arrange
        final original = LogEntry(
          level: LogLevel.error,
          message: 'Error',
          error: Exception('Original'),
        );
        final newError = Exception('New');

        // Act
        final copy = original.copyWith(error: newError);

        // Assert
        expect(copy.error, newError);
      });

      test('debe crear copia con cambios en stackTrace', () {
        // Arrange
        final original = LogEntry(
          level: LogLevel.error,
          message: 'Error',
          stackTrace: StackTrace.fromString('Original'),
        );
        final newStack = StackTrace.fromString('New');

        // Act
        final copy = original.copyWith(stackTrace: newStack);

        // Assert
        expect(copy.stackTrace, newStack);
      });

      test('debe crear copia con cambios en context', () {
        // Arrange
        final original = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          context: {'old': 'value'},
        );

        // Act
        final copy = original.copyWith(context: {'new': 'value'});

        // Assert
        expect(copy.context, {'new': 'value'});
      });

      test('debe crear copia con cambios en userId', () {
        // Arrange
        final original = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          userId: 'user1',
        );

        // Act
        final copy = original.copyWith(userId: 'user2');

        // Assert
        expect(copy.userId, 'user2');
      });

      test('debe crear copia con cambios en deviceInfo', () {
        // Arrange
        final original = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          deviceInfo: {'os': 'Android'},
        );

        // Act
        final copy = original.copyWith(deviceInfo: {'os': 'iOS'});

        // Assert
        expect(copy.deviceInfo, {'os': 'iOS'});
      });

      test('debe crear copia con cambios en timestamp', () {
        // Arrange
        final original = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          timestamp: DateTime(2020, 1, 1),
        );

        // Act
        final copy = original.copyWith(timestamp: DateTime(2025, 1, 1));

        // Assert
        expect(copy.timestamp, DateTime(2025, 1, 1));
      });

      test('debe mantener campos sin cambios cuando no se proporcionan', () {
        // Arrange
        final timestamp = DateTime(2026, 10, 20);
        final context = {'key': 'value'};
        final deviceInfo = {'os': 'Android'};

        final original = LogEntry(
          level: LogLevel.error,
          message: 'Original message',
          errorType: 'TypeError',
          error: Exception('Test'),
          context: context,
          userId: 'user123',
          deviceInfo: deviceInfo,
          timestamp: timestamp,
        );

        // Act
        final copy = original.copyWith(message: 'New message');

        // Assert
        expect(copy.message, 'New message'); // Cambiado
        expect(copy.level, LogLevel.error); // Sin cambios
        expect(copy.errorType, 'TypeError'); // Sin cambios
        expect(copy.error, isNotNull); // Sin cambios
        expect(copy.context, context); // Sin cambios
        expect(copy.userId, 'user123'); // Sin cambios
        expect(copy.deviceInfo, deviceInfo); // Sin cambios
        expect(copy.timestamp, timestamp); // Sin cambios
      });

      test('debe crear copia con múltiples cambios', () {
        // Arrange
        final original = LogEntry(
          level: LogLevel.info,
          message: 'Original',
          userId: 'user1',
        );

        // Act
        final copy = original.copyWith(
          level: LogLevel.error,
          message: 'Modified',
          userId: 'user2',
          context: {'new': 'context'},
        );

        // Assert
        expect(copy.level, LogLevel.error);
        expect(copy.message, 'Modified');
        expect(copy.userId, 'user2');
        expect(copy.context, {'new': 'context'});
      });

      test('instancia original no debe cambiar (inmutabilidad)', () {
        // Arrange
        final original = LogEntry(
          level: LogLevel.info,
          message: 'Original',
          userId: 'user1',
        );

        // Act
        final copy = original.copyWith(
          level: LogLevel.error,
          message: 'Modified',
          userId: 'user2',
        );

        // Assert - Original sin cambios
        expect(original.level, LogLevel.info);
        expect(original.message, 'Original');
        expect(original.userId, 'user1');
        // Copia con cambios
        expect(copy.level, LogLevel.error);
        expect(copy.message, 'Modified');
        expect(copy.userId, 'user2');
      });
    });

    group('toString', () {
      test('debe incluir emoji, level y message básico', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test message',
        );

        // Act
        final string = entry.toString();

        // Assert
        expect(string, contains('ℹ️')); // Info emoji
        expect(string, contains('[INFO]'));
        expect(string, contains('Test message'));
      });

      test('debe incluir errorType cuando está presente', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Error occurred',
          errorType: 'NetworkError',
        );

        // Act
        final string = entry.toString();

        // Assert
        expect(string, contains('Type: NetworkError'));
      });

      test('debe incluir error en nueva línea cuando está presente', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Error occurred',
          error: Exception('Connection failed'),
        );

        // Act
        final string = entry.toString();

        // Assert
        expect(string, contains('\n   Error: Exception: Connection failed'));
      });

      test('debe incluir context en nueva línea cuando está presente y no vacío', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Operation',
          context: {'operation': 'create', 'id': 123},
        );

        // Act
        final string = entry.toString();

        // Assert
        expect(string, contains('\n   Context:'));
        expect(string, contains('operation'));
        expect(string, contains('create'));
      });

      test('NO debe incluir context si está vacío', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Operation',
          context: {},
        );

        // Act
        final string = entry.toString();

        // Assert
        expect(string, isNot(contains('Context:')));
      });

      test('debe incluir stackTrace en nueva línea cuando está presente', () {
        // Arrange
        final stackTrace = StackTrace.fromString('Line 1\nLine 2');
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Error',
          stackTrace: stackTrace,
        );

        // Act
        final string = entry.toString();

        // Assert
        expect(string, contains('\n   Stack:\n'));
        expect(string, contains('Line 1'));
        expect(string, contains('Line 2'));
      });

      test('debe usar emoji correcto para cada nivel', () {
        // Assert
        expect(LogEntry(level: LogLevel.debug, message: 'Test').toString(),
            startsWith('🔍'));
        expect(LogEntry(level: LogLevel.info, message: 'Test').toString(),
            startsWith('ℹ️'));
        expect(LogEntry(level: LogLevel.warning, message: 'Test').toString(),
            startsWith('⚠️'));
        expect(LogEntry(level: LogLevel.error, message: 'Test').toString(),
            startsWith('❌'));
        expect(LogEntry(level: LogLevel.fatal, message: 'Test').toString(),
            startsWith('💥'));
      });

      test('debe mostrar level en mayúsculas', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Test',
        );

        // Act
        final string = entry.toString();

        // Assert
        expect(string, contains('[ERROR]'));
        expect(string, isNot(contains('[error]')));
      });

      test('formato completo con todos los campos', () {
        // Arrange
        final stackTrace = StackTrace.fromString('Stack line');
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Critical error',
          errorType: 'DatabaseError',
          error: Exception('Connection timeout'),
          stackTrace: stackTrace,
          context: {'operation': 'query', 'timeout': 30},
        );

        // Act
        final string = entry.toString();

        // Assert
        expect(string, contains('❌'));
        expect(string, contains('[ERROR]'));
        expect(string, contains('Critical error'));
        expect(string, contains('Type: DatabaseError'));
        expect(string, contains('Error: Exception: Connection timeout'));
        expect(string, contains('Context:'));
        expect(string, contains('operation'));
        expect(string, contains('Stack:\n'));
      });

      test('formato mínimo solo con campos requeridos', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Simple log',
        );

        // Act
        final string = entry.toString();

        // Assert
        expect(string, equals('ℹ️ [INFO] Simple log'));
        expect(string, isNot(contains('Type:')));
        expect(string, isNot(contains('Error:')));
        expect(string, isNot(contains('Context:')));
        expect(string, isNot(contains('Stack:')));
      });
    });

    group('Integración con LogLevel', () {
      test('debe funcionar con todos los niveles de LogLevel', () {
        // Act & Assert
        expect(() => LogEntry(level: LogLevel.debug, message: 'Test'),
            returnsNormally);
        expect(() => LogEntry(level: LogLevel.info, message: 'Test'),
            returnsNormally);
        expect(() => LogEntry(level: LogLevel.warning, message: 'Test'),
            returnsNormally);
        expect(() => LogEntry(level: LogLevel.error, message: 'Test'),
            returnsNormally);
        expect(() => LogEntry(level: LogLevel.fatal, message: 'Test'),
            returnsNormally);
      });

      test('level.value debe estar correctamente en toJson', () {
        // Arrange
        final debugEntry = LogEntry(level: LogLevel.debug, message: 'Test');
        final infoEntry = LogEntry(level: LogLevel.info, message: 'Test');
        final errorEntry = LogEntry(level: LogLevel.error, message: 'Test');

        // Act & Assert
        expect(debugEntry.toJson()['level'], 'debug');
        expect(infoEntry.toJson()['level'], 'info');
        expect(errorEntry.toJson()['level'], 'error');
      });
    });

    group('Edge Cases', () {
      test('debe manejar message vacío', () {
        // Arrange & Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: '',
        );

        // Assert
        expect(entry.message, '');
        expect(entry.toJson()['message'], '');
        expect(entry.toString(), contains('[INFO] '));
      });

      test('debe manejar message muy largo', () {
        // Arrange
        final longMessage = 'A' * 10000;

        // Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: longMessage,
        );

        // Assert
        expect(entry.message.length, 10000);
        expect(entry.toJson()['message'], longMessage);
      });

      test('debe manejar context con valores null', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          context: {'key': null, 'other': 'value'},
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['context']['key'], isNull);
        expect(json['context']['other'], 'value');
      });

      test('debe manejar deviceInfo con valores null', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          deviceInfo: {'os': null, 'version': '11'},
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['device_info']['os'], isNull);
        expect(json['device_info']['version'], '11');
      });

      test('debe manejar error de diferentes tipos', () {
        // Arrange
        final exception = Exception('Test');
        final string = 'String error';
        final number = 404;

        // Act & Assert
        expect(() => LogEntry(level: LogLevel.error, message: 'Test', error: exception),
            returnsNormally);
        expect(() => LogEntry(level: LogLevel.error, message: 'Test', error: string),
            returnsNormally);
        expect(() => LogEntry(level: LogLevel.error, message: 'Test', error: number),
            returnsNormally);
      });

      test('debe manejar stackTrace null en toString', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Error',
          stackTrace: null,
        );

        // Act
        final string = entry.toString();

        // Assert
        expect(string, isNot(contains('Stack:')));
      });

      test('debe manejar timestamp en pasado', () {
        // Arrange
        final pastTimestamp = DateTime(2000, 1, 1);

        // Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          timestamp: pastTimestamp,
        );

        // Assert
        expect(entry.timestamp, pastTimestamp);
        expect(entry.toJson()['created_at'], startsWith('2000-01-01'));
      });

      test('debe manejar timestamp en futuro', () {
        // Arrange
        final futureTimestamp = DateTime(2100, 12, 31);

        // Act
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          timestamp: futureTimestamp,
        );

        // Assert
        expect(entry.timestamp, futureTimestamp);
        expect(entry.toJson()['created_at'], startsWith('2100-12-31'));
      });

      test('debe manejar userId vacío', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          userId: '',
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['user_id'], '');
      });

      test('debe manejar errorType vacío', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Error',
          errorType: '',
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['error_type'], '');
      });

      test('debe manejar caracteres especiales en message', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test with "quotes" and \'apostrophes\' and\nnewlines\t and tabs',
        );

        // Act
        final json = entry.toJson();
        final string = entry.toString();

        // Assert
        expect(json['message'], contains('"quotes"'));
        expect(string, contains('"quotes"'));
      });

      test('debe manejar context con tipos complejos', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'Test',
          context: {
            'nested': {'deep': {'value': 123}},
            'list': [1, 'two', {'three': 3}],
            'bool': true,
            'double': 3.14,
          },
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['context']['nested']['deep']['value'], 123);
        expect(json['context']['list'][2]['three'], 3);
        expect(json['context']['bool'], true);
      });
    });

    group('Casos de uso reales', () {
      test('debe representar log de info típico', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.info,
          message: 'User logged in successfully',
          context: {'userId': 'user123', 'method': 'email'},
          userId: 'user123',
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['level'], 'info');
        expect(json['message'], contains('logged in'));
        expect(json['user_id'], 'user123');
        expect(json['context'], isNotNull);
      });

      test('debe representar log de error típico', () {
        // Arrange
        final error = Exception('Network timeout');
        final stackTrace = StackTrace.current;

        final entry = LogEntry(
          level: LogLevel.error,
          message: 'Failed to fetch gossips',
          errorType: 'NetworkError',
          error: error,
          stackTrace: stackTrace,
          context: {'operation': 'fetchGossips', 'timeout': 30},
          userId: 'user123',
          deviceInfo: {'os': 'Android', 'version': '11'},
        );

        // Act
        final json = entry.toJson();

        // Assert
        expect(json['level'], 'error');
        expect(json['error_type'], 'NetworkError');
        expect(json['stack_trace'], isNotNull);
        expect(json['context']['operation'], 'fetchGossips');
        expect(json['device_info']['os'], 'Android');
      });

      test('debe representar log de warning típico', () {
        // Arrange
        final entry = LogEntry(
          level: LogLevel.warning,
          message: 'Cache miss, fetching from network',
          context: {'cacheKey': 'gossips_list', 'fallbackUsed': true},
        );

        // Act
        final json = entry.toJson();
        final string = entry.toString();

        // Assert
        expect(json['level'], 'warning');
        expect(string, startsWith('⚠️'));
        expect(json['context']['fallbackUsed'], true);
      });

      test('debe representar log de fatal típico', () {
        // Arrange
        final error = StateError('Database corrupted');
        final stackTrace = StackTrace.current;

        final entry = LogEntry(
          level: LogLevel.fatal,
          message: 'Critical: App cannot continue',
          errorType: 'DatabaseCorruptionError',
          error: error,
          stackTrace: stackTrace,
          context: {'canRecover': false, 'action': 'restart_required'},
          deviceInfo: {'os': 'iOS', 'version': '15.0'},
        );

        // Act
        final json = entry.toJson();
        final string = entry.toString();

        // Assert
        expect(json['level'], 'fatal');
        expect(string, startsWith('💥'));
        expect(json['context']['canRecover'], false);
      });
    });
  });
}
