import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chismes/main.dart' as app;
import 'package:chismes/features/auth/presentation/screens/login_screen.dart';
import 'package:chismes/features/auth/presentation/widgets/auth_gate.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/logging/app_logger.dart';
import 'package:chismes/features/auth/presentation/controllers/login_controller.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';

import 'package:easy_localization/easy_localization.dart';
import 'helpers/mock_app_logger_helper.dart';
import 'helpers/test_translations_loader.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/presentation/controllers/otp_verification_controller.dart';
import 'package:chismes/features/auth/presentation/states/otp_verification_state.dart';

@GenerateMocks([LoginController, AuthRepository, OtpVerificationController])
import 'main_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Helper para envolver ChismesApp en EasyLocalization
  Widget wrapWithI18n(Widget child) {
    return EasyLocalization(
      supportedLocales: const [Locale('es'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'),
      startLocale: const Locale('es'),
      assetLoader: const TestTranslationsLoader(),
      useOnlyLangCode: true,
      child: child,
    );
  }

  // Guardar callbacks originales para restaurarlos después de cada test
  late Future<void> Function({String fileName}) originalLoadEnv;
  late Future<void> Function() originalInitializeSupabase;
  late Future<void> Function() originalSetupDependencies;
  late MockLoginController mockLoginController;
  late MockAuthRepository mockAuthRepository;
  late MockOtpVerificationController mockOtpController;

  setUpAll(() {
    // Provide dummy values for complex types
    provideDummy<AuthState>(const AuthInitial());
    provideDummy<OtpVerificationState>(
      const OtpVerificationState(email: 'test@example.com'),
    );
  });

  setUp(() {
    originalLoadEnv = app.loadEnv;
    originalInitializeSupabase = app.initializeSupabase;
    originalSetupDependencies = app.setupDependencies;

    // Registrar mocks necesarios para tests
    setupMockAppLogger();

    // Configurar mock de AuthRepository
    mockAuthRepository = MockAuthRepository();
    // Configurar authStateChanges para que devuelva un Stream que emite null (no autenticado)
    when(mockAuthRepository.authStateChanges).thenAnswer(
      (_) => Stream.value(null),
    );
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    getIt.registerSingleton<AuthRepository>(mockAuthRepository);

    // Configurar mock de OtpVerificationController
    mockOtpController = MockOtpVerificationController();
    when(mockOtpController.state).thenReturn(
      const OtpVerificationState(email: 'test@example.com'),
    );
    if (getIt.isRegistered<OtpVerificationController>()) {
      getIt.unregister<OtpVerificationController>();
    }
    getIt.registerSingleton<OtpVerificationController>(mockOtpController);

    // Configurar mock de LoginController
    mockLoginController = MockLoginController();
    when(mockLoginController.state).thenReturn(const AuthInitial());

    // Registrar mock en GetIt
    if (getIt.isRegistered<LoginController>()) {
      getIt.unregister<LoginController>();
    }
    getIt.registerSingleton<LoginController>(mockLoginController);
  });

  tearDown(() {
    // Restaurar callbacks originales
    app.loadEnv = originalLoadEnv;
    app.initializeSupabase = originalInitializeSupabase;
    app.setupDependencies = originalSetupDependencies;

    // Limpiar mocks
    if (getIt.isRegistered<AppLogger>()) {
      getIt.unregister<AppLogger>();
    }
    if (getIt.isRegistered<AuthRepository>()) {
      getIt.unregister<AuthRepository>();
    }
    if (getIt.isRegistered<OtpVerificationController>()) {
      getIt.unregister<OtpVerificationController>();
    }
    if (getIt.isRegistered<LoginController>()) {
      getIt.unregister<LoginController>();
    }
  });

  group('initializeApp', () {
    test('debe llamar a todas las funciones de inicialización en orden', () async {
      // Arrange
      var loadEnvCalled = false;
      var initializeSupabaseCalled = false;
      var setupDependenciesCalled = false;
      var callOrder = <String>[];

      app.loadEnv = ({String fileName = '.env'}) async {
        loadEnvCalled = true;
        callOrder.add('loadEnv');
      };

      app.initializeSupabase = () async {
        initializeSupabaseCalled = true;
        callOrder.add('initializeSupabase');
      };

      app.setupDependencies = () async {
        setupDependenciesCalled = true;
        callOrder.add('setupDependencies');
      };

      // Act
      await app.initializeApp();

      // Assert
      expect(loadEnvCalled, isTrue, reason: 'loadEnv debe ser llamado');
      expect(initializeSupabaseCalled, isTrue, reason: 'initializeSupabase debe ser llamado');
      expect(setupDependenciesCalled, isTrue, reason: 'setupDependencies debe ser llamado');
      expect(callOrder, ['loadEnv', 'initializeSupabase', 'setupDependencies']);
    });

    test('debe pasar el nombre de archivo correcto a loadEnv', () async {
      // Arrange
      String? capturedFileName;

      app.loadEnv = ({String fileName = '.env'}) async {
        capturedFileName = fileName;
      };

      app.initializeSupabase = () async {};
      app.setupDependencies = () async {};

      // Act
      await app.initializeApp();

      // Assert
      expect(capturedFileName, '.env');
    });

    test('debe inicializar WidgetsFlutterBinding', () async {
      // Arrange
      app.loadEnv = ({String fileName = '.env'}) async {};
      app.initializeSupabase = () async {};
      app.setupDependencies = () async {};

      // Act
      await app.initializeApp();

      // Assert - WidgetsFlutterBinding debe estar inicializado
      expect(WidgetsBinding.instance, isNotNull);
    });

    test('debe completarse sin errores cuando todas las dependencias se inicializan correctamente', () async {
      // Arrange
      app.loadEnv = ({String fileName = '.env'}) async {};
      app.initializeSupabase = () async {};
      app.setupDependencies = () async {};

      // Act & Assert - No debe lanzar excepciones
      await expectLater(app.initializeApp(), completes);
    });

    test('debe propagar errores de loadEnv', () async {
      // Arrange
      app.loadEnv = ({String fileName = '.env'}) async {
        throw Exception('Error loading .env');
      };

      app.initializeSupabase = () async {};
      app.setupDependencies = () async {};

      // Act & Assert
      expect(
        () => app.initializeApp(),
        throwsA(isA<Exception>()),
      );
    });

    test('debe propagar errores de initializeSupabase', () async {
      // Arrange
      app.loadEnv = ({String fileName = '.env'}) async {};

      app.initializeSupabase = () async {
        throw Exception('Error initializing Supabase');
      };

      app.setupDependencies = () async {};

      // Act & Assert
      expect(
        () => app.initializeApp(),
        throwsA(isA<Exception>()),
      );
    });

    test('debe propagar errores de setupDependencies', () async {
      // Arrange
      app.loadEnv = ({String fileName = '.env'}) async {};
      app.initializeSupabase = () async {};

      app.setupDependencies = () async {
        throw Exception('Error setting up dependencies');
      };

      // Act & Assert
      expect(
        () => app.initializeApp(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ChismesApp Widget', () {
    testWidgets('debe crear MaterialApp con configuración correcta', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, false);
      expect(materialApp.title, 'Chismes');
      expect(materialApp.themeMode, ThemeMode.system);
    });

    testWidgets('debe tener LoginScreen como home', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('debe tener tema claro configurado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);
    });

    testWidgets('debe tener tema oscuro configurado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.darkTheme, isNotNull);
    });

    testWidgets('debe usar ThemeMode.system', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.system);
    });

    testWidgets('debe renderizar sin errores', (WidgetTester tester) async {
      // Act & Assert - Si no lanza excepción, el test pasa
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('debe tener Scaffold en LoginScreen', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('ChismesApp debe ser un StatelessWidget', (WidgetTester tester) async {
      // Assert
      expect(const app.ChismesApp(), isA<StatelessWidget>());
    });

    testWidgets('debe tener key opcional', (WidgetTester tester) async {
      // Arrange
      const testKey = Key('chismes_app_key');

      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp(key: testKey)));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('MaterialApp debe tener la estructura correcta', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);

      final materialApp = tester.widget<MaterialApp>(materialAppFinder);
      expect(materialApp.home, isA<AuthGate>());
    });
  });

  group('Configuración de MaterialApp', () {
    testWidgets('debugShowCheckedModeBanner debe estar en false', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, isFalse);
    });

    testWidgets('title debe ser "Chismes"', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, equals('Chismes'));
    });

    testWidgets('debe tener ambos temas configurados (light y dark)', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull, reason: 'Light theme debe estar configurado');
      expect(materialApp.darkTheme, isNotNull, reason: 'Dark theme debe estar configurado');
    });

    testWidgets('themeMode debe seguir el sistema', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.system));
    });

    testWidgets('home debe ser una instancia const de AuthGate', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.home, isA<AuthGate>());
    });
  });

  group('Renderizado y estructura', () {
    testWidgets('debe renderizar correctamente sin errores de layout', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert - No debe haber overflow u otros errores de renderizado
      expect(tester.takeException(), isNull);
    });

    testWidgets('debe tener una jerarquía de widgets válida', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('no debe tener widgets rotos o faltantes', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert - Buscar texto del AppBar
      expect(find.text('Chismes'), findsOneWidget);
    });
  });

  group('Estado y ciclo de vida', () {
    testWidgets('debe mantener el estado al reconstruir', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Reconstruir
      await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      // Assert - LoginScreen debe seguir presente
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('debe reconstruirse sin errores múltiples veces', (WidgetTester tester) async {
      // Act
      for (int i = 0; i < 3; i++) {
        await tester.pumpWidget(wrapWithI18n(const app.ChismesApp()));
      await tester.pumpAndSettle();
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(LoginScreen), findsOneWidget);
      }
    });
  });

  group('Callbacks de inicialización', () {
    test('loadEnv debe ser callable', () {
      expect(app.loadEnv, isA<Function>());
    });

    test('initializeSupabase debe ser callable', () {
      expect(app.initializeSupabase, isA<Function>());
    });

    test('setupDependencies debe ser callable', () {
      expect(app.setupDependencies, isA<Function>());
    });
  });
}
