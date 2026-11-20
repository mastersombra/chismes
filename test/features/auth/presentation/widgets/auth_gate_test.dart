import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/auth/presentation/widgets/auth_gate.dart';
import 'package:chismes/features/auth/domain/repositories/auth_repository.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';
import 'package:chismes/core/logging/logging.dart';
import 'package:chismes/core/di/injection_container.dart';
import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:chismes/core/result/result.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'auth_gate_test.mocks.dart';

@GenerateMocks([AuthRepository, AppLogger])
void main() {
  provideDummy<Result<Failure, bool>>(Result.success(true));
  provideDummy<Result<Failure, void>>(Result.success(null));

  group('AuthGate', () {
    late MockAuthRepository mockAuthRepository;
    late MockAppLogger mockLogger;
    late StreamController<User?> authStreamController;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockLogger = MockAppLogger();
      authStreamController = StreamController<User?>.broadcast();

      // Setup GetIt
      if (getIt.isRegistered<AuthRepository>()) {
        getIt.unregister<AuthRepository>();
      }
      if (getIt.isRegistered<AppLogger>()) {
        getIt.unregister<AppLogger>();
      }
      getIt.registerSingleton<AuthRepository>(mockAuthRepository);
      getIt.registerSingleton<AppLogger>(mockLogger);

      // Setup stream
      when(mockAuthRepository.authStateChanges)
          .thenAnswer((_) => authStreamController.stream);
      when(mockAuthRepository.validateSession())
          .thenAnswer((_) async => Result.success(true));
      when(mockAuthRepository.signOut())
          .thenAnswer((_) async => Result.success(null));
    });

    tearDown(() {
      authStreamController.close();
      getIt.reset();
    });

    Widget createWidget() {
      return const MaterialApp(
        home: AuthGate(),
      );
    }

    testWidgets('debe construirse sin errores', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.byType(AuthGate), findsOneWidget);
    });

    testWidgets('debe mostrar loading state inicialmente', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
    });

    // Nota: Test de respuesta a stream omitido porque requiere mockear
    // LoginController y otras dependencias de LoginScreen/MainNavigationScreen

    testWidgets('debe usar StreamBuilder', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.byType(StreamBuilder<User?>), findsOneWidget);
    });

    testWidgets('debe ser StatefulWidget', (tester) async {
      // Assert
      expect(const AuthGate(), isA<StatefulWidget>());
    });

    testWidgets('debe llamar logger.d en initState', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      verify(mockLogger.d('AuthGate: Inicializando guard de autenticación')).called(1);
    });

    testWidgets('debe llamar logger.d en estado waiting', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pump(); // Un frame para activar el builder

      // Assert
      verify(mockLogger.d('AuthGate: Esperando estado de autenticación...')).called(greaterThan(0));
    });

    testWidgets('loading state debe mostrar Scaffold con backgroundColor', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('loading state debe mostrar icono centrado', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
      expect(find.byType(Center), findsWidgets); // Puede haber más de uno
    });

    testWidgets('loading state debe usar Column con mainAxisAlignment.center', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      final columns = tester.widgetList<Column>(find.byType(Column));
      final centerColumn = columns.firstWhere(
        (col) => col.mainAxisAlignment == MainAxisAlignment.center,
        orElse: () => throw TestFailure('No column with MainAxisAlignment.center found'),
      );
      expect(centerColumn, isNotNull);
    });

    testWidgets('debe escuchar authStateChanges del repository', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      verify(mockAuthRepository.authStateChanges).called(greaterThan(0));
    });

    testWidgets('debe usar correct stream del repository', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());
      await tester.pump();

      // Assert - Debe haber consultado el stream
      verify(mockAuthRepository.authStateChanges).called(greaterThan(0));
    });

    testWidgets('debe tener estructura correcta en loading state', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert - Verificar jerarquía básica
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Column), findsWidgets);
      expect(find.byIcon(Icons.chat_bubble_rounded), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('CircularProgressIndicator debe tener configuración correcta', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.strokeWidth, equals(3));
    });

    testWidgets('debe tener SizedBox con dimensiones correctas para loading', (tester) async {
      // Act
      await tester.pumpWidget(createWidget());

      // Assert
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final loadingBox = sizedBoxes.firstWhere(
        (box) => box.width == 30 && box.height == 30,
        orElse: () => throw TestFailure('SizedBox 30x30 not found'),
      );
      expect(loadingBox, isNotNull);
    });
    group('validación de sesión con el servidor', () {
      void resume(WidgetTester tester) => tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);

      void background(WidgetTester tester) => tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.paused);

      testWidgets('valida la sesión al iniciar sin bloquear el arranque',
          (tester) async {
        final pending = Completer<Result<Failure, bool>>();
        when(mockAuthRepository.validateSession())
            .thenAnswer((_) => pending.future);

        await tester.pumpWidget(createWidget());

        verify(mockAuthRepository.validateSession()).called(1);
        // El guard sigue reaccionando al stream mientras valida
        verify(mockAuthRepository.authStateChanges).called(greaterThan(0));
        pending.complete(Result.success(true));
        await tester.pump();
      });

      testWidgets('sesión válida: no cierra sesión', (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        verifyNever(mockAuthRepository.signOut());
      });

      testWidgets('sesión rechazada por el servidor: cierra sesión',
          (tester) async {
        when(mockAuthRepository.validateSession())
            .thenAnswer((_) async => Result.success(false));

        await tester.pumpWidget(createWidget());
        await tester.pump();

        verify(mockAuthRepository.signOut()).called(1);
        verify(mockLogger.w(
                'AuthGate: Sesión rechazada por el servidor, cerrando sesión'))
            .called(1);
      });

      testWidgets('validación no concluyente (sin red): conserva la sesión',
          (tester) async {
        when(mockAuthRepository.validateSession()).thenAnswer((_) async =>
            Result.failure(
                const NetworkFailure(code: ErrorCode.networkError)));

        await tester.pumpWidget(createWidget());
        await tester.pump();

        verifyNever(mockAuthRepository.signOut());
      });

      testWidgets('al volver a primer plano dentro del intervalo no revalida',
          (tester) async {
        await tester.pumpWidget(createWidget());
        await tester.pump();

        background(tester);
        resume(tester);
        await tester.pump();

        verify(mockAuthRepository.validateSession()).called(1);
      });

      testWidgets('al volver a primer plano pasado el intervalo revalida',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: AuthGate(revalidateInterval: Duration.zero)),
        );
        await tester.pump();

        background(tester);
        resume(tester);
        await tester.pump();

        verify(mockAuthRepository.validateSession()).called(2);
      });

      testWidgets('ignora estados distintos de resumed', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: AuthGate(revalidateInterval: Duration.zero)),
        );
        await tester.pump();

        background(tester);
        await tester.pump();

        verify(mockAuthRepository.validateSession()).called(1);
      });

      testWidgets('no lanza validaciones simultáneas', (tester) async {
        final pending = Completer<Result<Failure, bool>>();
        when(mockAuthRepository.validateSession())
            .thenAnswer((_) => pending.future);
        await tester.pumpWidget(
          const MaterialApp(home: AuthGate(revalidateInterval: Duration.zero)),
        );

        background(tester);
        resume(tester);
        await tester.pump();

        verify(mockAuthRepository.validateSession()).called(1);
        pending.complete(Result.success(true));
        await tester.pump();
      });

      testWidgets('deja de observar el ciclo de vida al desmontarse',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: AuthGate(revalidateInterval: Duration.zero)),
        );
        await tester.pump();
        await tester.pumpWidget(const SizedBox());

        background(tester);
        resume(tester);
        await tester.pump();

        verify(mockAuthRepository.validateSession()).called(1);
      });
    });
  });
}
