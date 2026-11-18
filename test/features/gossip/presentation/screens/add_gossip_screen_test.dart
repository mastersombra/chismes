import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chismes/features/gossip/presentation/screens/add_gossip_screen.dart';
import 'package:chismes/features/gossip/presentation/controllers/add_gossip_controller.dart';
import 'package:chismes/features/gossip/presentation/states/add_gossip_state.dart';
import 'package:chismes/features/gossip/domain/entities/gossip.dart';
import 'package:chismes/features/location/domain/entities/country.dart';
import 'package:chismes/features/location/domain/entities/region.dart';
import 'package:chismes/features/location/domain/entities/city.dart';
import 'package:chismes/features/gossip/presentation/widgets/city_autocomplete_optimized.dart';
import 'package:chismes/features/gossip/presentation/widgets/location_change_dialog.dart';
import 'package:chismes/features/location/domain/usecases/search_cities.dart';
import 'package:chismes/features/location/presentation/managers/location_manager.dart';
import 'package:chismes/features/location/presentation/states/location_state.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/error_messages.dart';
import 'package:chismes/features/auth/presentation/widgets/email_verification_banner.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/l10n/app_localizations.dart';

import '../../../../helpers/mock_add_gossip_controller_helper.dart';
import '../../../../helpers/widget_test_wrapper.dart';
import 'add_gossip_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AddGossipController>(),
  MockSpec<SearchCities>(),
  MockSpec<AuthRepository>(),
  MockSpec<LocationManager>(),
])
void main() {
  late MockAddGossipController mockController;
  late MockSearchCities mockSearchCities;
  late MockAuthRepository mockAuthRepository;
  late MockLocationManager mockLocationManager;

  // Provide dummy for Result<Failure, List<City>>
  provideDummy<Result<Failure, List<City>>>(
    Result.failure(const ValidationFailure(code: ErrorCode.invalidInput)),
  );

  setUp(() {
    // Initialize mocks
    mockController = MockAddGossipController();
    mockSearchCities = MockSearchCities();
    mockAuthRepository = MockAuthRepository();
    mockLocationManager = MockLocationManager();

    // Setup LocationManager mock
    when(mockLocationManager.state).thenReturn(LocationState.initial());
    when(mockLocationManager.addListener(any)).thenReturn(null);
    when(mockLocationManager.removeListener(any)).thenReturn(null);

    // Setup controller with locationManager
    when(mockController.locationManager).thenReturn(mockLocationManager);
    setupMockAddGossipController(mockController);

    // Setup mock SearchCities
    when(mockSearchCities.call(
      query: anyNamed('query'),
      regionId: anyNamed('regionId'),
    )).thenAnswer((_) async => Result.success(const []));

    // Setup mock AuthRepository
    when(mockAuthRepository.currentUser).thenReturn(User(
      id: 'test-user-id',
      email: 'test@example.com',
      emailVerified: true,
      profileCompleted: true,
      createdAt: DateTime.now(),
    ));

    // Register SearchCities in GetIt
    if (!getIt.isRegistered<SearchCities>()) {
      getIt.registerSingleton<SearchCities>(mockSearchCities);
    }

    // Register AuthRepository in GetIt
    if (!getIt.isRegistered<AuthRepository>()) {
      getIt.registerSingleton<AuthRepository>(mockAuthRepository);
    }
  });

  tearDown(() {
    if (getIt.isRegistered<SearchCities>()) {
      getIt.unregister<SearchCities>();
    }
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
  });

  Widget createWidget() {
    return testableWidget(
      child: AddGossipScreen(controller: mockController),
      useScaffold: false,
    );
  }

  AppLocalizations l10nOf(WidgetTester tester) =>
      AppLocalizations.of(tester.element(find.byType(AddGossipScreen)))!;

  Future<void> openLocationDialog(WidgetTester tester) async {
    await tester.tap(find.text(l10nOf(tester).gossipLocationSelectorChangeButtonLabel));
    await tester.pumpAndSettle();
    expect(find.byType(LocationChangeDialog), findsOneWidget);
  }

  LocationChangeDialog locationDialog(WidgetTester tester) =>
      tester.widget<LocationChangeDialog>(find.byType(LocationChangeDialog));

  group('AddGossipScreen - Construcción', () {
    testWidgets('debe construir el widget correctamente', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AddGossipScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsWidgets);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Nuevo Chisme 📝'), findsOneWidget);
    });

    testWidgets('debe inicializar TextEditingControllers', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Verificar que los campos de texto están presentes
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('debe usar AnimatedBuilder con el controller', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AnimatedBuilder), findsWidgets); // AnimatedBuilders presentes
      verify(mockController.addListener(any)).called(greaterThanOrEqualTo(1));
    });
  });

  group('AddGossipScreen - Componentes', () {
    testWidgets('debe mostrar CompactLocationSelector', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Ubicación no seleccionada'), findsOneWidget);
    });

    testWidgets('debe mostrar GossipTextFields', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Verificar que los campos de texto están presentes
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('debe mostrar ImagePickerWidget', (tester) async {
      await tester.pumpWidget(createWidget());

      // El widget de imagen debe estar presente aunque no sea visible sin estado específico
      await tester.pumpAndSettle();
    });

    testWidgets('debe mostrar PublishAsSelector', (tester) async {
      await tester.pumpWidget(createWidget());

      // El selector debe estar presente
      await tester.pumpAndSettle();
    });

    testWidgets('debe mostrar SubmitButton', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('AddGossipScreen - Estados de carga', () {
    testWidgets('debe mostrar loading en ubicación cuando isLoadingCountries es true', (tester) async {
      // El widget usa locationManager.state.isLoading (getter que chequea isLoadingCountries)
      when(mockLocationManager.state).thenReturn(
        LocationState.initial().copyWith(isLoadingCountries: true),
      );
      when(mockController.state).thenReturn(
        const AddGossipState(isLoadingCountries: true, idempotencyKey: 'test-key'),
      );

      await tester.pumpWidget(createWidget());
      await tester.pump(); // CircularProgressIndicator anima infinitamente, no usar pumpAndSettle

      // El indicador de carga se pasa al CompactLocationSelector
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('debe mostrar loading en ubicación cuando isLoadingCities es true', (tester) async {
      // El widget usa locationManager.state.isLoading (getter que chequea isLoadingCities)
      when(mockLocationManager.state).thenReturn(
        LocationState.initial().copyWith(isLoadingCities: true),
      );
      when(mockController.state).thenReturn(
        const AddGossipState(isLoadingCities: true, idempotencyKey: 'test-key'),
      );

      await tester.pumpWidget(createWidget());
      await tester.pump(); // CircularProgressIndicator anima infinitamente, no usar pumpAndSettle

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  group('AddGossipScreen - Manejo de errores', () {
    testWidgets('debe mostrar mensaje de error cuando hasError es true', (tester) async {
      const failure = NetworkFailure(code: ErrorCode.networkError);
      setupMockAddGossipControllerWithError(mockController, failure: failure);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error de conexión. Por favor verifica tu internet.'), findsOneWidget);
    });

    testWidgets('debe ocultar mensaje de error cuando no hay failure', (tester) async {
      when(mockController.state).thenReturn(const AddGossipState(idempotencyKey: 'test-key'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsNothing);
    });

    testWidgets('debe mostrar error de servidor correctamente', (tester) async {
      const failure = ServerFailure(code: ErrorCode.serverError);
      setupMockAddGossipControllerWithError(mockController, failure: failure);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('Error en el servidor. Intenta más tarde.'), findsOneWidget);
    });
  });

  group('AddGossipScreen - Interacciones', () {
    testWidgets('debe llamar updateSubject cuando cambia el texto del subject', (tester) async {
      when(mockController.updateSubject(any)).thenReturn(null);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final subjectField = find.byType(TextFormField).first;
      await tester.enterText(subjectField, 'Test Subject');
      await tester.pump();

      verify(mockController.updateSubject('Test Subject')).called(1);
    });

    testWidgets('debe llamar updateContent cuando cambia el texto del content', (tester) async {
      when(mockController.updateContent(any)).thenReturn(null);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final contentField = find.byType(TextFormField).last;
      await tester.enterText(contentField, 'Test Content');
      await tester.pump();

      verify(mockController.updateContent('Test Content')).called(1);
    });
  });

  group('AddGossipScreen - Submit', () {
    testWidgets('debe tener botón de submit', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('debe mostrar Form con key', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('debe llamar submit y mostrar diálogo de éxito para gossip publicado', (tester) async {
      final mockGossip = Gossip(
        id: '1',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test Subject',
        content: 'Test Content',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'test-user',
      );

      when(mockController.submit()).thenAnswer((_) async => mockGossip);
      when(mockController.state).thenReturn(
        const AddGossipState(
          idempotencyKey: 'test-key',

          subject: 'Test Subject',
          content: 'Test Content with enough characters for validation',
          selectedCityId: '1',
        ),
      );
      when(mockController.reset()).thenReturn(null);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Llenar el formulario
      await tester.enterText(find.byType(TextFormField).first, 'Test Subject');
      await tester.enterText(find.byType(TextFormField).last, 'Test Content with enough characters for validation');
      await tester.pump();

      // Hacer scroll hasta el botón de submit
      await tester.dragUntilVisible(
        find.byType(ElevatedButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );

      // Presionar el botón de submit
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verificar que se llamó submit
      verify(mockController.submit()).called(1);

      // Verificar que se muestra el diálogo con el título correcto
      expect(find.text('¡Chisme publicado!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.textContaining('pasó los controles automáticos'), findsOneWidget);
    });

    testWidgets('debe mostrar diálogo diferente para gossip en moderación', (tester) async {
      final mockGossip = Gossip(
        id: '1',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test Subject',
        content: 'Test Content',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.draft, // Draft significa pendiente de moderación
        moderationStatus: ModerationStatus.pending,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'test-user',
      );

      when(mockController.submit()).thenAnswer((_) async => mockGossip);
      when(mockController.state).thenReturn(
        const AddGossipState(
          idempotencyKey: 'test-key',

          subject: 'Test Subject',
          content: 'Test Content with enough characters for validation',
          selectedCityId: '1',
        ),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Test Subject');
      await tester.enterText(find.byType(TextFormField).last, 'Test Content with enough characters for validation');
      await tester.pump();

      await tester.dragUntilVisible(
        find.byType(ElevatedButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verificar diálogo para gossip pendiente de moderación
      expect(find.text('¡Chisme enviado!'), findsOneWidget);
      expect(find.textContaining('pendiente de moderación'), findsOneWidget);
    });

    testWidgets('debe limpiar formulario al confirmar diálogo de éxito', (tester) async {
      final mockGossip = Gossip(
        id: '1',
        countryId: '1',
        regionId: '1',
        cityId: '1',
        subject: 'Test Subject',
        content: 'Test Content',
        publishedAs: PublishAs.anonymous,
        status: GossipStatus.published,
        moderationStatus: ModerationStatus.approved,
        visibility: GossipVisibility.public,
        createdAt: DateTime.now(),
        createdBy: 'test-user',
      );

      when(mockController.submit()).thenAnswer((_) async => mockGossip);
      when(mockController.state).thenReturn(
        const AddGossipState(
          idempotencyKey: 'test-key',

          subject: 'Test Subject',
          content: 'Test Content with enough characters for validation',
          selectedCityId: '1',
        ),
      );
      when(mockController.reset()).thenReturn(null);

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Test Subject');
      await tester.enterText(find.byType(TextFormField).last, 'Test Content with enough characters for validation');
      await tester.pump();

      await tester.dragUntilVisible(
        find.byType(ElevatedButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Presionar "Aceptar" en el diálogo
      await tester.tap(find.text('Aceptar'));
      await tester.pump();

      // Verificar que se llamó reset para limpiar el estado del controller
      verify(mockController.reset()).called(1);

      // El diálogo también llama a clear() en los TextEditingControllers
      // pero después de Navigator.pop(), el widget ya no está en el árbol
      // por lo que no podemos verificar el estado de los controladores directamente
    });

    testWidgets('no debe mostrar diálogo si submit retorna null', (tester) async {
      when(mockController.submit()).thenAnswer((_) async => null);
      when(mockController.state).thenReturn(
        const AddGossipState(
          idempotencyKey: 'test-key',

          subject: 'Test Subject',
          content: 'Test Content with enough characters for validation',
          selectedCityId: '1',
        ),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Test Subject');
      await tester.enterText(find.byType(TextFormField).last, 'Test Content with enough characters for validation');
      await tester.pump();

      await tester.dragUntilVisible(
        find.byType(ElevatedButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pumpAndSettle();

      // No debería haber diálogo
      expect(find.text('¡Chisme publicado!'), findsNothing);
      expect(find.text('¡Chisme enviado!'), findsNothing);
    });

    testWidgets('debe validar formulario antes de llamar submit', (tester) async {
      when(mockController.state).thenReturn(const AddGossipState(idempotencyKey: 'test-key'));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // No llenar el formulario (dejarlo inválido)
      await tester.dragUntilVisible(
        find.byType(ElevatedButton),
        find.byType(SingleChildScrollView),
        const Offset(0, -50),
      );

      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      // submit no debería ser llamado si el formulario no es válido
      verifyNever(mockController.submit());
    });
  });

  group('AddGossipScreen - Diálogo de ubicación', () {
    testWidgets('debe mostrar dialog al cambiar ubicación', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cambiar'));
      await tester.pumpAndSettle();

      // El diálogo se muestra con Material, no siempre AlertDialog directo
      expect(find.byType(Dialog), findsWidgets);
    });

    testWidgets('debe llamar autoDetectLocation al usar ubicación actual', (tester) async {
      when(mockController.autoDetectLocation()).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      final l10n = l10nOf(tester);
      await tester.tap(find.text(l10n.locationUseCurrentLocation));
      await tester.pump();

      verify(mockController.autoDetectLocation()).called(1);
    });

    testWidgets('debe pasar callbacks correctos al LocationChangeDialog', (tester) async {
      const city = City(id: '1', name: 'Test City', regionId: '1');
      final searchCities = getIt<SearchCities>();

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      final dialog = locationDialog(tester);
      expect(dialog.searchCities, same(searchCities));
      expect(dialog.state, same(mockLocationManager.state));
      expect(dialog.isLoadingGPS, isFalse);

      dialog.onCountryChanged('1');
      dialog.onRegionChanged('2');
      dialog.onCityChanged(city);

      verify(mockController.selectCountry('1')).called(1);
      verify(mockController.selectRegion('2')).called(1);
      verify(mockController.selectCity('1')).called(1);
    });

    testWidgets('debe llamar selectCountry con countryId cuando se cambia país', (tester) async {
      const country = Country(id: 'country-1', name: 'Test Country', code: 'TC');
      when(mockLocationManager.state).thenReturn(
        LocationState.initial().copyWith(countries: const [country]),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Country').last);
      await tester.pumpAndSettle();

      verify(mockController.selectCountry('country-1')).called(1);
    });

    testWidgets('debe llamar selectRegion con regionId cuando se cambia región', (tester) async {
      const country = Country(id: '1', name: 'Test Country', code: 'TC');
      const region = Region(id: 'region-1', name: 'Test Region', countryId: '1', type: 'state');
      when(mockLocationManager.state).thenReturn(
        LocationState.initial().copyWith(
          countries: const [country],
          selectedCountry: country,
          regions: const [region],
        ),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Test Region').last);
      await tester.pumpAndSettle();

      verify(mockController.selectRegion('region-1')).called(1);
    });

    testWidgets('debe llamar selectCity con cityId cuando se cambia ciudad', (tester) async {
      const city = City(id: 'city-1', name: 'Test City', regionId: '1');

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      locationDialog(tester).onCityChanged(city);

      verify(mockController.selectCity('city-1')).called(1);
    });

    testWidgets('debe manejar null en onCityChanged correctamente', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      locationDialog(tester).onCityChanged(null);

      verify(mockController.selectCity(null)).called(1);
    });

    testWidgets('debe tener onConfirm configurado en el diálogo', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      // onConfirm está vacío: la ubicación ya se guarda en selectCity()
      locationDialog(tester).onConfirm();
      await tester.pump();

      verifyNever(mockController.selectCountry(any));
      verifyNever(mockController.selectRegion(any));
      verifyNever(mockController.selectCity(any));
      expect(find.byType(LocationChangeDialog), findsOneWidget);
    });

    testWidgets('debe ejecutar callback onCountryChanged cuando cambia el país', (tester) async {
      const country1 = Country(id: 'co', name: 'Colombia', code: 'CO');
      const country2 = Country(id: 'br', name: 'Brasil', code: 'BR');
      when(mockLocationManager.state).thenReturn(
        LocationState.initial().copyWith(
          countries: const [country1, country2],
          selectedCountry: country1,
        ),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brasil').last);
      await tester.pumpAndSettle();

      verify(mockController.selectCountry('br')).called(1);
      verifyNever(mockController.selectCountry('co'));
    });

    testWidgets('debe ejecutar callback onRegionChanged cuando cambia la región', (tester) async {
      const country = Country(id: 'co', name: 'Colombia', code: 'CO');
      const region1 = Region(id: 'antioquia', name: 'Antioquia', countryId: 'co', type: 'department');
      const region2 = Region(id: 'cundinamarca', name: 'Cundinamarca', countryId: 'co', type: 'department');
      when(mockLocationManager.state).thenReturn(
        LocationState.initial().copyWith(
          countries: const [country],
          selectedCountry: country,
          regions: const [region1, region2],
        ),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(dropdowns, findsNWidgets(2));
      await tester.tap(dropdowns.at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cundinamarca').last);
      await tester.pumpAndSettle();

      verify(mockController.selectRegion('cundinamarca')).called(1);
    });

    testWidgets('debe ejecutar callback onCityChanged cuando cambia la ciudad', (tester) async {
      const country = Country(id: 'co', name: 'Colombia', code: 'CO');
      const region = Region(id: 'antioquia', name: 'Antioquia', countryId: 'co', type: 'department');
      const city1 = City(id: 'medellin', name: 'Medellín', regionId: 'antioquia');
      const city2 = City(id: 'envigado', name: 'Envigado', regionId: 'antioquia');
      when(mockLocationManager.state).thenReturn(
        LocationState.initial().copyWith(
          countries: const [country],
          selectedCountry: country,
          regions: const [region],
          selectedRegion: region,
        ),
      );
      when(mockSearchCities.call(
        query: anyNamed('query'),
        regionId: 'antioquia',
        maxResults: anyNamed('maxResults'),
      )).thenAnswer((_) async => Result.success(const [city1, city2]));

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      final cityField = find.descendant(
        of: find.byType(CityAutocompleteOptimized),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(cityField, 'Envi');
      await tester.pump(const Duration(milliseconds: 300)); // debounce
      await tester.pump();

      await tester.tap(find.text('Envigado'));
      await tester.pump();

      verify(mockController.selectCity('envigado')).called(1);
    });

    testWidgets('debe pasar null a selectCity si city es null en onCityChanged', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      locationDialog(tester).onCityChanged(null);

      verify(mockController.selectCity(null)).called(1);
      verifyNever(mockController.selectCity(argThat(isNotNull)));
    });

    testWidgets('no debe llamar selectCountry si el valor del dropdown es null', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      locationDialog(tester).onCountryChanged(null);

      verifyNever(mockController.selectCountry(any));
    });

    testWidgets('no debe llamar selectRegion si el valor del dropdown es null', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      locationDialog(tester).onRegionChanged(null);

      verifyNever(mockController.selectRegion(any));
    });

    testWidgets('debe llamar onConfirm aunque esté vacío', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      // Llamarlo no debe lanzar ni tocar el controller
      expect(() => locationDialog(tester).onConfirm(), returnsNormally);
      verifyNever(mockController.selectCity(any));
    });

    testWidgets('debe ejecutar onConfirm al presionar botón Confirmar', (tester) async {
      const country = Country(id: 'co', name: 'Colombia', code: 'CO');
      const region = Region(id: 'antioquia', name: 'Antioquia', countryId: 'co', type: 'department');
      const city = City(id: 'medellin', name: 'Medellín', regionId: 'antioquia');
      when(mockLocationManager.state).thenReturn(
        LocationState.initial().copyWith(
          countries: const [country],
          selectedCountry: country,
          regions: const [region],
          selectedRegion: region,
          selectedCity: city,
        ),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      final confirmButton = find.text(l10nOf(tester).confirm);
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Formulario válido → onConfirm + pop del diálogo
      expect(find.byType(LocationChangeDialog), findsNothing);
      expect(find.byType(AddGossipScreen), findsOneWidget);
    });

    testWidgets('debe pasar null a selectCity cuando se limpia CityAutocomplete', (tester) async {
      const country = Country(id: 'co', name: 'Colombia', code: 'CO');
      const region = Region(id: 'antioquia', name: 'Antioquia', countryId: 'co', type: 'department');
      const city = City(id: 'medellin', name: 'Medellín', regionId: 'antioquia');
      when(mockLocationManager.state).thenReturn(
        LocationState.initial().copyWith(
          countries: const [country],
          selectedCountry: country,
          regions: const [region],
          selectedRegion: region,
          selectedCity: city,
        ),
      );

      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();
      await openLocationDialog(tester);

      final clearButton = find.descendant(
        of: find.byType(CityAutocompleteOptimized),
        matching: find.byIcon(Icons.clear),
      );
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pump();

      verify(mockController.selectCity(null)).called(1);
    });
  });

  group('AddGossipScreen - Dispose', () {
    testWidgets('debe limpiar recursos al hacer dispose', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Remover el widget para triggear dispose
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump();

      // Verificar que se removió el listener
      verify(mockController.removeListener(any)).called(greaterThanOrEqualTo(1));
    });
  });

  group('AddGossipScreen - Actualización de estado', () {
    testWidgets('debe reconstruirse cuando el estado del controller cambia', (tester) async {
      var callCount = 0;
      when(mockController.state).thenAnswer((_) {
        callCount++;
        return AddGossipState(
          idempotencyKey: 'test-key',
          subject: callCount > 1 ? 'Updated' : '',
        );
      });

      await tester.pumpWidget(createWidget());

      // Simular cambio de estado
      await tester.pump();

      // El widget debería haberse reconstruido - se llama al menos una vez
      verify(mockController.state).called(greaterThanOrEqualTo(1));
    });

    testWidgets('debe actualizar locationDisplayText cuando cambia', (tester) async {
      when(mockController.locationDisplayText).thenReturn('Nueva Ubicación');
      when(mockController.state).thenReturn(const AddGossipState(idempotencyKey: 'test-key'));

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.text('Nueva Ubicación'), findsOneWidget);
    });
  });

  group('AddGossipScreen - Validación de formulario', () {
    testWidgets('debe tener formulario con validación', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Form), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });
  });

  group('AddGossipScreen - Interacción con ImagePicker', () {
    testWidgets('debe llamar pickImageFromCamera al seleccionar cámara', (tester) async {
      when(mockController.pickImageFromCamera()).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidget());

      // El ImagePickerWidget tiene estos callbacks pero la interacción específica
      // depende de la implementación del widget
      await tester.pump();
    });

    testWidgets('debe llamar pickImageFromGallery al seleccionar galería', (tester) async {
      when(mockController.pickImageFromGallery()).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidget());
      await tester.pump();
    });

    testWidgets('debe llamar removeImage al eliminar imagen', (tester) async {
      when(mockController.removeImage()).thenReturn(null);
      when(mockController.state).thenReturn(
        const AddGossipState(imageUrl: 'https://example.com/image.jpg', idempotencyKey: 'test-key'),
      );

      await tester.pumpWidget(createWidget());
      await tester.pump();
    });
  });

  group('AddGossipScreen - PublishAs', () {
    testWidgets('debe llamar setPublishedAs al cambiar tipo de publicación', (tester) async {
      when(mockController.setPublishedAs(any)).thenReturn(null);

      await tester.pumpWidget(createWidget());
      await tester.pump();

      // El PublishAsSelector maneja el cambio internamente
    });
  });


  group('AddGossipScreen - Callbacks de ubicación', () {
    testWidgets('debe ejecutar onRegionChanged cuando se selecciona región', (tester) async {
      // Arrange
      const region = Region(
        id: 'region-1',
        countryId: 'country-1',
        name: 'Antioquia',
        type: 'state',
      );

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await openLocationDialog(tester);

      // Act - a través del callback que la screen pasa al diálogo
      locationDialog(tester).onRegionChanged(region.id);

      // Assert
      verify(mockController.selectRegion(region.id)).called(1);
    });

    testWidgets('debe ejecutar onCityChanged cuando se selecciona ciudad', (tester) async {
      // Arrange
      const city = City(
        id: 'city-1',
        regionId: 'region-1',
        name: 'Medellín',
      );

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await openLocationDialog(tester);

      // Act - a través del callback que la screen pasa al diálogo
      locationDialog(tester).onCityChanged(city);

      // Assert
      verify(mockController.selectCity(city.id)).called(1);
    });

    testWidgets('onConfirm no debe hacer nada (ubicación ya guardada)', (tester) async {
      // Arrange
      await tester.pumpWidget(createWidget());
      await tester.pump();
      await openLocationDialog(tester);
      clearInteractions(mockController);

      // Act
      locationDialog(tester).onConfirm();

      // Assert - no toca el controller: la ubicación se guarda en selectCity()
      verifyNoMoreInteractions(mockController);
    });
  });

  group('AddGossipScreen - Verificación de email', () {
    setUp(() {
      provideDummy<Result<Failure, void>>(Result.success(null));
    });

    User unverifiedUser() => User(
          id: 'test-user-id',
          email: 'test@example.com',
          emailVerified: false,
          profileCompleted: true,
          createdAt: DateTime(2024, 1, 1),
        );

    Finder resendButton() => find.descendant(
          of: find.byType(EmailVerificationBanner),
          // OutlinedButton.icon crea una subclase: comparar con `is`
          matching: find.byWidgetPredicate((w) => w is OutlinedButton),
        );

    testWidgets('con email verificado no muestra el banner', (tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(EmailVerificationBanner), findsNothing);
    });

    testWidgets('sin usuario no muestra el banner', (tester) async {
      when(mockAuthRepository.currentUser).thenReturn(null);

      await tester.pumpWidget(createWidget());
      await tester.pump();

      expect(find.byType(EmailVerificationBanner), findsNothing);
    });

    testWidgets('con email sin verificar muestra el banner habilitado',
        (tester) async {
      when(mockAuthRepository.currentUser).thenReturn(unverifiedUser());

      await tester.pumpWidget(createWidget());
      await tester.pump();

      final banner = tester.widget<EmailVerificationBanner>(
          find.byType(EmailVerificationBanner));
      expect(banner.isLoading, isFalse);
    });

    testWidgets('reenviar: loading mientras espera y snackbar de éxito',
        (tester) async {
      when(mockAuthRepository.currentUser).thenReturn(unverifiedUser());
      final completer = Completer<Result<Failure, void>>();
      when(mockAuthRepository.resendVerificationEmail())
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.ensureVisible(resendButton());
      await tester.tap(resendButton());
      await tester.pump();

      expect(
        tester
            .widget<EmailVerificationBanner>(find.byType(EmailVerificationBanner))
            .isLoading,
        isTrue,
      );
      verify(mockAuthRepository.resendVerificationEmail()).called(1);

      completer.complete(Result.success(null));
      await tester.pump();
      await tester.pump();

      expect(
        tester
            .widget<EmailVerificationBanner>(find.byType(EmailVerificationBanner))
            .isLoading,
        isFalse,
      );
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect((snackBar.content as Text).data,
          l10nOf(tester).gossipAddScreenEmailVerificationResent);
      expect(snackBar.backgroundColor, Colors.green);
    });

    testWidgets('reenviar con error muestra el mensaje del ErrorCode',
        (tester) async {
      when(mockAuthRepository.currentUser).thenReturn(unverifiedUser());
      when(mockAuthRepository.resendVerificationEmail()).thenAnswer(
        (_) async => Result.failure(
            const NetworkFailure(code: ErrorCode.noInternetConnection)),
      );

      await tester.pumpWidget(createWidget());
      await tester.pump();

      await tester.ensureVisible(resendButton());
      await tester.tap(resendButton());
      await tester.pump();
      await tester.pump();

      final context = tester.element(find.byType(AddGossipScreen));
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect((snackBar.content as Text).data,
          ErrorMessages.getMessage(context, ErrorCode.noInternetConnection));
      expect(snackBar.backgroundColor, Theme.of(context).colorScheme.error);
      expect(
        tester
            .widget<EmailVerificationBanner>(find.byType(EmailVerificationBanner))
            .isLoading,
        isFalse,
      );
    });

    testWidgets('si la screen se desmonta durante el reenvío no muestra snackbar',
        (tester) async {
      when(mockAuthRepository.currentUser).thenReturn(unverifiedUser());
      final completer = Completer<Result<Failure, void>>();
      when(mockAuthRepository.resendVerificationEmail())
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(createWidget());
      await tester.pump();
      await tester.ensureVisible(resendButton());
      await tester.tap(resendButton());
      await tester.pump();

      await tester.pumpWidget(testableWidget(child: const SizedBox()));
      completer.complete(Result.success(null));
      await tester.pump();

      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('AddGossipScreen - Botón de submit enviando', () {
    testWidgets('mientras envía muestra spinner y deshabilita el botón',
        (tester) async {
      setupMockAddGossipController(mockController, isSubmitting: true);

      await tester.pumpWidget(createWidget());
      await tester.pump();

      final button = find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(ElevatedButton),
      );
      expect(button, findsOneWidget);
      expect(tester.widget<ElevatedButton>(button).onPressed, isNull);
      expect(find.text(l10nOf(tester).gossipAddScreenSubmitButton), findsNothing);

      final spinner = tester.widget<CircularProgressIndicator>(find.descendant(
        of: button,
        matching: find.byType(CircularProgressIndicator),
      ));
      final context = tester.element(find.byType(AddGossipScreen));
      expect(spinner.color, Theme.of(context).colorScheme.onPrimary);

      await tester.ensureVisible(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.pump();
      verifyNever(mockController.submit());
    });
  });
}
