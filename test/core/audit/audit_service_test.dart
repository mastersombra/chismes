import 'package:chismes/core/audit/auditable.dart';
import 'package:chismes/core/audit/audit_service.dart';
import 'package:chismes/core/auth/auth_repository.dart';
import 'package:chismes/core/auth/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'audit_service_test.mocks.dart';

// Mock de AuthRepository
@GenerateMocks([AuthRepository])
void main() {
  group('AuditService', () {
    late MockAuthRepository mockAuthRepository;
    late AuditService auditService;
    late User testUser;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      auditService = AuditService(authRepository: mockAuthRepository);
      testUser = const User(
        id: 'user-123',
        email: 'test@example.com',
      );
    });

    group('prepareForCreate', () {
      test('debe agregar campos de auditoría correctamente', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(testUser);
        final data = {'title': 'Test', 'content': 'Test content'};

        // Act
        final result = auditService.prepareForCreate(data);

        // Assert
        expect(result['title'], equals('Test'));
        expect(result['content'], equals('Test content'));
        expect(result['createdAt'], isNotNull);
        expect(result['createdBy'], equals('user-123'));
        expect(result['modifiedAt'], isNull);
        expect(result['modifiedBy'], isNull);
      });

      test('debe preservar datos existentes', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(testUser);
        final data = {
          'id': 'item-1',
          'name': 'Test Item',
          'count': 42,
          'active': true,
        };

        // Act
        final result = auditService.prepareForCreate(data);

        // Assert
        expect(result['id'], equals('item-1'));
        expect(result['name'], equals('Test Item'));
        expect(result['count'], equals(42));
        expect(result['active'], isTrue);
        expect(result['createdBy'], equals('user-123'));
      });

      test('debe generar timestamp en formato ISO 8601', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(testUser);
        final data = {'title': 'Test'};

        // Act
        final result = auditService.prepareForCreate(data);

        // Assert
        final createdAt = result['createdAt'] as String;
        expect(createdAt, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:')));
        expect(DateTime.parse(createdAt), isA<DateTime>());
      });

      test('debe lanzar StateError cuando no hay usuario autenticado', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);
        final data = {'title': 'Test'};

        // Act & Assert
        expect(
          () => auditService.prepareForCreate(data),
          throwsStateError,
        );
      });

      test('debe lanzar StateError cuando userId está vacío', () {
        // Arrange
        final userWithEmptyId = const User(id: '', email: 'test@example.com');
        when(mockAuthRepository.currentUser).thenReturn(userWithEmptyId);
        final data = {'title': 'Test'};

        // Act & Assert
        expect(
          () => auditService.prepareForCreate(data),
          throwsStateError,
        );
      });

      test('debe incluir mensaje descriptivo en StateError', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);
        final data = {'title': 'Test'};

        // Act & Assert
        expect(
          () => auditService.prepareForCreate(data),
          throwsA(
            predicate(
              (e) =>
                  e is StateError &&
                  e.message.contains('Usuario no autenticado'),
            ),
          ),
        );
      });
    });

    group('prepareForUpdate', () {
      test('debe agregar campos de modificación correctamente', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(testUser);
        final data = {'title': 'Updated Title'};

        // Act
        final result = auditService.prepareForUpdate(data);

        // Assert
        expect(result['title'], equals('Updated Title'));
        expect(result['modifiedAt'], isNotNull);
        expect(result['modifiedBy'], equals('user-123'));
      });

      test('debe preservar datos existentes', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(testUser);
        final data = {
          'id': 'item-1',
          'title': 'Updated',
          'count': 99,
        };

        // Act
        final result = auditService.prepareForUpdate(data);

        // Assert
        expect(result['id'], equals('item-1'));
        expect(result['title'], equals('Updated'));
        expect(result['count'], equals(99));
        expect(result['modifiedBy'], equals('user-123'));
      });

      test('debe generar timestamp en formato ISO 8601', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(testUser);
        final data = {'title': 'Updated'};

        // Act
        final result = auditService.prepareForUpdate(data);

        // Assert
        final modifiedAt = result['modifiedAt'] as String;
        expect(modifiedAt, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:')));
        expect(DateTime.parse(modifiedAt), isA<DateTime>());
      });

      test('debe lanzar StateError cuando no hay usuario autenticado', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(null);
        final data = {'title': 'Updated'};

        // Act & Assert
        expect(
          () => auditService.prepareForUpdate(data),
          throwsStateError,
        );
      });

      test('no debe modificar campos createdAt/createdBy', () {
        // Arrange
        when(mockAuthRepository.currentUser).thenReturn(testUser);
        final data = {
          'title': 'Updated',
          'createdAt': '2024-01-01T00:00:00Z',
          'createdBy': 'user-old',
        };

        // Act
        final result = auditService.prepareForUpdate(data);

        // Assert
        expect(result['createdAt'], equals('2024-01-01T00:00:00Z'));
        expect(result['createdBy'], equals('user-old'));
        expect(result['modifiedBy'], equals('user-123'));
      });
    });

    group('isValidAudit', () {
      test('debe retornar true para auditoría válida sin modificaciones', () {
        // Arrange
        final entity = TestAuditable(
          createdAt: DateTime(2024, 1, 1),
          createdBy: 'user-123',
        );

        // Act
        final result = auditService.isValidAudit(entity);

        // Assert
        expect(result, isTrue);
      });

      test('debe retornar true para auditoría válida con modificaciones', () {
        // Arrange
        final entity = TestAuditable(
          createdAt: DateTime(2024, 1, 1),
          createdBy: 'user-123',
          modifiedAt: DateTime(2024, 1, 2),
          modifiedBy: 'user-456',
        );

        // Act
        final result = auditService.isValidAudit(entity);

        // Assert
        expect(result, isTrue);
      });

      test('debe retornar false cuando createdBy está vacío', () {
        // Arrange
        final entity = TestAuditable(
          createdAt: DateTime(2024, 1, 1),
          createdBy: '',
        );

        // Act
        final result = auditService.isValidAudit(entity);

        // Assert
        expect(result, isFalse);
      });

      test('debe retornar false cuando createdBy es null (autor oculto)', () {
        final entity = TestAuditable(
          createdAt: DateTime(2024, 1, 1),
          createdBy: null,
        );

        expect(auditService.isValidAudit(entity), isFalse);
      });

      test('debe retornar false cuando tiene modifiedAt sin modifiedBy', () {
        // Arrange
        final entity = TestAuditable(
          createdAt: DateTime(2024, 1, 1),
          createdBy: 'user-123',
          modifiedAt: DateTime(2024, 1, 2),
          modifiedBy: null,
        );

        // Act
        final result = auditService.isValidAudit(entity);

        // Assert
        expect(result, isFalse);
      });

      test('debe retornar false cuando tiene modifiedBy sin modifiedAt', () {
        // Arrange
        final entity = TestAuditable(
          createdAt: DateTime(2024, 1, 1),
          createdBy: 'user-123',
          modifiedAt: null,
          modifiedBy: 'user-456',
        );

        // Act
        final result = auditService.isValidAudit(entity);

        // Assert
        expect(result, isFalse);
      });
    });

    group('getAuditInfo', () {
      test('debe retornar info de auditoría sin modificaciones', () {
        // Arrange
        final entity = TestAuditable(
          createdAt: DateTime(2024, 1, 1, 10, 30),
          createdBy: 'user-123',
        );

        // Act
        final result = auditService.getAuditInfo(entity);

        // Assert
        expect(result, contains('Created by user-123'));
        expect(result, contains('2024-01-01'));
        expect(result, contains('10:30'));
        expect(result, isNot(contains('modified')));
      });

      test('debe retornar info de auditoría con modificaciones', () {
        // Arrange
        final entity = TestAuditable(
          createdAt: DateTime(2024, 1, 1, 10, 30),
          createdBy: 'user-123',
          modifiedAt: DateTime(2024, 1, 2, 15, 45),
          modifiedBy: 'user-456',
        );

        // Act
        final result = auditService.getAuditInfo(entity);

        // Assert
        expect(result, contains('Created by user-123'));
        expect(result, contains('2024-01-01'));
        expect(result, contains('modified by user-456'));
        expect(result, contains('2024-01-02'));
      });

      test('debe usar formato ISO 8601 en timestamps', () {
        // Arrange
        final entity = TestAuditable(
          createdAt: DateTime(2024, 3, 15, 8, 20, 30),
          createdBy: 'user-123',
        );

        // Act
        final result = auditService.getAuditInfo(entity);

        // Assert
        expect(result, matches(RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}')));
      });
    });
  });
}

// Clase de test que implementa Auditable
class TestAuditable implements Auditable {
  @override
  final DateTime createdAt;

  @override
  final String? createdBy;

  @override
  final DateTime? modifiedAt;

  @override
  final String? modifiedBy;

  TestAuditable({
    required this.createdAt,
    required this.createdBy,
    this.modifiedAt,
    this.modifiedBy,
  });
}
