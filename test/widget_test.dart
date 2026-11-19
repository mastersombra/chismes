// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:chismes/main.dart';
import 'package:chismes/features/auth/presentation/screens/login_screen.dart';
import 'package:chismes/features/auth/presentation/controllers/login_controller.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/core/services/search_history_service.dart';
import 'package:chismes/core/services/location_service.dart';

import 'helpers/mock_app_logger_helper.dart';
import 'helpers/test_di_helper.dart';
import 'helpers/widget_test_wrapper.dart';

@GenerateMocks([LoginController, AuthRepository, SearchHistoryService, LocationService])
import 'widget_test.mocks.dart';

void main() {
  late MockLoginController mockLoginController;
  late MockAuthRepository mockAuthRepository;
  late MockSearchHistoryService mockSearchHistoryService;
  late MockLocationService mockLocationService;

  setUpAll(() {
    // Provide dummy values for complex types
    provideDummy<AuthState>(const AuthInitial());
  });

  setUp(() async {
    // Inicializar DI para tests (LocaleNotifier, SharedPreferences, etc.)
    await setupTestDI();

    // Registrar mocks necesarios
    setupMockAppLogger();

    // Configurar mock de AuthRepository
    mockAuthRepository = MockAuthRepository();
    when(mockAuthRepository.authStateChanges).thenAnswer((_) => Stream.value(null));
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    getIt.registerSingleton<AuthRepository>(mockAuthRepository);

    // Configurar mock de LoginController
    mockLoginController = MockLoginController();
    when(mockLoginController.state).thenReturn(const AuthInitial());
    when(mockLoginController.addListener(any)).thenReturn(null);
    when(mockLoginController.removeListener(any)).thenReturn(null);

    // Registrar mock en GetIt
    if (getIt.isRegistered<LoginController>()) {
      getIt.unregister<LoginController>();
    }
    getIt.registerSingleton<LoginController>(mockLoginController);

    // Configurar mocks de servicios (necesarios para SearchScreen dentro de MainNavigationScreen)
    mockSearchHistoryService = MockSearchHistoryService();
    mockLocationService = MockLocationService();

    when(mockSearchHistoryService.getHistory()).thenAnswer((_) async => []);
    when(mockLocationService.getDefaultLocation()).thenAnswer((_) async => null);

    if (getIt.isRegistered<SearchHistoryService>()) {
      getIt.unregister<SearchHistoryService>();
    }
    if (getIt.isRegistered<LocationService>()) {
      getIt.unregister<LocationService>();
    }
    getIt.registerSingleton<SearchHistoryService>(mockSearchHistoryService);
    getIt.registerSingleton<LocationService>(mockLocationService);
  });

  tearDown(() async {
    // Limpiar mocks
    if (getIt.isRegistered<LoginController>()) {
      getIt.unregister<LoginController>();
    }
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
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

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      testableWidget(child: const ChismesApp(), useScaffold: false),
    );
    await tester.pumpAndSettle();

    // Verify that the app starts with the login screen.
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
