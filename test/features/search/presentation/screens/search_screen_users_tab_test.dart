import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/navigation/social_navigator.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/core/services/gossip_events.dart';
import 'package:chismes/core/services/location_service.dart';
import 'package:chismes/core/services/search_history_service.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/gossip/domain/usecases/get_gossips.dart';
import 'package:chismes/features/gossip/domain/usecases/search_gossips.dart';
import 'package:chismes/features/search/presentation/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/test_di_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import '../../../social/social_test_mocks.mocks.dart';
import 'search_screen_test.mocks.dart';

void main() {
  late MockSearchGossips searchGossips;
  late MockSearchHistoryService history;
  late MockLocationService location;
  late MockSocialNavigator navigator;

  void register<T extends Object>(T instance) {
    if (getIt.isRegistered<T>()) getIt.unregister<T>();
    getIt.registerSingleton<T>(instance);
  }

  void unregister<T extends Object>() {
    if (getIt.isRegistered<T>()) getIt.unregister<T>();
  }

  setUp(() async {
    await setupTestDI();
    provideDummy<Result<Failure, List<Gossip>>>(Result.success([]));
    final getGossips = MockGetGossips();
    searchGossips = MockSearchGossips();
    history = MockSearchHistoryService();
    location = MockLocationService();
    navigator = MockSocialNavigator();

    when(getGossips()).thenAnswer((_) async => Result.success([]));
    when(searchGossips(
            query: anyNamed('query'), cityId: anyNamed('cityId'), limit: anyNamed('limit')))
        .thenAnswer((_) async => Result.success([]));
    when(history.getHistory()).thenAnswer((_) async => []);
    when(history.addSearch(any)).thenAnswer((_) async {});
    when(location.getDefaultLocation()).thenAnswer((_) async => SavedLocation(
          countryId: 'CO',
          countryName: 'Colombia',
          regionId: 'ant',
          regionName: 'Antioquia',
          cityId: 'MED',
          cityName: 'Medellín',
        ));
    when(navigator.buildUserSearchResults(any)).thenAnswer(
      (inv) => Text('usuarios:${inv.positionalArguments.first}', key: const Key('usersResults')),
    );

    register<GetGossips>(getGossips);
    register<SearchGossips>(searchGossips);
    register<SearchHistoryService>(history);
    register<LocationService>(location);
    register<GossipEvents>(GossipEvents());
    register<SocialNavigator>(navigator);
  });

  tearDown(() async {
    unregister<GetGossips>();
    unregister<SearchGossips>();
    unregister<SearchHistoryService>();
    unregister<LocationService>();
    unregister<GossipEvents>();
    unregister<SocialNavigator>();
    await tearDownTestDI();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(testableWidget(useScaffold: false, child: const SearchScreen()));
    await tester.pumpAndSettle();
  }

  testWidgets('arranca en Chismes; Usuarios muestra los resultados de usuarios', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(const Key('searchModeSelector')), findsOneWidget);
    expect(find.text('Buscar chismes...'), findsOneWidget);
    expect(find.text('Solo Medellín'), findsOneWidget);

    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();

    expect(find.text('Buscar por @usuario o nombre...'), findsOneWidget);
    expect(find.byKey(const Key('usersResults')), findsOneWidget);
    // El filtro por ciudad es solo de chismes
    expect(find.text('Solo Medellín'), findsNothing);
  });

  testWidgets('en Usuarios escribir no busca chismes ni guarda historial', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '@ana');
    await tester.pumpAndSettle();

    expect(find.text('usuarios:@ana'), findsOneWidget);
    verify(navigator.buildUserSearchResults('@ana')).called(greaterThan(0));
    verifyNever(searchGossips(
        query: anyNamed('query'), cityId: anyNamed('cityId'), limit: anyNamed('limit')));
    verifyNever(history.addSearch(any));
  });

  testWidgets('volver a Chismes busca el texto actual como chisme', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fiesta');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chismes'));
    await tester.pumpAndSettle();

    verify(searchGossips(query: 'fiesta', cityId: null, limit: anyNamed('limit'))).called(1);
    expect(find.byKey(const Key('usersResults')), findsNothing);
  });

  testWidgets('la X limpia el texto también en Usuarios', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Usuarios'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'ana');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.text('usuarios:'), findsOneWidget);
  });
}
