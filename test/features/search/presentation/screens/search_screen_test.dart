import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/error_messages.dart';
import 'package:chismes/l10n/app_localizations.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/features/search/presentation/screens/search_screen.dart';
import 'package:chismes/features/gossip/domain/usecases/get_gossips.dart';
import 'package:chismes/features/gossip/domain/usecases/search_gossips.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/presentation/widgets/gossip_card.dart';
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
      final flutterGossip = Gossip(
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
      );

      // Mock SearchGossips para devolver solo el resultado filtrado
      when(mockSearchGossips(query: 'Flutter', cityId: null, limit: 20))
          .thenAnswer((_) async => Result.success([flutterGossip]));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - buscar por subject
      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pumpAndSettle();

      // Assert - debe llamar a SearchGossips (búsqueda en servidor)
      verify(mockSearchGossips(query: 'Flutter', cityId: null, limit: 20)).called(1);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('1 resultado'), findsOneWidget);
    });

    testWidgets('debe filtrar gossips por content', (tester) async {
      // Arrange
      final contentGossip = Gossip(
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
      );

      // Mock SearchGossips para devolver solo el resultado filtrado
      when(mockSearchGossips(query: 'Flutter', cityId: null, limit: 20))
          .thenAnswer((_) async => Result.success([contentGossip]));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - buscar por content
      await tester.enterText(find.byType(TextField), 'Flutter');
      await tester.pumpAndSettle();

      // Assert - debe llamar a SearchGossips (búsqueda en servidor)
      verify(mockSearchGossips(query: 'Flutter', cityId: null, limit: 20)).called(1);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('1 resultado'), findsOneWidget);
    });

    testWidgets('debe buscar case-insensitive', (tester) async {
      // Arrange
      final gossip = Gossip(
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
      );

      // Mock SearchGossips - la búsqueda case-insensitive se hace en el servidor
      when(mockSearchGossips(query: 'flutter', cityId: null, limit: 20))
          .thenAnswer((_) async => Result.success([gossip]));

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
      verify(mockSearchGossips(query: 'flutter', cityId: null, limit: 20)).called(1);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('debe usar GridView con 2 columnas', (tester) async {
      // Arrange
      final gossip = Gossip(
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
      );

      // Mock SearchGossips para devolver resultado
      when(mockSearchGossips(query: 'Test', cityId: null, limit: 20))
          .thenAnswer((_) async => Result.success([gossip]));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Assert - debe llamar a SearchGossips
      verify(mockSearchGossips(query: 'Test', cityId: null, limit: 20)).called(1);
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

      // Mock SearchGossips para devolver error
      when(mockSearchGossips(query: 'Test', cityId: null, limit: 20))
          .thenAnswer((_) async => Result.failure(failure));

      await tester.pumpWidget(
        testableWidget(
          child: const SearchScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act - escribir en el TextField para iniciar búsqueda
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Assert - debe llamar a SearchGossips
      verify(mockSearchGossips(query: 'Test', cityId: null, limit: 20)).called(1);
      // Verifica que se llamó al searchGossips y se manejó el error
      expect(find.byType(GridView), findsNothing);
      // Verifica que se muestra el mensaje de error
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('debe resetear búsqueda al limpiar el TextField', (tester) async {
      // Arrange
      final gossip = Gossip(
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
      );

      // Mock GetGossips para mostrar recientes
      final recentGossips = [gossip];
      when(mockGetGossips()).thenAnswer((_) async => Result.success(recentGossips));

      // Mock SearchGossips para búsqueda
      when(mockSearchGossips(query: 'Test', cityId: null, limit: 20))
          .thenAnswer((_) async => Result.success([gossip]));

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
      // Completer para controlar cuándo responde la búsqueda (sin tiempo real)
      final completer = Completer<Result<Failure, List<Gossip>>>();
      when(mockSearchGossips(query: 'Test', cityId: null, limit: 20))
          .thenAnswer((_) => completer.future);

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
      final textField = find.byType(TextField);
      expect(
        find.descendant(of: textField, matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );
      expect(find.descendant(of: textField, matching: find.byIcon(Icons.clear)), findsNothing);

      // Al responder desaparece el loading y queda el botón de limpiar
      completer.complete(Result.success([]));
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.descendant(of: textField, matching: find.byIcon(Icons.clear)), findsOneWidget);
    });
  });

  group('SearchScreen - Carga de recientes con error', () {
    testWidgets('muestra el mensaje del ErrorCode si GetGossips falla',
        (tester) async {
      when(mockGetGossips()).thenAnswer((_) async => Result.failure(
          const NetworkFailure(code: ErrorCode.noInternetConnection)));

      await tester.pumpWidget(testableWidget(child: const SearchScreen()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SearchScreen));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        find.text(ErrorMessages.getMessage(context, ErrorCode.noInternetConnection)),
        findsOneWidget,
      );
      // Ya no está cargando: muestra el estado vacío inicial
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(l10nOf(tester).searchByTopic), findsOneWidget);
    });
  });

  group('SearchScreen - Historial de búsquedas', () {
    final history = ['flutter', 'dart', 'supabase', 'riverpod', 'getit', 'sexto'];

    setUp(() {
      when(mockSearchHistoryService.getHistory()).thenAnswer((_) async => history);
      when(mockSearchHistoryService.addSearch(any)).thenAnswer((_) async {});
      when(mockSearchHistoryService.removeSearch(any)).thenAnswer((_) async {});
      when(mockSearchHistoryService.clearHistory()).thenAnswer((_) async {});
    });

    Future<void> pumpAndFocus(WidgetTester tester) async {
      await tester.pumpWidget(testableWidget(child: const SearchScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
    }

    Finder historyItem(String query) => find.ancestor(
          of: find.text(query),
          matching: find.byType(InkWell),
        );

    testWidgets('sin foco no muestra el historial', (tester) async {
      await tester.pumpWidget(testableWidget(child: const SearchScreen()));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).searchRecentSearches), findsNothing);
    });

    testWidgets('al enfocar el campo vacío muestra máximo 5 búsquedas',
        (tester) async {
      await pumpAndFocus(tester);

      expect(find.text(l10nOf(tester).searchRecentSearches), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      for (final q in history.take(5)) {
        expect(find.text(q), findsOneWidget);
      }
      expect(find.text('sexto'), findsNothing);
    });

    testWidgets('historial vacío no muestra el panel aunque haya foco',
        (tester) async {
      when(mockSearchHistoryService.getHistory()).thenAnswer((_) async => []);

      await pumpAndFocus(tester);

      expect(find.text(l10nOf(tester).searchRecentSearches), findsNothing);
    });

    testWidgets('tocar un item busca ese texto y oculta el historial',
        (tester) async {
      await pumpAndFocus(tester);

      await tester.tap(historyItem('dart'));
      await tester.pumpAndSettle();

      verify(mockSearchGossips(query: 'dart', cityId: null, limit: 20)).called(1);
      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'dart');
      expect(find.text(l10nOf(tester).searchRecentSearches), findsNothing);
      expect(find.text(l10nOf(tester).searchNoResults), findsOneWidget);
      verify(mockSearchHistoryService.addSearch('dart')).called(1);
    });

    testWidgets('la X de un item lo elimina y recarga el historial',
        (tester) async {
      await pumpAndFocus(tester);
      clearInteractions(mockSearchHistoryService);
      when(mockSearchHistoryService.getHistory())
          .thenAnswer((_) async => ['flutter', 'supabase']);

      await tester.tap(find.descendant(
        of: historyItem('dart'),
        matching: find.byIcon(Icons.close),
      ));
      await tester.pumpAndSettle();

      verify(mockSearchHistoryService.removeSearch('dart')).called(1);
      verify(mockSearchHistoryService.getHistory()).called(1);
      expect(find.text('dart'), findsNothing);
      expect(find.text('flutter'), findsOneWidget);
      verifyNever(mockSearchGossips(
          query: anyNamed('query'), cityId: anyNamed('cityId'), limit: anyNamed('limit')));
    });

    testWidgets('"Borrar todo" limpia el historial y oculta el panel',
        (tester) async {
      await pumpAndFocus(tester);
      when(mockSearchHistoryService.getHistory()).thenAnswer((_) async => []);

      await tester.tap(find.text(l10nOf(tester).searchClearAll));
      await tester.pumpAndSettle();

      verify(mockSearchHistoryService.clearHistory()).called(1);
      expect(find.text(l10nOf(tester).searchRecentSearches), findsNothing);
      expect(find.text('flutter'), findsNothing);
    });
  });

  group('SearchScreen - Botón limpiar del campo', () {
    testWidgets('limpia el texto y vuelve al estado inicial', (tester) async {
      when(mockSearchGossips(query: 'Test', cityId: null, limit: 20))
          .thenAnswer((_) async => Result.success([]));

      await tester.pumpWidget(testableWidget(child: const SearchScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();
      expect(find.text(l10nOf(tester).searchNoResults), findsOneWidget);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
      expect(find.byIcon(Icons.clear), findsNothing);
      expect(find.text(l10nOf(tester).searchNoResults), findsNothing);
      expect(find.text(l10nOf(tester).searchByTopic), findsOneWidget);
    });
  });

  group('SearchScreen - Filtro por ciudad', () {
    final location = SavedLocation(
      countryId: 'co',
      regionId: 'ant',
      cityId: 'med',
      countryName: 'Colombia',
      regionName: 'Antioquia',
      cityName: 'Medellín',
    );

    setUp(() {
      when(mockLocationService.getDefaultLocation()).thenAnswer((_) async => location);
      when(mockSearchHistoryService.addSearch(any)).thenAnswer((_) async {});
    });

    Finder chip() => find.byType(FilterChip);

    testWidgets('sin ubicación guardada no muestra el filtro', (tester) async {
      when(mockLocationService.getDefaultLocation()).thenAnswer((_) async => null);

      await tester.pumpWidget(testableWidget(child: const SearchScreen()));
      await tester.pumpAndSettle();

      expect(chip(), findsNothing);
    });

    testWidgets('con ubicación muestra el chip con el nombre de la ciudad',
        (tester) async {
      await tester.pumpWidget(testableWidget(child: const SearchScreen()));
      await tester.pumpAndSettle();

      expect(chip(), findsOneWidget);
      expect(find.text(l10nOf(tester).searchFilterOnlyCity('Medellín')), findsOneWidget);
      expect(tester.widget<FilterChip>(chip()).selected, isFalse);
    });

    testWidgets('activar el filtro sin query no busca', (tester) async {
      await tester.pumpWidget(testableWidget(child: const SearchScreen()));
      await tester.pumpAndSettle();

      await tester.tap(chip());
      await tester.pumpAndSettle();

      expect(tester.widget<FilterChip>(chip()).selected, isTrue);
      verifyNever(mockSearchGossips(
          query: anyNamed('query'), cityId: anyNamed('cityId'), limit: anyNamed('limit')));
    });

    testWidgets('activar/desactivar con query activo repite la búsqueda con/sin cityId',
        (tester) async {
      await tester.pumpWidget(testableWidget(child: const SearchScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'chisme');
      await tester.pumpAndSettle();
      verify(mockSearchGossips(query: 'chisme', cityId: null, limit: 20)).called(1);

      await tester.tap(chip());
      await tester.pumpAndSettle();
      verify(mockSearchGossips(query: 'chisme', cityId: 'med', limit: 20)).called(1);
      expect(tester.widget<FilterChip>(chip()).selected, isTrue);

      await tester.tap(chip());
      await tester.pumpAndSettle();
      verify(mockSearchGossips(query: 'chisme', cityId: null, limit: 20)).called(1);
      expect(tester.widget<FilterChip>(chip()).selected, isFalse);
    });

    testWidgets('el chip se oculta mientras se muestra el historial',
        (tester) async {
      when(mockSearchHistoryService.getHistory()).thenAnswer((_) async => ['algo']);
      await tester.pumpWidget(testableWidget(child: const SearchScreen()));
      await tester.pumpAndSettle();
      expect(chip(), findsOneWidget);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).searchRecentSearches), findsOneWidget);
      expect(chip(), findsNothing);
    });
  });
  group('SearchScreen - Layout en pantallas chicas con teclado', () {
    final recent = Gossip(
      id: 'r1',
      countryId: 'co',
      regionId: 'ant',
      cityId: 'med',
      subject: 'Reciente',
      content: 'Contenido',
      publishedAs: PublishAs.anonymous,
      status: GossipStatus.published,
      moderationStatus: ModerationStatus.approved,
      visibility: GossipVisibility.public,
      createdAt: DateTime(2024, 1, 1),
      createdBy: 'user1',
    );

    /// iPhone SE (375×667) con teclado de 300px abierto.
    void useSmallPhoneWithKeyboard(WidgetTester tester) {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
    }

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        testableWidget(child: const SearchScreen(), useScaffold: false),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      when(mockSearchHistoryService.addSearch(any)).thenAnswer((_) async {});
    });

    testWidgets('con foco el historial reemplaza a los recientes', (tester) async {
      when(mockGetGossips()).thenAnswer((_) async => Result.success([recent]));
      when(mockSearchHistoryService.getHistory()).thenAnswer((_) async => ['uno']);

      await pumpScreen(tester);
      expect(find.text(l10nOf(tester).searchRecent), findsOneWidget);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).searchRecentSearches), findsOneWidget);
      expect(find.text(l10nOf(tester).searchRecent), findsNothing);
      expect(find.byType(GossipCard), findsNothing);
    });

    // Sin recientes: GossipCard desborda en la grilla a 375 de ancho
    // (bug aparte, gossip_card.dart:154 vs childAspectRatio 0.72).
    testWidgets('historial de 5 items con teclado no desborda y es scrollable',
        (tester) async {
      useSmallPhoneWithKeyboard(tester);
      when(mockSearchHistoryService.getHistory())
          .thenAnswer((_) async => ['uno', 'dos', 'tres', 'cuatro', 'cinco']);

      await pumpScreen(tester);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).searchRecentSearches), findsOneWidget);
      expect(find.text(l10nOf(tester).searchByTopic), findsNothing);

      // El último item es alcanzable con scroll
      await tester.scrollUntilVisible(find.text('cinco'), 50,
          scrollable: find.byType(Scrollable).last);
      expect(find.text('cinco').hitTestable(), findsOneWidget);
    });

    testWidgets('estado vacío inicial con teclado no desborda', (tester) async {
      useSmallPhoneWithKeyboard(tester);

      await pumpScreen(tester);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).searchByTopic), findsOneWidget);
    });

    testWidgets('sin resultados con teclado no desborda', (tester) async {
      useSmallPhoneWithKeyboard(tester);

      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'nada');
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).searchNoResults), findsOneWidget);
    });

    testWidgets('tocar fuera del campo cierra el historial y vuelven los recientes',
        (tester) async {
      when(mockGetGossips()).thenAnswer((_) async => Result.success([recent]));
      when(mockSearchHistoryService.getHistory()).thenAnswer((_) async => ['uno']);

      await pumpScreen(tester);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text(l10nOf(tester).searchRecentSearches), findsOneWidget);

      await tester.tap(find.byType(AppBar));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).searchRecentSearches), findsNothing);
      expect(find.text(l10nOf(tester).searchRecent), findsOneWidget);
      expect(find.byType(GossipCard), findsOneWidget);
    });

    testWidgets('limpiar con la X sin foco vuelve a los recientes, no al historial',
        (tester) async {
      when(mockGetGossips()).thenAnswer((_) async => Result.success([recent]));
      when(mockSearchHistoryService.getHistory()).thenAnswer((_) async => ['uno']);

      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppBar)); // quitar foco
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).searchRecentSearches), findsNothing);
      expect(find.text(l10nOf(tester).searchRecent), findsOneWidget);
    });

    testWidgets('limpiar con la X con foco muestra el historial', (tester) async {
      when(mockSearchHistoryService.getHistory()).thenAnswer((_) async => ['uno']);

      await pumpScreen(tester);
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text(l10nOf(tester).searchRecentSearches), findsOneWidget);
    });
  });
}

AppLocalizations l10nOf(WidgetTester tester) =>
    AppLocalizations.of(tester.element(find.byType(SearchScreen)))!;
