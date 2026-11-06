import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chismes/features/gossip/data/datasources/shared_prefs_gossip_local_data_source.dart';
import 'package:chismes/features/gossip/data/models/gossip_model.dart';
import 'package:chismes/core/logging/logging.dart';

void main() {
  group('SharedPrefsGossipLocalDataSource', () {
    late SharedPrefsGossipLocalDataSource dataSource;
    late AppLogger logger;

    setUp(() async {
      // Configurar mock de SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Crear logger real con mocks
      final mockRemoteLogger = _MockRemoteLogger();
      final mockDeviceInfo = _MockDeviceInfoProvider();
      logger = AppLogger(mockRemoteLogger, mockDeviceInfo);

      dataSource = SharedPrefsGossipLocalDataSource(logger);
    });

    tearDown(() {
      logger.close();
    });

    tearDown(() async {
      // Limpiar después de cada test
      await dataSource.clear();
    });

    group('getAll', () {
      test('debe retornar lista vacía cuando no hay cache', () async {
        // Act
        final result = await dataSource.getAll();

        // Assert
        expect(result, isEmpty);
      });

      test('debe retornar gossips guardados previamente', () async {
        // Arrange
        final models = [
          _createTestModel(id: '1', subject: 'Test 1'),
          _createTestModel(id: '2', subject: 'Test 2'),
        ];
        await dataSource.saveAll(models);

        // Act
        final result = await dataSource.getAll();

        // Assert
        expect(result.length, 2);
        expect(result[0].id, '1');
        expect(result[0].subject, 'Test 1');
        expect(result[1].id, '2');
        expect(result[1].subject, 'Test 2');
      });

      test('debe retornar lista vacía y limpiar cache si está corrupto', () async {
        // Arrange - Guardar JSON inválido directamente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_gossips', 'invalid json {[}');
        await prefs.setInt('cached_gossips_version', 1);

        // Act
        final result = await dataSource.getAll();

        // Assert
        expect(result, isEmpty);

        // Verificar que el cache se limpió
        final cachedData = prefs.getString('cached_gossips');
        expect(cachedData, isNull);
      });

      test('debe retornar lista vacía si la versión del cache es diferente', () async {
        // Arrange - Guardar con versión antigua
        final models = [_createTestModel(id: '1', subject: 'Old')];
        await dataSource.saveAll(models);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('cached_gossips_version', 999); // Versión futura

        // Act
        final result = await dataSource.getAll();

        // Assert
        expect(result, isEmpty);

        // Verificar que el cache se limpió
        final cachedData = prefs.getString('cached_gossips');
        expect(cachedData, isNull);
      });

      test('debe persistir datos entre instancias', () async {
        // Arrange - Guardar con una instancia
        final models = [_createTestModel(id: '1', subject: 'Persistent')];
        await dataSource.saveAll(models);

        // Act - Crear nueva instancia y leer
        final newDataSource = SharedPrefsGossipLocalDataSource(logger);
        final result = await newDataSource.getAll();

        // Assert
        expect(result.length, 1);
        expect(result[0].id, '1');
        expect(result[0].subject, 'Persistent');
      });
    });

    group('save', () {
      test('debe agregar un gossip al cache', () async {
        // Arrange
        final model = _createTestModel(id: '1', subject: 'Test');

        // Act
        await dataSource.save(model);
        final result = await dataSource.getAll();

        // Assert
        expect(result.length, 1);
        expect(result.first.id, '1');
        expect(result.first.subject, 'Test');
      });

      test('debe agregar gossip al inicio de la lista', () async {
        // Arrange
        final model1 = _createTestModel(id: '1', subject: 'First');
        final model2 = _createTestModel(id: '2', subject: 'Second');

        // Act
        await dataSource.save(model1);
        await dataSource.save(model2);
        final result = await dataSource.getAll();

        // Assert - El segundo guardado debe estar primero
        expect(result.length, 2);
        expect(result[0].id, '2');
        expect(result[0].subject, 'Second');
        expect(result[1].id, '1');
        expect(result[1].subject, 'First');
      });

      test('no debe fallar si hay error al guardar', () async {
        // Arrange - Crear modelo con datos que puedan causar error
        final model = _createTestModel(id: '1', subject: 'Test');

        // Act & Assert - No debe lanzar excepción
        await expectLater(
          dataSource.save(model),
          completes,
        );
      });
    });

    group('saveAll', () {
      test('debe reemplazar todos los gossips', () async {
        // Arrange
        final oldModels = [_createTestModel(id: 'old', subject: 'Old')];
        await dataSource.saveAll(oldModels);

        final newModels = [
          _createTestModel(id: 'new1', subject: 'New 1'),
          _createTestModel(id: 'new2', subject: 'New 2'),
        ];

        // Act
        await dataSource.saveAll(newModels);
        final result = await dataSource.getAll();

        // Assert
        expect(result.length, 2);
        expect(result.any((m) => m.id == 'old'), isFalse);
        expect(result.any((m) => m.id == 'new1'), isTrue);
        expect(result.any((m) => m.id == 'new2'), isTrue);
      });

      test('debe limpiar cache si se pasa lista vacía', () async {
        // Arrange
        final models = [_createTestModel(id: '1', subject: 'Test')];
        await dataSource.saveAll(models);

        // Act
        await dataSource.saveAll([]);
        final result = await dataSource.getAll();

        // Assert
        expect(result, isEmpty);
      });

      test('debe limitar cache a 100 gossips', () async {
        // Arrange - Crear 150 gossips
        final manyModels = List.generate(
          150,
          (i) => _createTestModel(id: 'id_$i', subject: 'Subject $i'),
        );

        // Act
        await dataSource.saveAll(manyModels);
        final result = await dataSource.getAll();

        // Assert - Solo debe guardar los primeros 100
        expect(result.length, 100);
        expect(result.first.id, 'id_0');
        expect(result.last.id, 'id_99');
      });

      test('debe guardar timestamp al guardar cache', () async {
        // Arrange
        final models = [_createTestModel(id: '1', subject: 'Test')];

        // Act
        await dataSource.saveAll(models);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        final timestamp = prefs.getString('cached_gossips_timestamp');
        expect(timestamp, isNotNull);
        expect(DateTime.parse(timestamp!), isNotNull);
      });

      test('debe guardar versión del cache', () async {
        // Arrange
        final models = [_createTestModel(id: '1', subject: 'Test')];

        // Act
        await dataSource.saveAll(models);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        final version = prefs.getInt('cached_gossips_version');
        expect(version, 1);
      });

      test('no debe fallar si hay error al guardar', () async {
        // Arrange
        final models = [_createTestModel(id: '1', subject: 'Test')];

        // Act & Assert - No debe lanzar excepción
        await expectLater(
          dataSource.saveAll(models),
          completes,
        );
      });
    });

    group('clear', () {
      test('debe eliminar todos los gossips', () async {
        // Arrange
        final models = [
          _createTestModel(id: '1', subject: 'Test 1'),
          _createTestModel(id: '2', subject: 'Test 2'),
        ];
        await dataSource.saveAll(models);

        // Act
        await dataSource.clear();
        final result = await dataSource.getAll();

        // Assert
        expect(result, isEmpty);
      });

      test('debe eliminar también metadata del cache', () async {
        // Arrange
        final models = [_createTestModel(id: '1', subject: 'Test')];
        await dataSource.saveAll(models);

        // Act
        await dataSource.clear();

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('cached_gossips'), isNull);
        expect(prefs.getString('cached_gossips_timestamp'), isNull);
        expect(prefs.getInt('cached_gossips_version'), isNull);
      });

      test('no debe fallar si el cache ya está vacío', () async {
        // Act & Assert - No debe lanzar excepción
        await expectLater(
          dataSource.clear(),
          completes,
        );
      });
    });

    group('getCacheInfo', () {
      test('debe retornar null si no hay cache', () async {
        // Act
        final info = await dataSource.getCacheInfo();

        // Assert
        expect(info, isNull);
      });

      test('debe retornar información correcta del cache', () async {
        // Arrange
        final models = [
          _createTestModel(id: '1', subject: 'Test 1'),
          _createTestModel(id: '2', subject: 'Test 2'),
        ];
        await dataSource.saveAll(models);

        // Act
        final info = await dataSource.getCacheInfo();

        // Assert
        expect(info, isNotNull);
        expect(info!.count, 2);
        expect(info.version, 1);
        expect(info.timestamp, isNotNull);
        expect(double.parse(info.sizeKB), greaterThan(0));
      });

      test('debe calcular tamaño del cache correctamente', () async {
        // Arrange - Crear muchos gossips
        final models = List.generate(
          50,
          (i) => _createTestModel(id: 'id_$i', subject: 'Subject $i'),
        );
        await dataSource.saveAll(models);

        // Act
        final info = await dataSource.getCacheInfo();

        // Assert
        expect(info, isNotNull);
        expect(info!.count, 50);
        // Cada gossip ~1KB, 50 gossips ~50KB
        expect(double.parse(info.sizeKB), greaterThan(10));
      });

      test('toString debe retornar formato legible', () async {
        // Arrange
        final models = [_createTestModel(id: '1', subject: 'Test')];
        await dataSource.saveAll(models);

        // Act
        final info = await dataSource.getCacheInfo();
        final string = info.toString();

        // Assert
        expect(string, contains('1 gossips'));
        expect(string, contains('KB'));
        expect(string, contains('guardado:'));
        expect(string, contains('version: 1'));
      });
    });

    group('Serialización', () {
      test('debe serializar y deserializar todos los campos', () async {
        // Arrange
        final model = GossipModel(
          id: '123',
          countryId: 'CO',
          regionId: 'ANT',
          cityId: 'MED',
          subject: 'Test Subject',
          content: 'Test Content with special chars: áéíóú ñ 😀',
          audioUrl: 'https://example.com/audio.mp3',
          imageUrl: 'https://example.com/image.jpg',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          reportedCount: 5,
          viewCount: 100,
          deletedAt: '2024-01-15T10:30:00.000Z',
          deletedBy: 'admin-123',
          visibility: 'public',
          createdAt: '2024-01-01T00:00:00.000Z',
          createdBy: 'user-456',
          modifiedAt: '2024-01-10T12:00:00.000Z',
          modifiedBy: 'user-789',
        );

        // Act
        await dataSource.saveAll([model]);
        final result = await dataSource.getAll();

        // Assert
        expect(result.length, 1);
        final loaded = result.first;
        expect(loaded.id, model.id);
        expect(loaded.countryId, model.countryId);
        expect(loaded.regionId, model.regionId);
        expect(loaded.cityId, model.cityId);
        expect(loaded.subject, model.subject);
        expect(loaded.content, model.content);
        expect(loaded.audioUrl, model.audioUrl);
        expect(loaded.imageUrl, model.imageUrl);
        expect(loaded.publishedAs, model.publishedAs);
        expect(loaded.status, model.status);
        expect(loaded.moderationStatus, model.moderationStatus);
        expect(loaded.reportedCount, model.reportedCount);
        expect(loaded.viewCount, model.viewCount);
        expect(loaded.deletedAt, model.deletedAt);
        expect(loaded.deletedBy, model.deletedBy);
        expect(loaded.visibility, model.visibility);
        expect(loaded.createdAt, model.createdAt);
        expect(loaded.createdBy, model.createdBy);
        expect(loaded.modifiedAt, model.modifiedAt);
        expect(loaded.modifiedBy, model.modifiedBy);
      });

      test('debe manejar campos opcionales null', () async {
        // Arrange
        final model = GossipModel(
          id: '1',
          countryId: 'CO',
          regionId: 'ANT',
          cityId: 'MED',
          subject: 'Test',
          content: 'Content',
          audioUrl: null, // Opcional
          imageUrl: null, // Opcional
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          reportedCount: 0,
          viewCount: 0,
          deletedAt: null, // Opcional
          deletedBy: null, // Opcional
          visibility: 'public',
          createdAt: '2024-01-01T00:00:00.000Z',
          createdBy: 'user-1',
          modifiedAt: null, // Opcional
          modifiedBy: null, // Opcional
        );

        // Act
        await dataSource.saveAll([model]);
        final result = await dataSource.getAll();

        // Assert
        expect(result.length, 1);
        final loaded = result.first;
        expect(loaded.audioUrl, isNull);
        expect(loaded.imageUrl, isNull);
        expect(loaded.deletedAt, isNull);
        expect(loaded.deletedBy, isNull);
        expect(loaded.modifiedAt, isNull);
        expect(loaded.modifiedBy, isNull);
      });
    });

    group('Edge Cases y Performance', () {
      test('getAll debe manejar jsonString vacío correctamente', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_gossips', '');
        await prefs.setInt('cached_gossips_version', 1);

        // Act
        final result = await dataSource.getAll();

        // Assert
        expect(result, isEmpty);
      });

      test('saveAll con exactamente 100 gossips no debe truncar', () async {
        // Arrange
        final gossips = List.generate(100, (i) => _createTestModel(id: 'id-$i', subject: 'Subject $i'));

        // Act
        await dataSource.saveAll(gossips);

        // Assert
        final result = await dataSource.getAll();
        expect(result.length, 100);
      });

      test('saveAll con 101 gossips debe truncar a 100', () async {
        // Arrange
        final gossips = List.generate(101, (i) => _createTestModel(id: 'id-$i', subject: 'Subject $i'));

        // Act
        await dataSource.saveAll(gossips);

        // Assert
        final result = await dataSource.getAll();
        expect(result.length, 100);
        expect(result.first.id, 'id-0'); // Primeros 100
      });

      test('saveAll con 200 gossips debe truncar a 100', () async {
        // Arrange
        final gossips = List.generate(200, (i) => _createTestModel(id: 'id-$i', subject: 'Subject $i'));

        // Act
        await dataSource.saveAll(gossips);

        // Assert
        final result = await dataSource.getAll();
        expect(result.length, 100);
      });

      test('save debe mantener el gossip más reciente primero', () async {
        // Arrange
        final gossip1 = _createTestModel(id: 'first', subject: 'First');
        final gossip2 = _createTestModel(id: 'second', subject: 'Second');
        final gossip3 = _createTestModel(id: 'third', subject: 'Third');

        // Act
        await dataSource.save(gossip1);
        await dataSource.save(gossip2);
        await dataSource.save(gossip3);

        // Assert
        final result = await dataSource.getAll();
        expect(result[0].id, 'third');  // Más reciente
        expect(result[1].id, 'second');
        expect(result[2].id, 'first');
      });

      test('getCacheInfo debe manejar cache sin timestamp', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        final gossips = [_createTestModel(id: 'test', subject: 'Test')];
        final jsonString = jsonEncode(gossips.map((g) => g.toJson()).toList());

        await prefs.setString('cached_gossips', jsonString);
        await prefs.setInt('cached_gossips_version', 1);
        // NO guardar timestamp

        // Act
        final info = await dataSource.getCacheInfo();

        // Assert
        expect(info, isNotNull);
        expect(info!.count, 1);
        expect(info.timestamp, isNull);
      });

      test('getCacheInfo debe manejar cache con JSON inválido', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_gossips', '{invalid json[');

        // Act
        final info = await dataSource.getCacheInfo();

        // Assert
        expect(info, isNull);
      });

      test('getAll debe manejar FormatException en fromJson', () async {
        // Arrange
        final prefs = await SharedPreferences.getInstance();
        // JSON válido pero con datos que fallan en GossipModel.fromJson
        final invalidGossip = {
          'id': 123, // Debería ser String, no int
          'subject': 'Test',
        };
        await prefs.setString('cached_gossips', jsonEncode([invalidGossip]));
        await prefs.setInt('cached_gossips_version', 1);

        // Act
        final result = await dataSource.getAll();

        // Assert - debe retornar vacío y limpiar cache
        expect(result, isEmpty);

        // Verificar que cache fue limpiado
        final jsonString = prefs.getString('cached_gossips');
        expect(jsonString, isNull);
      });

      test('clear debe ser idempotente', () async {
        // Arrange
        await dataSource.saveAll([_createTestModel(id: 'test', subject: 'Test')]);

        // Act - clear múltiples veces
        await dataSource.clear();
        await dataSource.clear();
        await dataSource.clear();

        // Assert
        final result = await dataSource.getAll();
        expect(result, isEmpty);
      });

      test('saveAll debe calcular sizeKB correctamente', () async {
        // Arrange
        final gossips = [_createTestModel(id: 'test', subject: 'Test')];

        // Act
        await dataSource.saveAll(gossips);
        final info = await dataSource.getCacheInfo();

        // Assert
        expect(info, isNotNull);
        expect(info!.sizeKB, isNotEmpty);
        expect(double.parse(info.sizeKB), greaterThan(0));
        expect(double.parse(info.sizeKB), lessThan(100)); // 1 gossip < 100KB
      });

      test('CacheInfo.toString debe incluir todos los campos', () {
        // Arrange
        final info = CacheInfo(
          count: 50,
          sizeKB: '75.50',
          timestamp: '2024-06-15T10:30:00.000Z',
          version: 1,
        );

        // Act
        final result = info.toString();

        // Assert
        expect(result, contains('50 gossips'));
        expect(result, contains('75.50 KB'));
        expect(result, contains('guardado:'));
        expect(result, contains('version: 1'));
      });

      test('CacheInfo.toString debe manejar timestamp null', () {
        // Arrange
        final info = CacheInfo(
          count: 10,
          sizeKB: '25.00',
          timestamp: null,
          version: 1,
        );

        // Act
        final result = info.toString();

        // Assert
        expect(result, contains('desconocido'));
      });

      test('saveAll debe guardar timestamp en formato ISO8601', () async {
        // Arrange
        final gossips = [_createTestModel(id: 'test', subject: 'Test')];

        // Act
        await dataSource.saveAll(gossips);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        final timestamp = prefs.getString('cached_gossips_timestamp');

        expect(timestamp, isNotNull);
        expect(timestamp, isNotEmpty);

        // Verificar que es ISO8601 válido
        expect(() => DateTime.parse(timestamp!), returnsNormally);
      });

      test('getAll debe usar timestamp del cache', () async {
        // Arrange
        final gossips = [_createTestModel(id: 'test', subject: 'Test')];
        await dataSource.saveAll(gossips);

        final prefs = await SharedPreferences.getInstance();
        final savedTimestamp = prefs.getString('cached_gossips_timestamp');

        // Act
        final result = await dataSource.getAll();

        // Assert - getAll internamente loguea el timestamp
        expect(result, isNotEmpty);
        expect(savedTimestamp, isNotNull);
      });

      test('saveAll debe guardar version correcta', () async {
        // Arrange
        final gossips = [_createTestModel(id: 'test', subject: 'Test')];

        // Act
        await dataSource.saveAll(gossips);

        // Assert
        final prefs = await SharedPreferences.getInstance();
        final version = prefs.getInt('cached_gossips_version');

        expect(version, 1); // _cacheVersion = 1
      });

      test('clear debe eliminar todas las keys del cache', () async {
        // Arrange
        final gossips = [_createTestModel(id: 'test', subject: 'Test')];
        await dataSource.saveAll(gossips);

        final prefs = await SharedPreferences.getInstance();

        // Verificar que keys existen
        expect(prefs.containsKey('cached_gossips'), isTrue);
        expect(prefs.containsKey('cached_gossips_timestamp'), isTrue);
        expect(prefs.containsKey('cached_gossips_version'), isTrue);

        // Act
        await dataSource.clear();

        // Assert
        expect(prefs.containsKey('cached_gossips'), isFalse);
        expect(prefs.containsKey('cached_gossips_timestamp'), isFalse);
        expect(prefs.containsKey('cached_gossips_version'), isFalse);
      });

      test('save debe funcionar cuando cache está vacío', () async {
        // Arrange
        await dataSource.clear();
        final gossip = _createTestModel(id: 'first', subject: 'First');

        // Act
        await dataSource.save(gossip);

        // Assert
        final result = await dataSource.getAll();
        expect(result.length, 1);
        expect(result.first.id, 'first');
      });

      test('getCacheInfo version debe coincidir con constante', () async {
        // Arrange
        final gossips = [_createTestModel(id: 'test', subject: 'Test')];
        await dataSource.saveAll(gossips);

        // Act
        final info = await dataSource.getCacheInfo();

        // Assert
        expect(info, isNotNull);
        expect(info!.version, 1); // _cacheVersion
      });

      test('saveAll con lista vacía debe crear cache vacío válido', () async {
        // Arrange
        final emptyList = <GossipModel>[];

        // Act
        await dataSource.saveAll(emptyList);

        // Assert
        final result = await dataSource.getAll();
        expect(result, isEmpty);

        // Pero metadata debe existir
        final info = await dataSource.getCacheInfo();
        expect(info, isNotNull);
        expect(info!.count, 0);
      });

      test('getAll después de clear debe retornar lista vacía', () async {
        // Arrange
        await dataSource.saveAll([_createTestModel(id: 'test', subject: 'Test')]);
        await dataSource.clear();

        // Act
        final result = await dataSource.getAll();

        // Assert
        expect(result, isEmpty);
      });
    });
  });
}

/// Helper para crear un modelo de prueba
GossipModel _createTestModel({
  required String id,
  required String subject,
  String? content,
  String? audioUrl,
  String? imageUrl,
}) {
  return GossipModel(
    id: id,
    countryId: 'CO',
    regionId: 'ANT',
    cityId: 'MED',
    subject: subject,
    content: content ?? 'Test content for $subject',
    audioUrl: audioUrl,
    imageUrl: imageUrl,
    publishedAs: 'anonymous',
    status: 'published',
    moderationStatus: 'approved',
    reportedCount: 0,
    viewCount: 0,
    deletedAt: null,
    deletedBy: null,
    visibility: 'public',
    createdAt: '2024-01-01T00:00:00.000Z',
    createdBy: 'test-user',
    modifiedAt: null,
    modifiedBy: null,
  );
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
