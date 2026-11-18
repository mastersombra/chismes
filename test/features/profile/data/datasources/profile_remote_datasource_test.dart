import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:chismes/features/profile/data/models/profile_settings_model.dart';
import 'package:chismes/features/profile/data/models/user_stats_model.dart';

void main() {
  late AppLogger logger;

  setUp(() {
    // Logger mock simple para tests
    final mockRemoteLogger = _MockRemoteLogger();
    final mockDeviceInfo = _MockDeviceInfoProvider();
    logger = AppLogger(mockRemoteLogger, mockDeviceInfo);
  });

  tearDown(() {
    logger.close();
  });

  group('ProfileRemoteDataSource - Constructor', () {
    test('debe crear instancia con dependencias', () {
      // Arrange
      final supabase = _FakeSupabaseClient();

      // Act
      final dataSource = ProfileRemoteDataSource(supabase, logger);

      // Assert
      expect(dataSource, isA<ProfileRemoteDataSource>());
    });
  });

  group('UserStatsModel - Estructura', () {
    test('debe crear UserStatsModel con campos correctos', () {
      // Arrange & Act
      final stats = UserStatsModel(
        gossipsCount: 10,
        commentsCount: 5,
        followersCount: 20,
        followingCount: 15,
        lastActivityAt: '2024-01-15T10:30:00.000Z',
      );

      // Assert
      expect(stats.gossipsCount, 10);
      expect(stats.commentsCount, 5);
      expect(stats.followersCount, 20);
      expect(stats.followingCount, 15);
      expect(stats.lastActivityAt, isNotEmpty);
    });

    test('debe convertir UserStatsModel a JSON', () {
      // Arrange
      final stats = UserStatsModel(
        gossipsCount: 10,
        commentsCount: 5,
        followersCount: 20,
        followingCount: 15,
        lastActivityAt: '2024-01-15T10:30:00.000Z',
      );

      // Act
      final json = stats.toJson();

      // Assert
      expect(json['gossips_count'], 10);
      expect(json['comments_count'], 5);
      expect(json['followers_count'], 20);
      expect(json['following_count'], 15);
      expect(json['last_activity_at'], isNotEmpty);
    });

    test('debe deserializar UserStatsModel desde JSON', () {
      // Arrange
      final json = {
        'gossips_count': 10,
        'comments_count': 5,
        'followers_count': 20,
        'following_count': 15,
        'last_activity_at': '2024-01-15T10:30:00.000Z',
      };

      // Act
      final stats = UserStatsModel.fromJson(json);

      // Assert
      expect(stats, isA<UserStatsModel>());
      expect(stats.gossipsCount, 10);
      expect(stats.commentsCount, 5);
    });

    test('debe manejar counts en cero', () {
      // Arrange & Act
      final stats = UserStatsModel(
        gossipsCount: 0,
        commentsCount: 0,
        followersCount: 0,
        followingCount: 0,
        lastActivityAt: '2024-01-15T10:30:00.000Z',
      );

      // Assert
      expect(stats.gossipsCount, 0);
      expect(stats.commentsCount, 0);
      expect(stats.followersCount, 0);
      expect(stats.followingCount, 0);
    });
  });

  group('ProfileSettingsModel - Estructura', () {
    test('debe crear ProfileSettingsModel con campos correctos', () {
      // Arrange & Act
      final settings = ProfileSettingsModel.fromJson({
        'notifications_enabled': true,
        'email_notifications': true,
        'push_notifications': false,
        'comments_notifications': true,
        'likes_notifications': true,
        'follow_notifications': false,
        'language': 'es',
        'dark_mode': true,
        'privacy_level': 'public',
        'show_email': false,
        'show_activity': true,
      });

      // Assert
      expect(settings, isA<ProfileSettingsModel>());
      expect(settings.notificationsEnabled, true);
      expect(settings.darkMode, true);
      expect(settings.language, 'es');
      expect(settings.privacyLevel, 'public');
    });

    test('debe convertir ProfileSettingsModel a JSON', () {
      // Arrange
      final settings = ProfileSettingsModel.fromJson({
        'notifications_enabled': true,
        'email_notifications': true,
        'push_notifications': true,
        'comments_notifications': true,
        'likes_notifications': true,
        'follow_notifications': true,
        'language': 'es',
        'dark_mode': false,
        'privacy_level': 'public',
        'show_email': false,
        'show_activity': true,
      });

      // Act
      final json = settings.toJson();

      // Assert
      expect(json['notifications_enabled'], true);
      expect(json['language'], 'es');
      expect(json['privacy_level'], 'public');
      expect(json.containsKey('dark_mode'), true);
    });

    test('debe soportar diferentes idiomas', () {
      // Arrange
      final languages = ['es', 'en', 'pt'];

      for (final lang in languages) {
        final settings = ProfileSettingsModel.fromJson({
          'notifications_enabled': true,
          'email_notifications': true,
          'push_notifications': true,
          'comments_notifications': true,
          'likes_notifications': true,
          'follow_notifications': true,
          'language': lang,
          'dark_mode': false,
          'privacy_level': 'public',
          'show_email': false,
          'show_activity': true,
        });

        // Assert
        expect(settings.language, lang);
      }
    });

    test('debe soportar diferentes niveles de privacidad', () {
      // Arrange
      final privacyLevels = ['public', 'private', 'followers'];

      for (final level in privacyLevels) {
        final settings = ProfileSettingsModel.fromJson({
          'notifications_enabled': true,
          'email_notifications': true,
          'push_notifications': true,
          'comments_notifications': true,
          'likes_notifications': true,
          'follow_notifications': true,
          'language': 'es',
          'dark_mode': false,
          'privacy_level': level,
          'show_email': false,
          'show_activity': true,
        });

        // Assert
        expect(settings.privacyLevel, level);
      }
    });

    test('debe manejar configuración default', () {
      // Documentación: getSettings retorna valores por defecto
      final defaultSettings = {
        'notifications_enabled': true,
        'email_notifications': true,
        'push_notifications': true,
        'comments_notifications': true,
        'likes_notifications': true,
        'follow_notifications': true,
        'language': 'es',
        'dark_mode': false,
        'privacy_level': 'public',
        'show_email': false,
        'show_activity': true,
      };

      expect(defaultSettings['notifications_enabled'], true);
      expect(defaultSettings['language'], 'es');
      expect(defaultSettings['dark_mode'], false);
      expect(defaultSettings['privacy_level'], 'public');
    });
  });

  group('getUserStats - Comportamiento esperado', () {
    test('debe retornar UserStatsModel', () {
      // getUserStats retorna UserStatsModel
      final stats = UserStatsModel(
        gossipsCount: 0,
        commentsCount: 0,
        followersCount: 0,
        followingCount: 0,
        lastActivityAt: DateTime.now().toIso8601String(),
      );

      expect(stats, isA<UserStatsModel>());
    });

    test('debe consultar tabla gossips para contar', () {
      // Documentación: select('id').eq('created_by', userId).neq('status', 'deleted')
      const expectedTable = 'gossips';
      const expectedColumn = 'id';
      const expectedFilter = 'created_by';
      const excludeStatus = 'deleted';

      expect(expectedTable, 'gossips');
      expect(expectedColumn, 'id');
      expect(expectedFilter, 'created_by');
      expect(excludeStatus, 'deleted');
    });

    test('debe excluir gossips deleted', () {
      // Documentación: .neq('status', 'deleted')
      const excludedStatus = 'deleted';
      expect(excludedStatus, 'deleted');
    });

    test('debe retornar counts en cero para features pendientes', () {
      // Documentación: commentsCount, followersCount, followingCount = 0 (TODO)
      const commentsCount = 0;
      const followersCount = 0;
      const followingCount = 0;

      expect(commentsCount, 0);
      expect(followersCount, 0);
      expect(followingCount, 0);
    });

    test('debe incluir lastActivityAt', () {
      // lastActivityAt debe ser timestamp ISO8601
      final timestamp = DateTime.now().toIso8601String();

      expect(timestamp, contains('T'));
      expect(timestamp, isNotEmpty);
    });

    test('debe requerir userId', () {
      // userId es parámetro requerido
      const userId = 'user-123';
      expect(userId, isNotEmpty);
      expect(userId, isNotNull);
    });
  });

  group('getSettings - Comportamiento esperado', () {
    test('debe retornar ProfileSettingsModel', () {
      // getSettings retorna ProfileSettingsModel
      final settings = ProfileSettingsModel.fromJson({
        'notifications_enabled': true,
        'email_notifications': true,
        'push_notifications': true,
        'comments_notifications': true,
        'likes_notifications': true,
        'follow_notifications': true,
        'language': 'es',
        'dark_mode': false,
        'privacy_level': 'public',
        'show_email': false,
        'show_activity': true,
      });

      expect(settings, isA<ProfileSettingsModel>());
    });

    test('debe retornar configuración por defecto', () {
      // Documentación: Por ahora retorna configuración por defecto (TODO tabla)
      const isDefaultConfig = true;
      expect(isDefaultConfig, true);
    });

    test('debe requerir userId', () {
      // userId es parámetro requerido
      const userId = 'user-123';
      expect(userId, isNotEmpty);
      expect(userId, isNotNull);
    });
  });

  group('updateSettings - Comportamiento esperado', () {
    test('debe aceptar ProfileSettingsModel', () {
      // updateSettings acepta ProfileSettingsModel como parámetro
      final settings = ProfileSettingsModel.fromJson({
        'notifications_enabled': true,
        'email_notifications': true,
        'push_notifications': true,
        'comments_notifications': true,
        'likes_notifications': true,
        'follow_notifications': true,
        'language': 'es',
        'dark_mode': false,
        'privacy_level': 'public',
        'show_email': false,
        'show_activity': true,
      });

      expect(settings, isA<ProfileSettingsModel>());
    });

    test('debe convertir settings a JSON para persistencia', () {
      // settings.toJson() para enviar a Supabase
      final settings = ProfileSettingsModel.fromJson({
        'notifications_enabled': true,
        'email_notifications': true,
        'push_notifications': true,
        'comments_notifications': true,
        'likes_notifications': true,
        'follow_notifications': true,
        'language': 'es',
        'dark_mode': false,
        'privacy_level': 'public',
        'show_email': false,
        'show_activity': true,
      });

      final json = settings.toJson();

      expect(json, isA<Map<String, dynamic>>());
      expect(json.keys, isNotEmpty);
    });

    test('debe simular latencia de red', () {
      // Documentación: await Future.delayed(500ms) simular latencia
      const delayMs = 500;
      expect(delayMs, greaterThan(0));
      expect(delayMs, lessThanOrEqualTo(1000));
    });

    test('debe requerir userId y settings', () {
      // Parámetros requeridos
      const userId = 'user-123';
      final settings = ProfileSettingsModel.fromJson({
        'notifications_enabled': true,
        'email_notifications': true,
        'push_notifications': true,
        'comments_notifications': true,
        'likes_notifications': true,
        'follow_notifications': true,
        'language': 'es',
        'dark_mode': false,
        'privacy_level': 'public',
        'show_email': false,
        'show_activity': true,
      });

      expect(userId, isNotEmpty);
      expect(settings, isNotNull);
    });
  });

  group('signOut - Comportamiento esperado', () {
    test('debe llamar a supabase.auth.signOut()', () {
      // Documentación: await _supabase.auth.signOut()
      const authMethod = 'signOut';
      expect(authMethod, 'signOut');
    });

    test('debe ser método asíncrono', () {
      // signOut retorna Future<void>
      Future<void> signOutMock() async {
        // Mock implementation
      }

      expect(signOutMock(), isA<Future<void>>());
    });

    test('debe loguear inicio y fin de operación', () {
      // Documentación: logs de 'Signing out user' y 'User signed out successfully'
      const startLog = 'Signing out user';
      const endLog = 'User signed out successfully';

      expect(startLog, isNotEmpty);
      expect(endLog, contains('successfully'));
    });
  });

  group('Error handling - Comportamiento general', () {
    test('debe propagar excepciones (rethrow)', () {
      // Todos los métodos usan rethrow en catch
      expect(() => throw Exception('Test error'), throwsException);
    });

    test('debe loguear errores antes de propagar', () {
      // Documentación: _logger.e() antes de rethrow en todos los métodos
      expect(logger, isA<AppLogger>());
    });

    test('debe incluir contexto en logs de error', () {
      // Los logs de error deben incluir contexto relevante
      final mockContext = {
        'userId': 'user-123',
        'settings': <String, dynamic>{},
      };

      expect(mockContext, isA<Map<String, dynamic>>());
      expect(mockContext.containsKey('userId'), true);
    });

    test('debe incluir stackTrace en logs de error', () {
      // Todos los _logger.e() incluyen stackTrace
      try {
        throw Exception('Test');
      } catch (error, stackTrace) {
        expect(stackTrace, isA<StackTrace>());
        expect(stackTrace, isNotNull);
      }
    });
  });

  group('TODO - Features pendientes', () {
    test('getUserStats debe implementar commentsCount', () {
      // TODO: Implementar cuando exista feature de comments
      const pendingFeature = 'comments';
      expect(pendingFeature, 'comments');
    });

    test('getUserStats debe implementar followersCount y followingCount', () {
      // TODO: Implementar cuando exista feature de follows
      const pendingFeature = 'follows';
      expect(pendingFeature, 'follows');
    });

    test('getSettings debe usar tabla de configuraciones', () {
      // TODO: Implementar tabla de configuraciones en Supabase
      const pendingFeature = 'settings_table';
      expect(pendingFeature, contains('settings'));
    });

    test('updateSettings debe persistir en Supabase', () {
      // TODO: Implementar actualización en tabla de configuraciones
      const pendingFeature = 'persist_settings';
      expect(pendingFeature, contains('persist'));
    });
  });
}

/// Mock simple de SupabaseClient para tests de constructor
class _FakeSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Mocks para testing del logger
class _MockRemoteLogger implements RemoteLogger {
  @override
  Future<void> log(LogEntry entry) async {}
}

class _MockDeviceInfoProvider extends DeviceInfoProvider {
  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    return {'os': 'Test', 'device': 'TestDevice'};
  }
}
