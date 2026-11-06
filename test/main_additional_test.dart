import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chismes/main.dart' as app;
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/theme/app_theme.dart';
import 'package:chismes/core/services/deep_link_service.dart';
import 'package:chismes/core/logging/app_logger.dart';
import 'package:chismes/features/auth/presentation/controllers/login_controller.dart';
import 'package:chismes/features/auth/presentation/state/auth_state.dart';

import 'helpers/mock_app_logger_helper.dart';

// Generate mocks
@GenerateMocks([DeepLinkService, LoginController])
import 'main_additional_test.mocks.dart';

/// Tests adicionales para main.dart
///
/// Estos tests cubren aspectos más específicos como:
/// - NavigatorKey para deep links
/// - Temas (colores, typography)
/// - Deep link initialization
/// - Error recovery
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Guardar callbacks originales
  late Future<void> Function({String fileName}) originalLoadEnv;
  late Future<void> Function() originalInitializeSupabase;
  late Future<void> Function() originalSetupDependencies;
  late MockLoginController mockLoginController;

  setUpAll(() {
    // Provide dummy values for complex types
    provideDummy<AuthState>(const AuthInitial());
  });

  setUp(() {
    originalLoadEnv = app.loadEnv;
    originalInitializeSupabase = app.initializeSupabase;
    originalSetupDependencies = app.setupDependencies;

    // Registrar mocks necesarios para tests
    setupMockAppLogger();

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
    app.loadEnv = originalLoadEnv;
    app.initializeSupabase = originalInitializeSupabase;
    app.setupDependencies = originalSetupDependencies;

    // Limpiar mocks
    if (getIt.isRegistered<AppLogger>()) {
      getIt.unregister<AppLogger>();
    }
    if (getIt.isRegistered<LoginController>()) {
      getIt.unregister<LoginController>();
    }
  });

  group('NavigatorKey (Deep Links)', () {
    testWidgets('MaterialApp debe tener navigatorKey configurado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(const app.ChismesApp());

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.navigatorKey, isNotNull);
      expect(materialApp.navigatorKey, equals(navigatorKey));
    });

    testWidgets('navigatorKey debe ser el mismo GlobalKey exportado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(const app.ChismesApp());

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.navigatorKey, same(navigatorKey));
    });

    test('navigatorKey debe ser un GlobalKey<NavigatorState>', () {
      // Assert
      expect(navigatorKey, isA<GlobalKey<NavigatorState>>());
    });
  });

  group('Temas - Light Theme', () {
    testWidgets('light theme debe tener color primario configurado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(const app.ChismesApp());

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final lightTheme = materialApp.theme!;

      expect(lightTheme.colorScheme.primary, isNotNull);
      expect(lightTheme.brightness, Brightness.light);
    });

    testWidgets('light theme debe tener primaryLight configurado correctamente', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(const app.ChismesApp());

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final lightTheme = materialApp.theme!;

      // Verificar que el color primario es el primaryLight de AppTheme
      expect(lightTheme.colorScheme.primary, AppTheme.primaryLight);
    });

    testWidgets('light theme debe tener TextTheme configurado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(const app.ChismesApp());

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final lightTheme = materialApp.theme!;

      expect(lightTheme.textTheme, isNotNull);
      expect(lightTheme.textTheme.bodyLarge, isNotNull);
      expect(lightTheme.textTheme.bodyMedium, isNotNull);
      expect(lightTheme.textTheme.bodySmall, isNotNull);
    });
  });

  group('Temas - Dark Theme', () {
    testWidgets('dark theme debe tener color primario configurado', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(const app.ChismesApp());

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final darkTheme = materialApp.darkTheme!;

      expect(darkTheme.colorScheme.primary, isNotNull);
      expect(darkTheme.brightness, Brightness.dark);
    });

    testWidgets('dark theme debe tener primaryDark configurado correctamente', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(const app.ChismesApp());

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final darkTheme = materialApp.darkTheme!;

      // Verificar que el color primario es el primaryDark de AppTheme
      expect(darkTheme.colorScheme.primary, AppTheme.primaryDark);
    });

    testWidgets('dark theme debe ser diferente del light theme', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(const app.ChismesApp());

      // Assert
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final lightTheme = materialApp.theme!;
      final darkTheme = materialApp.darkTheme!;

      expect(lightTheme.colorScheme.primary, isNot(equals(darkTheme.colorScheme.primary)));
      expect(lightTheme.brightness, isNot(equals(darkTheme.brightness)));
    });
  });

  group('initializeApp - Deep Links', () {
    test('debe manejar error de deep links sin fallar la inicialización', () async {
      // Arrange
      app.loadEnv = ({String fileName = '.env'}) async {};
      app.initializeSupabase = () async {};
      app.setupDependencies = () async {
        // Simular que deep link service no está registrado
        // (esto causa el error que vemos en los logs)
      };

      // Act & Assert - No debe lanzar excepción
      // El error de deep links debe ser capturado e impreso
      await expectLater(app.initializeApp(), completes);
    });

    test('debe continuar si deep links initialization falla', () async {
      // Arrange
      var setupDependenciesCalled = false;

      app.loadEnv = ({String fileName = '.env'}) async {};
      app.initializeSupabase = () async {};
      app.setupDependencies = () async {
        setupDependenciesCalled = true;
        // No registrar DeepLinkService para simular error
      };

      // Act
      await app.initializeApp();

      // Assert - setupDependencies debe haber sido llamado
      expect(setupDependenciesCalled, isTrue);
    });
  });

  group('initializeApp - Orden de Ejecución', () {
    test('debe ejecutar loadEnv antes que initializeSupabase', () async {
      // Arrange
      var loadEnvTime = DateTime.now();
      var supabaseTime = DateTime.now();

      app.loadEnv = ({String fileName = '.env'}) async {
        loadEnvTime = DateTime.now();
        await Future.delayed(const Duration(milliseconds: 10));
      };

      app.initializeSupabase = () async {
        supabaseTime = DateTime.now();
      };

      app.setupDependencies = () async {};

      // Act
      await app.initializeApp();

      // Assert
      expect(loadEnvTime.isBefore(supabaseTime), isTrue);
    });

    test('debe ejecutar initializeSupabase antes que setupDependencies', () async {
      // Arrange
      var supabaseTime = DateTime.now();
      var dependenciesTime = DateTime.now();

      app.loadEnv = ({String fileName = '.env'}) async {};

      app.initializeSupabase = () async {
        supabaseTime = DateTime.now();
        await Future.delayed(const Duration(milliseconds: 10));
      };

      app.setupDependencies = () async {
        dependenciesTime = DateTime.now();
      };

      // Act
      await app.initializeApp();

      // Assert
      expect(supabaseTime.isBefore(dependenciesTime), isTrue);
    });

    test('no debe ejecutar pasos posteriores si loadEnv falla', () async {
      // Arrange
      var initializeSupabaseCalled = false;
      var setupDependenciesCalled = false;

      app.loadEnv = ({String fileName = '.env'}) async {
        throw Exception('Error loading .env');
      };

      app.initializeSupabase = () async {
        initializeSupabaseCalled = true;
      };

      app.setupDependencies = () async {
        setupDependenciesCalled = true;
      };

      // Act
      try {
        await app.initializeApp();
      } catch (e) {
        // Ignorar error esperado
      }

      // Assert
      expect(initializeSupabaseCalled, isFalse);
      expect(setupDependenciesCalled, isFalse);
    });
  });

  group('ChismesApp - Configuración Avanzada', () {
    testWidgets('debe construir sin dependencias externas inicializadas', (WidgetTester tester) async {
      // Act & Assert - Widget debe construir sin crash
      await tester.pumpWidget(const app.ChismesApp());
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('debe ser reconstruible múltiples veces sin state', (WidgetTester tester) async {
      // Act - Construir múltiples veces
      for (int i = 0; i < 5; i++) {
        await tester.pumpWidget(const app.ChismesApp());
        await tester.pump();
      }

      // Assert - Debe seguir funcionando
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('debe mantener configuración al reconstruir', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(const app.ChismesApp());

      var materialApp1 = tester.widget<MaterialApp>(find.byType(MaterialApp));
      var title1 = materialApp1.title;
      var themeMode1 = materialApp1.themeMode;

      // Reconstruir
      await tester.pumpWidget(const app.ChismesApp());

      var materialApp2 = tester.widget<MaterialApp>(find.byType(MaterialApp));
      var title2 = materialApp2.title;
      var themeMode2 = materialApp2.themeMode;

      // Assert - Configuración debe ser la misma
      expect(title1, equals(title2));
      expect(themeMode1, equals(themeMode2));
    });
  });

  group('Callbacks - Flexibilidad', () {
    test('debe permitir sobrescribir loadEnv con función custom', () async {
      // Arrange
      var customCalled = false;

      app.loadEnv = ({String fileName = '.env'}) async {
        customCalled = true;
      };
      app.initializeSupabase = () async {};
      app.setupDependencies = () async {};

      // Act
      await app.initializeApp();

      // Assert
      expect(customCalled, isTrue);
    });

    test('debe permitir sobrescribir initializeSupabase con función custom', () async {
      // Arrange
      var customCalled = false;

      app.loadEnv = ({String fileName = '.env'}) async {};
      app.initializeSupabase = () async {
        customCalled = true;
      };
      app.setupDependencies = () async {};

      // Act
      await app.initializeApp();

      // Assert
      expect(customCalled, isTrue);
    });

    test('debe permitir sobrescribir setupDependencies con función custom', () async {
      // Arrange
      var customCalled = false;

      app.loadEnv = ({String fileName = '.env'}) async {};
      app.initializeSupabase = () async {};
      app.setupDependencies = () async {
        customCalled = true;
      };

      // Act
      await app.initializeApp();

      // Assert
      expect(customCalled, isTrue);
    });

    test('debe restaurar callbacks originales después de sobrescribir', () async {
      // Arrange
      final originalCallback = app.loadEnv;

      // Act - Sobrescribir temporalmente
      app.loadEnv = ({String fileName = '.env'}) async {};

      // Restaurar
      app.loadEnv = originalCallback;

      // Assert
      expect(app.loadEnv, equals(originalCallback));
    });
  });

  group('Integración - Widget + Inicialización', () {
    test('puede completar inicialización antes de construir widget', () async {
      // Arrange
      app.loadEnv = ({String fileName = '.env'}) async {};
      app.initializeSupabase = () async {};
      app.setupDependencies = () async {};

      // Act
      await app.initializeApp();

      // Assert - No debe lanzar excepción al construir después
      expect(() => const app.ChismesApp(), returnsNormally);
    });
  });

  group('Edge Cases', () {
    test('debe manejar múltiples llamadas a initializeApp', () async {
      // Arrange
      var callCount = 0;

      app.loadEnv = ({String fileName = '.env'}) async {
        callCount++;
      };
      app.initializeSupabase = () async {};
      app.setupDependencies = () async {};

      // Act - Llamar múltiples veces
      await app.initializeApp();
      await app.initializeApp();
      await app.initializeApp();

      // Assert - Debe ejecutarse cada vez
      expect(callCount, 3);
    });

    testWidgets('debe construir widget sin llamar initializeApp primero', (WidgetTester tester) async {
      // Act & Assert - No debe crash
      await tester.pumpWidget(const app.ChismesApp());
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    test('debe aceptar fileName custom en loadEnv', () async {
      // Arrange
      String? capturedFileName;

      app.loadEnv = ({String fileName = '.env'}) async {
        capturedFileName = fileName;
      };
      app.initializeSupabase = () async {};
      app.setupDependencies = () async {};

      // Act - Llamar con fileName default
      await app.initializeApp();

      // Assert
      expect(capturedFileName, equals('.env'));
    });
  });

  group('Deep Links - Happy Path', () {
    test('debe inicializar deep links exitosamente cuando DeepLinkService está registrado', () async {
      // Arrange
      final mockDeepLinkService = MockDeepLinkService();

      // Configurar mock para no lanzar excepción
      when(mockDeepLinkService.initialize()).thenAnswer((_) async {});

      // Configurar callbacks
      app.loadEnv = ({String fileName = '.env'}) async {};
      app.initializeSupabase = () async {};
      app.setupDependencies = () async {
        // Registrar mock de DeepLinkService en GetIt
        if (!getIt.isRegistered<DeepLinkService>()) {
          getIt.registerSingleton<DeepLinkService>(mockDeepLinkService);
        }
      };

      // Act
      await app.initializeApp();

      // Assert - Verificar que initialize() fue llamado
      verify(mockDeepLinkService.initialize()).called(1);

      // Cleanup - Desregistrar para no afectar otros tests
      if (getIt.isRegistered<DeepLinkService>()) {
        await getIt.unregister<DeepLinkService>();
      }
    });

    test('debe continuar la ejecución después de inicializar deep links', () async {
      // Arrange
      final mockDeepLinkService = MockDeepLinkService();
      var deepLinksInitialized = false;

      when(mockDeepLinkService.initialize()).thenAnswer((_) async {
        deepLinksInitialized = true;
      });

      app.loadEnv = ({String fileName = '.env'}) async {};
      app.initializeSupabase = () async {};
      app.setupDependencies = () async {
        if (!getIt.isRegistered<DeepLinkService>()) {
          getIt.registerSingleton<DeepLinkService>(mockDeepLinkService);
        }
      };

      // Act
      await app.initializeApp();

      // Assert - Verificar que deep links se inicializó y la función completó
      expect(deepLinksInitialized, isTrue);
      verify(mockDeepLinkService.initialize()).called(1);

      // Cleanup
      if (getIt.isRegistered<DeepLinkService>()) {
        await getIt.unregister<DeepLinkService>();
      }
    });
  });
}
