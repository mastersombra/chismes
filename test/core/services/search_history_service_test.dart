import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chismes/core/services/search_history_service.dart';
import 'package:chismes/core/logging/logging.dart';

import 'search_history_service_test.mocks.dart';

@GenerateMocks([SharedPreferences, AppLogger])
void main() {
  late SearchHistoryService service;
  late MockSharedPreferences mockPrefs;
  late MockAppLogger mockLogger;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockLogger = MockAppLogger();
    service = SearchHistoryService(mockPrefs, mockLogger);
  });

  group('SearchHistoryService', () {
    group('addSearch', () {
      test('debe agregar búsqueda al historial vacío', () async {
        // Arrange
        when(mockPrefs.getStringList('search_history')).thenReturn(null);
        when(mockPrefs.setStringList('search_history', any))
            .thenAnswer((_) async => true);

        // Act
        await service.addSearch('flutter');

        // Assert
        verify(mockPrefs.setStringList('search_history', ['flutter'])).called(1);
      });

      test('debe mover búsqueda existente al inicio', () async {
        // Arrange
        when(mockPrefs.getStringList('search_history'))
            .thenReturn(['dart', 'flutter', 'widgets']);
        when(mockPrefs.setStringList('search_history', any))
            .thenAnswer((_) async => true);

        // Act
        await service.addSearch('flutter');

        // Assert
        verify(mockPrefs.setStringList(
          'search_history',
          ['flutter', 'dart', 'widgets'],
        )).called(1);
      });

      test('debe limitar historial a 10 elementos', () async {
        // Arrange
        final fullHistory = List.generate(10, (i) => 'query$i');
        when(mockPrefs.getStringList('search_history')).thenReturn(fullHistory);
        when(mockPrefs.setStringList('search_history', any))
            .thenAnswer((_) async => true);

        // Act
        await service.addSearch('new query');

        // Assert
        final captured = verify(
          mockPrefs.setStringList('search_history', captureAny),
        ).captured.single as List<String>;

        expect(captured.length, 10);
        expect(captured.first, 'new query');
      });

      test('debe ignorar queries vacíos', () async {
        // Act
        await service.addSearch('');
        await service.addSearch('   ');

        // Assert
        verifyNever(mockPrefs.setStringList(any, any));
      });
    });

    group('getHistory', () {
      test('debe retornar historial existente', () async {
        // Arrange
        final history = ['flutter', 'dart', 'widgets'];
        when(mockPrefs.getStringList('search_history')).thenReturn(history);

        // Act
        final result = await service.getHistory();

        // Assert
        expect(result, history);
      });

      test('debe retornar lista vacía si no hay historial', () async {
        // Arrange
        when(mockPrefs.getStringList('search_history')).thenReturn(null);

        // Act
        final result = await service.getHistory();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('removeSearch', () {
      test('debe eliminar búsqueda específica', () async {
        // Arrange
        when(mockPrefs.getStringList('search_history'))
            .thenReturn(['flutter', 'dart', 'widgets']);
        when(mockPrefs.setStringList('search_history', any))
            .thenAnswer((_) async => true);

        // Act
        await service.removeSearch('dart');

        // Assert
        verify(mockPrefs.setStringList(
          'search_history',
          ['flutter', 'widgets'],
        )).called(1);
      });
    });

    group('clearHistory', () {
      test('debe limpiar todo el historial', () async {
        // Arrange
        when(mockPrefs.remove('search_history')).thenAnswer((_) async => true);

        // Act
        await service.clearHistory();

        // Assert
        verify(mockPrefs.remove('search_history')).called(1);
      });
    });
  });
}
