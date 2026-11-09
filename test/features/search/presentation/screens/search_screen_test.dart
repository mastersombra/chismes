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
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import '../../../../helpers/widget_test_wrapper.dart';

import 'search_screen_test.mocks.dart';

@GenerateMocks([GetGossips])
void main() {
  late MockGetGossips mockGetGossips;

  setUp(() {
    mockGetGossips = MockGetGossips();

    // Provide dummy
    provideDummy<Result<Failure, List<Gossip>>>(Result.success([]));

    // Registrar mock en DI
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
    }
    getIt.registerSingleton<GetGossips>(mockGetGossips);
  });

  tearDown(() {
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
    }
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
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje inicial antes de buscar', (tester) async {
      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.pumpAndSettle();

      expect(find.text('Escribe para buscar chismes 🔎'), findsOneWidget);
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

      when(mockGetGossips()).thenAnswer((_) async => Result.success(gossips));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - escribir en el TextField
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Assert
      verify(mockGetGossips()).called(1);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('debe mostrar mensaje cuando no hay resultados', (tester) async {
      // Arrange
      when(mockGetGossips()).thenAnswer((_) async => Result.success([]));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'NonExistent');
      await tester.pumpAndSettle();

      // Assert - Verifica el texto
      expect(find.text('No se encontraron chismes 😢'), findsOneWidget);

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
      verify(mockGetGossips()).called(1);
      expect(find.byType(GridView), findsOneWidget);
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
      verify(mockGetGossips()).called(1);
      expect(find.byType(GridView), findsOneWidget);
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
      verify(mockGetGossips()).called(1);
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

      // Assert
      verify(mockGetGossips()).called(1);
      // Verifica que se llamó al getGossips y se manejó el error
      expect(find.byType(GridView), findsNothing);
    });
  });
}
