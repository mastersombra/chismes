import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/features/home/presentation/screens/home_screen.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/domain/usecases/get_gossips.dart';
import 'package:chismes/features/gossip/presentation/widgets/gossip_card.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/di/injection_container.dart';

import 'home_screen_test.mocks.dart';

@GenerateMocks([GetGossips])
void main() {
  late MockGetGossips mockGetGossips;

  setUp(() {
    mockGetGossips = MockGetGossips();

    // Proporcionar dummy value
    provideDummy<Result<Failure, List<Gossip>>>(
      Result.success(<Gossip>[]),
    );

    // Limpiar y registrar mock en getIt
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
    }
    getIt.registerSingleton<GetGossips>(mockGetGossips);
  });

  tearDown(() {
    // Limpiar después de cada test
    if (getIt.isRegistered<GetGossips>()) {
      getIt.unregister<GetGossips>();
    }
  });

  group('HomeScreen', () {
    final mockGossips = [
      Gossip(
        id: 'test-1',
        countryId: '1',
        regionId: 'ant',
        cityId: 'med',
        subject: 'Test Subject 1',
        content: 'Test Content 1',
        audioUrl: null,
        imageUrl: 'https://example.com/image1.jpg',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-1',
        modifiedAt: null,
        modifiedBy: null,
      ),
      Gossip(
        id: 'test-2',
        countryId: '1',
        regionId: 'ant',
        cityId: 'med',
        subject: 'Test Subject 2',
        content: 'Test Content 2',
        audioUrl: null,
        imageUrl: 'https://example.com/image2.jpg',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        reportedCount: 0,
        viewCount: 0,
        deletedAt: null,
        deletedBy: null,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'user-2',
        modifiedAt: null,
        modifiedBy: null,
      ),
    ];

    testWidgets('debe renderizar AppBar con título', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.text('Chismes 🔥'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('debe renderizar Scaffold', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('debe renderizar RefreshIndicator', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('debe renderizar GridView', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('debe cargar gossips al iniciar', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Esperar a que cargue
      await tester.pumpAndSettle();

      // Debe llamar a GetGossips
      verify(mockGetGossips()).called(1);
    });

    testWidgets('debe mostrar GossipCards cuando hay datos', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GossipCard), findsNWidgets(2));
    });

    testWidgets('GridView debe tener crossAxisCount 2', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('GridView debe tener childAspectRatio 0.72', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.childAspectRatio, 0.72);
    });

    testWidgets('GridView debe tener crossAxisSpacing correcto', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisSpacing, 12.0);
    });

    testWidgets('GridView debe tener mainAxisSpacing correcto', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.mainAxisSpacing, 12.0);
    });

    testWidgets('debe tener Padding con AppSpacing.md', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final padding = tester.widget<Padding>(
        find.ancestor(
          of: find.byType(GridView),
          matching: find.byType(Padding),
        ).first,
      );
      expect(padding.padding, const EdgeInsets.all(12.0));
    });

    testWidgets('GridView debe tener AlwaysScrollableScrollPhysics', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(gridView.physics, isA<AlwaysScrollableScrollPhysics>());
    });

    testWidgets('debe recargar datos al hacer pull-to-refresh', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar que se llamó una vez al cargar
      verify(mockGetGossips()).called(1);

      // Simular pull-to-refresh
      await tester.drag(find.byType(GridView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Debe llamar de nuevo
      verify(mockGetGossips()).called(1); // Una vez más
    });

    testWidgets('debe mostrar lista vacía cuando no hay gossips', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success([]),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GossipCard), findsNothing);
    });

    testWidgets('debe manejar error de carga', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.failure(
          const NetworkFailure(
            code: ErrorCode.networkError,
            technicalMessage: 'Network error',
          ),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // No debe mostrar cards si hay error
      expect(find.byType(GossipCard), findsNothing);
    });

    testWidgets('debe ser StatefulWidget', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      final widget = tester.widget(find.byType(HomeScreen));
      expect(widget, isA<StatefulWidget>());
    });

    testWidgets('itemCount debe coincidir con cantidad de gossips', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(gridView.semanticChildCount, mockGossips.length);
    });

    testWidgets('debe usar SliverGridDelegateWithFixedCrossAxisCount', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      expect(
        gridView.gridDelegate,
        isA<SliverGridDelegateWithFixedCrossAxisCount>(),
      );
    });

    testWidgets('debe construir GossipCard para cada gossip', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Debe haber un GossipCard por cada gossip
      expect(find.byType(GossipCard), findsNWidgets(mockGossips.length));
    });

    testWidgets('RefreshIndicator debe envolver GridView', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final refreshIndicator = find.ancestor(
        of: find.byType(GridView),
        matching: find.byType(RefreshIndicator),
      );
      expect(refreshIndicator, findsOneWidget);
    });

    testWidgets('debe tener estructura correcta: Scaffold > AppBar + Body', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verificar jerarquía
      expect(find.byType(Scaffold), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Scaffold),
          matching: find.byType(AppBar),
        ),
        findsOneWidget,
      );
    });

    testWidgets('debe usar GridView.builder en lugar de GridView', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      // GridView.builder usa itemBuilder
      expect(gridView.childrenDelegate, isA<SliverChildBuilderDelegate>());
    });

    testWidgets('debe llamar a GetGossips solo una vez en initState', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Solo debe llamarse una vez al iniciar
      verify(mockGetGossips()).called(1);
    });

    testWidgets('debe limpiar gossips al hacer refresh', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Debe haber gossips
      expect(find.byType(GossipCard), findsNWidgets(2));

      // Hacer refresh
      await tester.drag(find.byType(GridView), const Offset(0, 300));
      await tester.pump(); // Solo pump, no pumpAndSettle

      // Durante el refresh debe seguir habiendo datos (o mostrando loading)
      await tester.pumpAndSettle();

      // Después del refresh debe seguir habiendo gossips
      expect(find.byType(GossipCard), findsNWidgets(2));
    });

    testWidgets('debe manejar múltiples refresh consecutivos', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Primer refresh
      await tester.drag(find.byType(GridView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Segundo refresh
      await tester.drag(find.byType(GridView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Debe seguir funcionando
      expect(find.byType(GossipCard), findsNWidgets(2));
    });

    testWidgets('debe manejar error seguido de éxito en refresh', (tester) async {
      // Primera llamada (initState): error
      // Segunda llamada (refresh): éxito
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.failure(
          const NetworkFailure(
            code: ErrorCode.networkError,
            technicalMessage: 'Network error',
          ),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // No debe haber cards por el error
      expect(find.byType(GossipCard), findsNothing);

      // Cambiar respuesta a éxito
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      // Hacer refresh
      await tester.drag(find.byType(GridView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Ahora debe haber cards
      expect(find.byType(GossipCard), findsNWidgets(2));
    });

    testWidgets('debe manejar éxito seguido de error en refresh', (tester) async {
      // Primera llamada (initState): éxito
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Debe haber cards
      expect(find.byType(GossipCard), findsNWidgets(2));

      // Cambiar respuesta a error
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.failure(
          const NetworkFailure(
            code: ErrorCode.networkError,
            technicalMessage: 'Network error',
          ),
        ),
      );

      // Hacer refresh
      await tester.drag(find.byType(GridView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // No debe haber cards después del error
      expect(find.byType(GossipCard), findsNothing);
    });

    testWidgets('debe manejar diferentes tipos de Failure', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.failure(
          const ServerFailure(
            code: ErrorCode.serverError,
            technicalMessage: 'Server error',
          ),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GossipCard), findsNothing);
    });

    testWidgets('debe manejar lista con un solo gossip', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success([mockGossips.first]),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GossipCard), findsOneWidget);
    });

    testWidgets('debe manejar lista con muchos gossips', (tester) async {
      final manyGossips = List.generate(
        10,
        (index) => Gossip(
          id: 'test-$index',
          countryId: '1',
          regionId: 'ant',
          cityId: 'med',
          subject: 'Test Subject $index',
          content: 'Test Content $index',
          audioUrl: null,
          imageUrl: 'https://example.com/image$index.jpg',
          publishedAs: PublishAs.anonymous,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          reportedCount: 0,
          viewCount: 0,
          deletedAt: null,
          deletedBy: null,
          visibility: GossipVisibility.public,
          createdAt: DateTime.now(),
          createdBy: 'user-$index',
          modifiedAt: null,
          modifiedBy: null,
        ),
      );

      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(manyGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // El GridView solo renderiza los widgets visibles
      // Verificamos que al menos algunos estén renderizados
      expect(find.byType(GossipCard), findsWidgets);
    });

    testWidgets('debe poder hacer scroll en GridView', (tester) async {
      final manyGossips = List.generate(
        20,
        (index) => Gossip(
          id: 'test-$index',
          countryId: '1',
          regionId: 'ant',
          cityId: 'med',
          subject: 'Test Subject $index',
          content: 'Test Content $index',
          audioUrl: null,
          imageUrl: 'https://example.com/image$index.jpg',
          publishedAs: PublishAs.anonymous,
          status: GossipStatus.published,
          moderationStatus: ModerationStatus.approved,
          reportedCount: 0,
          viewCount: 0,
          deletedAt: null,
          deletedBy: null,
          visibility: GossipVisibility.public,
          createdAt: DateTime.now(),
          createdBy: 'user-$index',
          modifiedAt: null,
          modifiedBy: null,
        ),
      );

      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(manyGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Hacer scroll hacia abajo
      await tester.drag(find.byType(GridView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // No debe haber errores
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('RefreshIndicator onRefresh debe completar correctamente', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // El onRefresh debe ser async y completar
      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      expect(refreshIndicator.onRefresh, isNotNull);

      // Simular refresh completo
      await tester.fling(find.byType(GridView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      // No debe haber errores
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('debe mantener estado de gossips entre rebuilds', (tester) async {
      when(mockGetGossips()).thenAnswer(
        (_) async => Result.success(mockGossips),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(GossipCard), findsNWidgets(2));

      // Rebuild sin cambios
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      // Debe seguir mostrando los mismos gossips
      expect(find.byType(GossipCard), findsNWidgets(2));
    });
  });
}
