import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chismes/core/logging/remote_logger.dart';
import 'package:chismes/core/logging/log_entry.dart';
import 'package:chismes/core/logging/log_level.dart';

@GenerateMocks([
  SupabaseClient,
  SupabaseQueryBuilder,
  FunctionsClient,
  FunctionResponse,
  GoTrueClient,
  Session,
])
import 'remote_logger_test.mocks.dart';

void main() {
  /// Helper para configurar mocks de SupabaseClient con auth
  // ignore: unused_element
  MockSupabaseClient setupMockSupabaseClient({
    required MockFunctionsClient functions,
  }) {
    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    final mockSession = MockSession();

    when(mockClient.auth).thenReturn(mockAuth);
    when(mockAuth.currentSession).thenReturn(mockSession);
    when(mockClient.functions).thenReturn(functions);

    return mockClient;
  }

  group('MockRemoteLogger', () {
    late MockRemoteLogger logger;

    setUp(() {
      logger = MockRemoteLogger();
    });

    test('debe implementar RemoteLogger', () {
      expect(logger, isA<RemoteLogger>());
    });

    test('debe inicializar con lista vacía', () {
      expect(logger.logs, isEmpty);
    });

    test('debe agregar log a la lista cuando se llama log()', () async {
      // Arrange
      final entry = LogEntry(
        level: LogLevel.error,
        message: 'Test error',
      );

      // Act
      await logger.log(entry);

      // Assert
      expect(logger.logs, hasLength(1));
      expect(logger.logs.first, entry);
    });

    test('debe agregar múltiples logs', () async {
      // Arrange
      final entry1 = LogEntry(level: LogLevel.error, message: 'Error 1');
      final entry2 = LogEntry(level: LogLevel.fatal, message: 'Error 2');
      final entry3 = LogEntry(level: LogLevel.info, message: 'Info');

      // Act
      await logger.log(entry1);
      await logger.log(entry2);
      await logger.log(entry3);

      // Assert
      expect(logger.logs, hasLength(3));
      expect(logger.logs[0], entry1);
      expect(logger.logs[1], entry2);
      expect(logger.logs[2], entry3);
    });

    test('clear() debe vaciar la lista de logs', () async {
      // Arrange
      await logger.log(LogEntry(level: LogLevel.error, message: 'Error'));
      await logger.log(LogEntry(level: LogLevel.fatal, message: 'Fatal'));
      expect(logger.logs, hasLength(2));

      // Act
      logger.clear();

      // Assert
      expect(logger.logs, isEmpty);
    });

    test('clear() en lista vacía no debe causar error', () {
      // Act & Assert
      expect(() => logger.clear(), returnsNormally);
      expect(logger.logs, isEmpty);
    });

    test('debe mantener orden de logs', () async {
      // Arrange
      final entries = List.generate(
        10,
        (i) => LogEntry(level: LogLevel.error, message: 'Error $i'),
      );

      // Act
      for (final entry in entries) {
        await logger.log(entry);
      }

      // Assert
      expect(logger.logs, hasLength(10));
      for (var i = 0; i < 10; i++) {
        expect(logger.logs[i].message, 'Error $i');
      }
    });

    test('logs debe ser accesible directamente', () async {
      // Arrange
      final entry = LogEntry(level: LogLevel.error, message: 'Test');
      await logger.log(entry);

      // Act & Assert - Acceso directo a la lista
      expect(logger.logs.length, 1);
      expect(logger.logs.first.message, 'Test');
      expect(logger.logs.first.level, LogLevel.error);
    });

    test('debe ser útil para verificación en tests', () async {
      // Este test simula cómo se usaría en tests reales

      // Arrange
      final mockLogger = MockRemoteLogger();

      // Act - Simular uso en código real
      await mockLogger.log(LogEntry(level: LogLevel.error, message: 'Error 1'));
      await mockLogger.log(LogEntry(level: LogLevel.info, message: 'Info'));

      // Assert - Verificar que se loguearon
      expect(mockLogger.logs, hasLength(2));
      expect(mockLogger.logs[0].level, LogLevel.error);
      expect(mockLogger.logs[1].level, LogLevel.info);

      // Limpiar para siguiente test
      mockLogger.clear();
      expect(mockLogger.logs, isEmpty);
    });
  });

  group('SupabaseRemoteLogger', () {
    test('debe implementar RemoteLogger', () {
      // Arrange
      final mockClient = MockSupabaseClient();
      final logger = SupabaseRemoteLogger(mockClient);

      // Assert
      expect(logger, isA<RemoteLogger>());
    });

    test('debe crear instancia con SupabaseClient', () {
      // Arrange
      final mockClient = MockSupabaseClient();

      // Act
      final logger = SupabaseRemoteLogger(mockClient);

      // Assert
      expect(logger, isNotNull);
      expect(logger, isA<SupabaseRemoteLogger>());
    });

    test('NO debe llamar from para logs de nivel debug', () async {
      // Arrange
      final mockClient = MockSupabaseClient();
      final logger = SupabaseRemoteLogger(mockClient);

      final entry = LogEntry(level: LogLevel.debug, message: 'Debug');

      // Act
      await logger.log(entry);
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      verifyNever(mockClient.from(any));
    });

    test('NO debe llamar from para logs de nivel info', () async {
      // Arrange
      final mockClient = MockSupabaseClient();
      final logger = SupabaseRemoteLogger(mockClient);

      final entry = LogEntry(level: LogLevel.info, message: 'Info');

      // Act
      await logger.log(entry);
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      verifyNever(mockClient.from(any));
    });

    test('NO debe llamar from para logs de nivel warning', () async {
      // Arrange
      final mockClient = MockSupabaseClient();
      final logger = SupabaseRemoteLogger(mockClient);

      final entry = LogEntry(level: LogLevel.warning, message: 'Warning');

      // Act
      await logger.log(entry);
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      verifyNever(mockClient.from(any));
    });

    test('NO debe propagar errores (fire-and-forget)', () async {
      // Arrange
      final mockClient = MockSupabaseClient();
      final logger = SupabaseRemoteLogger(mockClient);

      when(mockClient.from(any)).thenThrow(Exception('Supabase error'));

      final entry = LogEntry(level: LogLevel.error, message: 'Error');

      // Act & Assert - No debe lanzar excepción
      await expectLater(logger.log(entry), completes);
    });

    test('debe invocar Edge Function para logs de error', () async {
      // Arrange
      final mockFunctions = MockFunctionsClient();
      final mockResponse = MockFunctionResponse();
      final mockClient = setupMockSupabaseClient(functions: mockFunctions);

      when(mockFunctions.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => mockResponse);
      when(mockResponse.status).thenReturn(200);

      final logger = SupabaseRemoteLogger(mockClient);
      final entry = LogEntry(level: LogLevel.error, message: 'Test error');

      // Act
      await logger.log(entry);
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      verify(mockClient.functions).called(1);
      verify(mockFunctions.invoke('log-error', body: anyNamed('body'))).called(1);
    });

    test('debe invocar Edge Function para logs fatal', () async {
      // Arrange
      final mockFunctions = MockFunctionsClient();
      final mockResponse = MockFunctionResponse();
      final mockClient = setupMockSupabaseClient(functions: mockFunctions);

      when(mockFunctions.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => mockResponse);
      when(mockResponse.status).thenReturn(200);

      final logger = SupabaseRemoteLogger(mockClient);
      final entry = LogEntry(level: LogLevel.fatal, message: 'Test fatal');

      // Act
      await logger.log(entry);
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      verify(mockClient.functions).called(1);
      verify(mockFunctions.invoke('log-error', body: anyNamed('body'))).called(1);
    });

    test('debe manejar respuesta exitosa (status 200)', () async {
      // Arrange
      final mockFunctions = MockFunctionsClient();
      final mockResponse = MockFunctionResponse();
      final mockClient = setupMockSupabaseClient(functions: mockFunctions);

      when(mockFunctions.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => mockResponse);
      when(mockResponse.status).thenReturn(200);

      final logger = SupabaseRemoteLogger(mockClient);
      final entry = LogEntry(level: LogLevel.error, message: 'Test error');

      // Act & Assert - No debe lanzar excepción
      await expectLater(logger.log(entry), completes);
      await Future.delayed(Duration(milliseconds: 100));

      verify(mockResponse.status).called(greaterThan(0));
    });

    test('debe manejar rate limit (status 429)', () async {
      // Arrange
      final mockFunctions = MockFunctionsClient();
      final mockResponse = MockFunctionResponse();
      final mockClient = setupMockSupabaseClient(functions: mockFunctions);

      when(mockFunctions.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => mockResponse);
      when(mockResponse.status).thenReturn(429);

      final logger = SupabaseRemoteLogger(mockClient);
      final entry = LogEntry(level: LogLevel.error, message: 'Test error');

      // Act & Assert - No debe lanzar excepción
      await expectLater(logger.log(entry), completes);
      await Future.delayed(Duration(milliseconds: 100));

      verify(mockResponse.status).called(greaterThan(0));
    });

    test('debe manejar error de Edge Function (status 500)', () async {
      // Arrange
      final mockFunctions = MockFunctionsClient();
      final mockResponse = MockFunctionResponse();
      final mockClient = setupMockSupabaseClient(functions: mockFunctions);

      when(mockFunctions.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => mockResponse);
      when(mockResponse.status).thenReturn(500);

      final logger = SupabaseRemoteLogger(mockClient);
      final entry = LogEntry(level: LogLevel.error, message: 'Test error');

      // Act & Assert - No debe lanzar excepción
      await expectLater(logger.log(entry), completes);
      await Future.delayed(Duration(milliseconds: 100));

      verify(mockResponse.status).called(greaterThan(0));
    });

    test('debe manejar excepción durante invoke', () async {
      // Arrange
      final mockClient = MockSupabaseClient();
      final mockFunctions = MockFunctionsClient();

      when(mockClient.functions).thenReturn(mockFunctions);
      when(mockFunctions.invoke(any, body: anyNamed('body')))
          .thenThrow(Exception('Network error'));

      final logger = SupabaseRemoteLogger(mockClient);
      final entry = LogEntry(level: LogLevel.error, message: 'Test error');

      // Act & Assert - No debe lanzar excepción
      await expectLater(logger.log(entry), completes);
      await Future.delayed(Duration(milliseconds: 100));
    });

    test('debe enviar body correcto a Edge Function', () async {
      // Arrange
      final mockFunctions = MockFunctionsClient();
      final mockResponse = MockFunctionResponse();
      final mockClient = setupMockSupabaseClient(functions: mockFunctions);

      when(mockFunctions.invoke(any, body: anyNamed('body')))
          .thenAnswer((_) async => mockResponse);
      when(mockResponse.status).thenReturn(200);

      final logger = SupabaseRemoteLogger(mockClient);
      final entry = LogEntry(
        level: LogLevel.error,
        message: 'Test error',
        context: {'key': 'value'},
      );

      // Act
      await logger.log(entry);
      await Future.delayed(Duration(milliseconds: 100));

      // Assert
      final captured = verify(
        mockFunctions.invoke('log-error', body: captureAnyNamed('body'))
      ).captured;

      expect(captured, hasLength(1));
      expect(captured.first, isA<Map>());
    });
  });

  group('Comparación MockRemoteLogger vs SupabaseRemoteLogger', () {
    test('ambos deben implementar misma interface', () {
      // Arrange
      final mockLogger = MockRemoteLogger();
      final supabaseLogger = SupabaseRemoteLogger(MockSupabaseClient());

      // Assert
      expect(mockLogger, isA<RemoteLogger>());
      expect(supabaseLogger, isA<RemoteLogger>());
    });

    test('MockRemoteLogger es útil para tests unitarios', () async {
      // Arrange
      final mockLogger = MockRemoteLogger();
      final entry = LogEntry(level: LogLevel.error, message: 'Test');

      // Act
      await mockLogger.log(entry);

      // Assert - Verificación fácil
      expect(mockLogger.logs, hasLength(1));
      expect(mockLogger.logs.first.message, 'Test');
    });
  });
}
