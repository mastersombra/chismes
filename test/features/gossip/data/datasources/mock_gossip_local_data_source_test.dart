import 'package:flutter_test/flutter_test.dart';
import '../../../../fixtures/mocks/mock_gossip_data_source.dart';
import 'package:chismes/features/gossip/data/models/gossip_model.dart';

void main() {
  group('MockGossipLocalDataSource', () {
    late MockGossipLocalDataSource dataSource;

    setUp(() {
      dataSource = MockGossipLocalDataSource();
    });

    test('getAll debe retornar lista vacía inicialmente', () async {
      // Act
      final result = await dataSource.getAll();

      // Assert
      expect(result, isEmpty);
    });

    test('save debe agregar un gossip', () async {
      // Arrange
      final model = GossipModel(
        id: '1',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Content',
        publishedAs: 'anonymous',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-01T00:00:00.000Z',
        createdBy: 'user-1',
      );

      // Act
      await dataSource.save(model);
      final result = await dataSource.getAll();

      // Assert
      expect(result.length, 1);
      expect(result.first.id, '1');
      expect(result.first.subject, 'Test');
    });

    test('save debe agregar múltiples gossips', () async {
      // Arrange
      final model1 = GossipModel(
        id: '1',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test 1',
        content: 'Content 1',
        publishedAs: 'anonymous',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-01T00:00:00.000Z',
        createdBy: 'user-1',
      );

      final model2 = GossipModel(
        id: '2',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test 2',
        content: 'Content 2',
        publishedAs: 'profile',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-02T00:00:00.000Z',
        createdBy: 'user-2',
      );

      // Act
      await dataSource.save(model1);
      await dataSource.save(model2);
      final result = await dataSource.getAll();

      // Assert
      expect(result.length, 2);
      // Último guardado debe estar primero (insert at 0)
      expect(result.first.id, '2');
      expect(result.last.id, '1');
    });

    test('saveAll debe reemplazar todos los gossips', () async {
      // Arrange
      final oldModel = GossipModel(
        id: 'old',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Old',
        content: 'Old Content',
        publishedAs: 'anonymous',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-01T00:00:00.000Z',
        createdBy: 'user-1',
      );

      await dataSource.save(oldModel);

      final newModels = [
        GossipModel(
          id: 'new1',
          countryId: 'CO',
          regionId: 'ANT',
          cityId: 'MED',
          subject: 'New 1',
          content: 'New Content 1',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-02T00:00:00.000Z',
          createdBy: 'user-2',
        ),
        GossipModel(
          id: 'new2',
          countryId: 'CO',
          regionId: 'ANT',
          cityId: 'MED',
          subject: 'New 2',
          content: 'New Content 2',
          publishedAs: 'profile',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-03T00:00:00.000Z',
          createdBy: 'user-3',
        ),
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

    test('saveAll con lista vacía debe limpiar todos los datos', () async {
      // Arrange
      final model = GossipModel(
        id: '1',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Test',
        content: 'Content',
        publishedAs: 'anonymous',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-01T00:00:00.000Z',
        createdBy: 'user-1',
      );

      await dataSource.save(model);

      // Act
      await dataSource.saveAll([]);
      final result = await dataSource.getAll();

      // Assert
      expect(result, isEmpty);
    });

    test('clear debe eliminar todos los gossips', () async {
      // Arrange
      final models = [
        GossipModel(
          id: '1',
          countryId: 'CO',
          regionId: 'ANT',
          cityId: 'MED',
          subject: 'Test 1',
          content: 'Content 1',
          publishedAs: 'anonymous',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-01T00:00:00.000Z',
          createdBy: 'user-1',
        ),
        GossipModel(
          id: '2',
          countryId: 'CO',
          regionId: 'ANT',
          cityId: 'MED',
          subject: 'Test 2',
          content: 'Content 2',
          publishedAs: 'profile',
          status: 'published',
          moderationStatus: 'approved',
          visibility: 'public',
          createdAt: '2024-01-02T00:00:00.000Z',
          createdBy: 'user-2',
        ),
      ];

      await dataSource.saveAll(models);

      // Act
      await dataSource.clear();
      final result = await dataSource.getAll();

      // Assert
      expect(result, isEmpty);
    });

    test('save debe insertar al inicio de la lista', () async {
      // Arrange
      final model1 = GossipModel(
        id: '1',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'First',
        content: 'Content',
        publishedAs: 'anonymous',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-01T00:00:00.000Z',
        createdBy: 'user-1',
      );

      final model2 = GossipModel(
        id: '2',
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        subject: 'Second',
        content: 'Content',
        publishedAs: 'anonymous',
        status: 'published',
        moderationStatus: 'approved',
        visibility: 'public',
        createdAt: '2024-01-02T00:00:00.000Z',
        createdBy: 'user-2',
      );

      // Act
      await dataSource.save(model1);
      await dataSource.save(model2);
      final result = await dataSource.getAll();

      // Assert - El segundo guardado debe estar primero
      expect(result.first.id, '2');
      expect(result.first.subject, 'Second');
      expect(result.last.id, '1');
      expect(result.last.subject, 'First');
    });
  });
}
