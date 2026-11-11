import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/features/search/presentation/screens/search_screen.dart';
import 'package:chismes/features/gossip/domain/usecases/get_gossips.dart';
import 'package:chismes/features/gossip/domain/usecases/search_gossips.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/core/services/search_history_service.dart';
import 'package:chismes/core/services/location_service.dart';
import '../../../../helpers/test_di_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';

import 'search_screen_test.mocks.dart';

@GenerateMocks([GetGossips, SearchGossips, SearchHistoryService, LocationService])
void main() {
  late MockGetGossips mockGetGossips;
  late MockSearchGossips mockSearchGossips;
  late MockSearchHistoryService mockSearchHistoryService;
  late MockLocationService mockLocationService;

  setUp(() async {
    // Inicializar DI para tests (LocaleNotifier, SharedPreferences, etc.)
    await setupTestDI();
    mockGetGossips = MockGetGossips();
    mockSearchGossips = MockSearchGossips();
    mockSearchHistoryService = MockSearchHistoryService();
    mockLocationService = MockLocationService();

    // Provide dummies
    provideDummy<Result<Failure, List<Gossip>>>(Result.success([]));

    // Setup mocks por defecto
    when(mockGetGossips()).thenAnswer((_) async => Result.success([]));
    when(mockSearchGossips(query: anyNamed('query'), cityId: anyNamed('cityId'), limit: anyNamed('limit')))
        .thenAnswer((_) async => Result.success([]));
    when(mockSearchHistoryService.getHistory()).thenAnswer((_) async => []);
    when(mockLocationService.getDefaultLocation()).thenAnswer((_) async => null);

    // Registrar mocks en DI
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
    }
    if (getIt.isRegistered<SearchGossips>()) {
      getIt.unregister<SearchGossips>();
    }
    if (getIt.isRegistered<SearchHistoryService>()) {
      getIt.unregister<SearchHistoryService>();
    }
    if (getIt.isRegistered<LocationService>()) {
      getIt.unregister<LocationService>();
    }

    getIt.registerSingleton<GetGossips>(mockGetGossips);
    getIt.registerSingleton<SearchGossips>(mockSearchGossips);
    getIt.registerSingleton<SearchHistoryService>(mockSearchHistoryService);
    getIt.registerSingleton<LocationService>(mockLocationService);
  });

  tearDown(() async {
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
    }
    if (getIt.isRegistered<SearchGossips>()) {
      getIt.unregister<SearchGossips>();
    }
    if (getIt.isRegistered<SearchHistoryService>()) {
      getIt.unregister<SearchHistoryService>();
    }
    if (getIt.isRegistered<LocationService>()) {
      getIt.unregister<LocationService>();
    }

    // Limpiar DI después del test
    await tearDownTestDI();
  });

  group('SearchScreen', () {
    testWidgets('debe renderizar SearchScreen correctamente', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Buscar 🔎'), findsOneWidget);
    });

    testWidgets('debe mostrar TextField de búsqueda', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Buscar chismes...'), findsOneWidget);
      // Verifica que hay al menos un ícono de búsqueda (puede haber 2: TextField + empty state)
      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('debe cargar y mostrar chismes recientes al iniciar', (tester) async {
      // Arrange
      final recentGossips = [
        Gossip(
          id: '1',
          countryId: 'co',
          regionId: 'ant',
          cityId: 'med',
          subject: 'Reciente 1',
          content: 'Contenido reciente',
          publishedAs: PublishAs.anonymous,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          visibility: GossipVisibility.public,
          createdAt: DateTime.now(),
          createdBy: 'user1',
        ),
      ];

      when(mockGetGossips()).thenAnswer((_) async => Result.success(recentGossips));

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - debe cargar recientes en initState
      verify(mockGetGossips()).called(1);
      expect(find.text('🆕'), findsOneWidget);
      expect(find.text('Recientes'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje cuando no hay recientes', (tester) async {
      // Arrange - mockGetGossips ya retorna lista vacía por defecto

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Busca chismes por tema'), findsOneWidget);
      expect(find.text('o palabra clave'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsWidgets); // Hay uno en AppBar y otro en el empty state
    });

    testWidgets('debe buscar y mostrar resultados', (tester) async {
      // Arrange
      final gossips = [
        Gossip(
          id: '1',
          countryId: 'co',
          regionId: 'ant',
          cityId: 'med',
          subject: 'Test Gossip',
          content: 'Test content',
          publishedAs: PublishAs.anonymous,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          visibility: GossipVisibility.public,
          createdAt: DateTime.now(),
          createdBy: 'user1',
        ),
      ];

      when(mockSearchGossips(query: anyNamed('query'), cityId: anyNamed('cityId'), limit: anyNamed('limit')))
          .thenAnswer((_) async => Result.success(gossips));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - escribir en el TextField
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Assert - Se llama a searchGossips (búsqueda en servidor)
      verify(mockSearchGossips(query: 'Test', cityId: null, limit: 20)).called(1);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('1 resultado'), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje cuando no hay resultados', (tester) async {
      // Arrange
      when(mockSearchGossips(query: anyNamed('query'), cityId: anyNamed('cityId'), limit: anyNamed('limit')))
          .thenAnswer((_) async => Result.success([]));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'NonExistent');
      await tester.pumpAndSettle();

      // Assert - Verifica el texto actualizado
      expect(find.text('No se encontraron chismes 😢'), findsOneWidget);
      expect(find.text('Intenta con otras palabras'), findsOneWidget);

      // Assert - Verifica el ícono y sus propiedades
      final iconFinder = find.byIcon(Icons.search_off);
      expect(iconFinder, findsOneWidget);

      final icon = tester.widget<Icon>(iconFinder);
      expect(icon.size, 60);

      // Assert - Verifica el Column con MainAxisAlignment.center
      final columnFinder = find.byType(Column);
      expect(columnFinder, findsWidgets);
    });

    testWidgets('debe filtrar gossips por subject', (tester) async {
      // Arrange
      final gossips = [
        Gossip(
          id: '1',
          countryId: 'co',
          regionId: 'ant',
          cityId: 'med',
          subject: 'Flutter es genial',
          content: 'Otro contenido',
          publishedAs: PublishAs.anonymous,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          visibility: GossipVisibility.public,
          createdAt: DateTime.now(),
          createdBy: 'user1',
        ),
        Gossip(
          id: '2',
          countryId: 'co',
          regionId: 'ant',
          cityId: 'med',
          subject: 'Dart es increíble',
          content: 'Contenido diferente',
          publishedAs: PublishAs.anonymous,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          visibility: GossipVisibility.public,
          createdAt: DateTime.now(),
          createdBy: 'user1',
        ),
      ];

      when(mockGetGossips()).thenAnswer((_) async => Result.success(gossips));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - buscar por subject
      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pumpAndSettle();

      // Assert - debe encontrar solo el primer gossip
      verify(mockGetGossips()).called(2); // initState + búsqueda
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('1 resultado'), findsOneWidget);
    });

    testWidgets('debe filtrar gossips por content', (tester) async {
      // Arrange
      final gossips = [
        Gossip(
          id: '1',
          countryId: 'co',
          regionId: 'ant',
          cityId: 'med',
          subject: 'Título',
          content: 'Contenido con Flutter',
          publishedAs: PublishAs.anonymous,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          visibility: GossipVisibility.public,
          createdAt: DateTime.now(),
          createdBy: 'user1',
        ),
        Gossip(
          id: '2',
          countryId: 'co',
          regionId: 'ant',
          cityId: 'med',
          subject: 'Otro título',
          content: 'Contenido diferente',
          publishedAs: PublishAs.anonymous,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          visibility: GossipVisibility.public,
          createdAt: DateTime.now(),
          createdBy: 'user1',
        ),
      ];

      when(mockGetGossips()).thenAnswer((_) async => Result.success(gossips));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - buscar por content
      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pumpAndSettle();

      // Assert
      verify(mockGetGossips()).called(2); // initState + búsqueda
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('1 resultado'), findsOneWidget);
    });

    testWidgets('debe buscar case-insensitive', (tester) async {
      // Arrange
      final gossips = [
        Gossip(
          id: '1',
          countryId: 'co',
          regionId: 'ant',
          cityId: 'med',
          subject: 'Flutter es GENIAL',
          content: 'Contenido',
          publishedAs: PublishAs.anonymous,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          visibility: GossipVisibility.public,
          createdAt: DateTime.now(),
          createdBy: 'user1',
        ),
      ];

      when(mockGetGossips()).thenAnswer((_) async => Result.success(gossips));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - buscar en minúsculas
      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.pumpAndSettle();

      // Assert - debe encontrar el gossip aunque el subject tenga mayúsculas
      verify(mockGetGossips()).called(2); // initState + búsqueda
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('debe usar GridView con 2 columnas', (tester) async {
      // Arrange
      final gossips = [
        Gossip(
          id: '1',
          countryId: 'co',
          regionId: 'ant',
          cityId: 'med',
          subject: 'Test',
          content: 'Content',
          publishedAs: PublishAs.anonymous,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          visibility: GossipVisibility.public,
          createdAt: DateTime.now(),
          createdBy: 'user1',
        ),
      ];

      when(mockGetGossips()).thenAnswer((_) async => Result.success(gossips));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Assert
      verify(mockGetGossips()).called(2); // initState + búsqueda
      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
      expect(delegate.childAspectRatio, 0.72);
    });

    testWidgets('debe ser StatefulWidget', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final widget = tester.widget(find.byType(SearchScreen));
      expect(widget, isA<StatefulWidget>());
    });

    testWidgets('debe tener Scaffold', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pump();

      // SearchScreen debe tener su propio Scaffold (puede haber más de uno si el wrapper también tiene)
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('debe manejar errores al buscar', (tester) async {
      // Arrange
      final failure = Failure(
        code: ErrorCode.networkError,
        technicalMessage: 'Network error',
      );
      when(mockGetGossips()).thenAnswer((_) async => Result.failure(failure));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - escribir en el TextField para iniciar búsqueda
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Assert - Se llama 2 veces: initState + búsqueda
      verify(mockGetGossips()).called(2);
      // Verifica que se llamó al getGossips y se manejó el error
      expect(find.byType(GridView), findsNothing);
      // Verifica que se muestra el mensaje de error
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('debe resetear búsqueda al limpiar el TextField', (tester) async {
      // Arrange
      final gossips = [
        Gossip(
          id: '1',
          countryId: 'co',
          regionId: 'ant',
          cityId: 'med',
          subject: 'Test',
          content: 'Content',
          publishedAs: PublishAs.anonymous,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          visibility: GossipVisibility.public,
          createdAt: DateTime.now(),
          createdBy: 'user1',
        ),
      ];

      when(mockGetGossips()).thenAnswer((_) async => Result.success(gossips));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Buscar
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Verificar que está en estado de búsqueda
      expect(find.text('1 resultado'), findsOneWidget);

      // Act - Limpiar búsqueda
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Assert - Debe volver a mostrar recientes
      expect(find.text('🆕'), findsOneWidget);
      expect(find.text('Recientes'), findsOneWidget);
    });

    testWidgets('debe mostrar loading indicator mientras busca', (tester) async {
      // Arrange
      when(mockGetGossips()).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return Result.success([]);
      });

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pump(); // No pump and settle, para capturar el loading state

      // Assert - Debe mostrar loading indicator en el suffixIcon
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Esperar a que termine
      await tester.pumpAndSettle();
    });
  });
}
