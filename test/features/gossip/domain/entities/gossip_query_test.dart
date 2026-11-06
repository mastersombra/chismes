import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/gossip/domain/entities/gossip_query.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';

void main() {
  group('GossipQuery', () {
    test('debe crear query con valores personalizados', () {
      // Act
      final query = GossipQuery(
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        status: GossipStatus.published,
        visibility: GossipVisibility.public,
        limit: 50,
        cursor: 'cursor-123',
        orderBy: 'viewCount',
        descending: false,
      );

      // Assert
      expect(query.countryId, 'CO');
      expect(query.regionId, 'ANT');
      expect(query.cityId, 'MED');
      expect(query.status, GossipStatus.published);
      expect(query.visibility, GossipVisibility.public);
      expect(query.limit, 50);
      expect(query.cursor, 'cursor-123');
      expect(query.orderBy, 'viewCount');
      expect(query.descending, false);
    });

    test('debe tener valores por defecto', () {
      // Act
      final query = GossipQuery();

      // Assert
      expect(query.limit, 20);
      expect(query.orderBy, 'createdAt');
      expect(query.descending, true);
      expect(query.countryId, isNull);
      expect(query.regionId, isNull);
      expect(query.cityId, isNull);
      expect(query.status, isNull);
      expect(query.visibility, isNull);
      expect(query.cursor, isNull);
    });

    test('defaultPublic debe crear query con filtros públicos', () {
      // Act
      final query = GossipQuery.defaultPublic();

      // Assert
      expect(query.status, GossipStatus.published);
      expect(query.visibility, GossipVisibility.public);
      expect(query.limit, 20);
      expect(query.orderBy, 'createdAt');
      expect(query.descending, true);
      expect(query.countryId, isNull);
      expect(query.regionId, isNull);
      expect(query.cityId, isNull);
    });

    test('byCity debe crear query filtrado por ciudad', () {
      // Act
      final query = GossipQuery.byCity('medellin-123');

      // Assert
      expect(query.cityId, 'medellin-123');
      expect(query.status, GossipStatus.published);
      expect(query.visibility, GossipVisibility.public);
      expect(query.limit, 20);
      expect(query.orderBy, 'createdAt');
      expect(query.descending, true);
      expect(query.countryId, isNull);
      expect(query.regionId, isNull);
    });

    test('byRegion debe crear query filtrado por región', () {
      // Act
      final query = GossipQuery.byRegion('antioquia-456');

      // Assert
      expect(query.regionId, 'antioquia-456');
      expect(query.status, GossipStatus.published);
      expect(query.visibility, GossipVisibility.public);
      expect(query.limit, 20);
      expect(query.orderBy, 'createdAt');
      expect(query.descending, true);
      expect(query.countryId, isNull);
      expect(query.cityId, isNull);
    });

    test('byCountry debe crear query filtrado por país', () {
      // Act
      final query = GossipQuery.byCountry('colombia-789');

      // Assert
      expect(query.countryId, 'colombia-789');
      expect(query.status, GossipStatus.published);
      expect(query.visibility, GossipVisibility.public);
      expect(query.limit, 20);
      expect(query.orderBy, 'createdAt');
      expect(query.descending, true);
      expect(query.regionId, isNull);
      expect(query.cityId, isNull);
    });

    test('copyWithCursor debe mantener todos los valores excepto cursor', () {
      // Arrange
      final originalQuery = GossipQuery(
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        status: GossipStatus.published,
        visibility: GossipVisibility.public,
        limit: 50,
        cursor: 'old-cursor',
        orderBy: 'viewCount',
        descending: false,
      );

      // Act
      final newQuery = originalQuery.copyWithCursor('new-cursor-456');

      // Assert
      expect(newQuery.countryId, originalQuery.countryId);
      expect(newQuery.regionId, originalQuery.regionId);
      expect(newQuery.cityId, originalQuery.cityId);
      expect(newQuery.status, originalQuery.status);
      expect(newQuery.visibility, originalQuery.visibility);
      expect(newQuery.limit, originalQuery.limit);
      expect(newQuery.orderBy, originalQuery.orderBy);
      expect(newQuery.descending, originalQuery.descending);
      expect(newQuery.cursor, 'new-cursor-456'); // Valor actualizado
      expect(newQuery.cursor, isNot(equals(originalQuery.cursor)));
    });

    test('copyWithCursor desde query sin cursor previo', () {
      // Arrange
      final query = GossipQuery.defaultPublic();

      // Act
      final newQuery = query.copyWithCursor('first-cursor');

      // Assert
      expect(newQuery.cursor, 'first-cursor');
      expect(query.cursor, isNull); // Original no cambia
    });

    test('toString debe incluir todos los campos', () {
      // Arrange
      final query = GossipQuery(
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
        status: GossipStatus.published,
        visibility: GossipVisibility.public,
        limit: 25,
        cursor: 'test-cursor',
        orderBy: 'createdAt',
        descending: true,
      );

      // Act
      final result = query.toString();

      // Assert
      expect(result, contains('GossipQuery('));
      expect(result, contains('countryId: CO'));
      expect(result, contains('regionId: ANT'));
      expect(result, contains('cityId: MED'));
      expect(result, contains('status: GossipStatus.published'));
      expect(result, contains('visibility: GossipVisibility.public'));
      expect(result, contains('limit: 25'));
      expect(result, contains('cursor: test-cursor'));
      expect(result, contains('orderBy: createdAt'));
      expect(result, contains('descending: true'));
    });

    test('toString con valores null debe mostrar null', () {
      // Arrange
      final query = GossipQuery();

      // Act
      final result = query.toString();

      // Assert
      expect(result, contains('countryId: null'));
      expect(result, contains('regionId: null'));
      expect(result, contains('cityId: null'));
      expect(result, contains('status: null'));
      expect(result, contains('visibility: null'));
      expect(result, contains('cursor: null'));
    });

    test('debe permitir múltiples filtros de ubicación simultáneos', () {
      // Act - Aunque en producción son mutuamente excluyentes, la clase lo permite
      final query = GossipQuery(
        countryId: 'CO',
        regionId: 'ANT',
        cityId: 'MED',
      );

      // Assert
      expect(query.countryId, 'CO');
      expect(query.regionId, 'ANT');
      expect(query.cityId, 'MED');
    });

    test('debe permitir cambiar limit personalizado', () {
      // Act
      final query = GossipQuery(limit: 100);

      // Assert
      expect(query.limit, 100);
    });

    test('debe permitir ordenamiento ascendente', () {
      // Act
      final query = GossipQuery(
        orderBy: 'subject',
        descending: false,
      );

      // Assert
      expect(query.orderBy, 'subject');
      expect(query.descending, false);
    });

    test('debe permitir diferentes campos de ordenamiento', () {
      // Act
      final queryByViews = GossipQuery(orderBy: 'viewCount');
      final queryByReports = GossipQuery(orderBy: 'reportedCount');

      // Assert
      expect(queryByViews.orderBy, 'viewCount');
      expect(queryByReports.orderBy, 'reportedCount');
    });

    test('debe permitir diferentes visibilidades', () {
      // Act
      final publicQuery = GossipQuery(visibility: GossipVisibility.public);
      final privateQuery = GossipQuery(visibility: GossipVisibility.private);
      final followersQuery = GossipQuery(visibility: GossipVisibility.followers);

      // Assert
      expect(publicQuery.visibility, GossipVisibility.public);
      expect(privateQuery.visibility, GossipVisibility.private);
      expect(followersQuery.visibility, GossipVisibility.followers);
    });

    test('debe permitir diferentes estados', () {
      // Act
      final draftQuery = GossipQuery(status: GossipStatus.draft);
      final publishedQuery = GossipQuery(status: GossipStatus.published);
      final hiddenQuery = GossipQuery(status: GossipStatus.hidden);
      final deletedQuery = GossipQuery(status: GossipStatus.deleted);

      // Assert
      expect(draftQuery.status, GossipStatus.draft);
      expect(publishedQuery.status, GossipStatus.published);
      expect(hiddenQuery.status, GossipStatus.hidden);
      expect(deletedQuery.status, GossipStatus.deleted);
    });

    group('copyWithLast - Keyset Pagination', () {
      test('debe crear nueva query con lastCreatedAt y lastId', () {
        // Arrange
        final originalQuery = GossipQuery.defaultPublic();
        final timestamp = DateTime.parse('2024-01-15T10:00:00.000Z');
        final lastId = 'gossip-id-123';

        // Act
        final newQuery = originalQuery.copyWithLast(timestamp, lastId);

        // Assert
        expect(newQuery.lastCreatedAt, timestamp);
        expect(newQuery.lastId, lastId);
      });

      test('debe mantener todos los filtros originales', () {
        // Arrange
        final originalQuery = GossipQuery(
          countryId: 'CO',
          regionId: 'ANT',
          cityId: 'MED',
          status: GossipStatus.published,
          visibility: GossipVisibility.public,
          limit: 50,
          orderBy: 'viewCount',
          descending: false,
        );
        final timestamp = DateTime.parse('2024-01-15T10:00:00.000Z');
        final lastId = 'last-gossip-id';

        // Act
        final newQuery = originalQuery.copyWithLast(timestamp, lastId);

        // Assert
        expect(newQuery.countryId, originalQuery.countryId);
        expect(newQuery.regionId, originalQuery.regionId);
        expect(newQuery.cityId, originalQuery.cityId);
        expect(newQuery.status, originalQuery.status);
        expect(newQuery.visibility, originalQuery.visibility);
        expect(newQuery.limit, originalQuery.limit);
        expect(newQuery.orderBy, originalQuery.orderBy);
        expect(newQuery.descending, originalQuery.descending);
      });

      test('debe actualizar lastCreatedAt y lastId sin afectar original', () {
        // Arrange
        final originalQuery = GossipQuery.defaultPublic();
        final timestamp = DateTime.parse('2024-01-15T10:00:00.000Z');
        final lastId = 'new-id';

        // Act
        final newQuery = originalQuery.copyWithLast(timestamp, lastId);

        // Assert
        expect(newQuery.lastCreatedAt, timestamp);
        expect(newQuery.lastId, lastId);
        expect(originalQuery.lastCreatedAt, isNull);
        expect(originalQuery.lastId, isNull);
      });

      test('debe permitir encadenar múltiples copyWithLast', () {
        // Arrange
        final query1 = GossipQuery.defaultPublic();
        final timestamp1 = DateTime.parse('2024-01-15T10:00:00.000Z');
        final timestamp2 = DateTime.parse('2024-01-15T11:00:00.000Z');

        // Act
        final query2 = query1.copyWithLast(timestamp1, 'id-1');
        final query3 = query2.copyWithLast(timestamp2, 'id-2');

        // Assert
        expect(query1.lastCreatedAt, isNull);
        expect(query2.lastCreatedAt, timestamp1);
        expect(query2.lastId, 'id-1');
        expect(query3.lastCreatedAt, timestamp2);
        expect(query3.lastId, 'id-2');
      });

      test('debe funcionar con query byCity', () {
        // Arrange
        final query = GossipQuery.byCity('medellin');
        final timestamp = DateTime.parse('2024-01-15T10:00:00.000Z');

        // Act
        final paginatedQuery = query.copyWithLast(timestamp, 'last-id');

        // Assert
        expect(paginatedQuery.cityId, 'medellin');
        expect(paginatedQuery.lastCreatedAt, timestamp);
        expect(paginatedQuery.lastId, 'last-id');
      });

      test('debe funcionar con query byRegion', () {
        // Arrange
        final query = GossipQuery.byRegion('antioquia');
        final timestamp = DateTime.parse('2024-01-15T10:00:00.000Z');

        // Act
        final paginatedQuery = query.copyWithLast(timestamp, 'last-id');

        // Assert
        expect(paginatedQuery.regionId, 'antioquia');
        expect(paginatedQuery.lastCreatedAt, timestamp);
        expect(paginatedQuery.lastId, 'last-id');
      });

      test('debe funcionar con query byCountry', () {
        // Arrange
        final query = GossipQuery.byCountry('colombia');
        final timestamp = DateTime.parse('2024-01-15T10:00:00.000Z');

        // Act
        final paginatedQuery = query.copyWithLast(timestamp, 'last-id');

        // Assert
        expect(paginatedQuery.countryId, 'colombia');
        expect(paginatedQuery.lastCreatedAt, timestamp);
        expect(paginatedQuery.lastId, 'last-id');
      });
    });

    group('lastCreatedAt y lastId en constructor', () {
      test('debe permitir crear query con lastCreatedAt y lastId', () {
        // Arrange
        final timestamp = DateTime.parse('2024-01-15T10:00:00.000Z');

        // Act
        final query = GossipQuery(
          lastCreatedAt: timestamp,
          lastId: 'some-id',
        );

        // Assert
        expect(query.lastCreatedAt, timestamp);
        expect(query.lastId, 'some-id');
      });

      test('debe mantener lastCreatedAt y lastId como null por defecto', () {
        // Act
        final query = GossipQuery();

        // Assert
        expect(query.lastCreatedAt, isNull);
        expect(query.lastId, isNull);
      });
    });
  });
}
