# Templates y Ejemplos de Tests

**Propósito:** Guía práctica con templates y ejemplos concretos para implementar tests en las áreas críticas.

---

## 📋 Tabla de Contenidos

1. [Controllers Tests](#controllers-tests)
2. [DataSource Tests](#datasource-tests)
3. [Screen Widget Tests](#screen-widget-tests)
4. [State Tests](#state-tests)
5. [Service Tests](#service-tests)
6. [Model Tests](#model-tests)

---

## Controllers Tests

### Template: Controller con State Management

```dart
// test/features/home/presentation/controllers/following_tab_controller_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chismes/core/result/result.dart';
import 'package:chismes/features/home/domain/usecases/get_following_feed.dart';
import 'package:chismes/features/home/presentation/controllers/following_tab_controller.dart';
import 'package:chismes/features/home/presentation/states/following_tab_state.dart';

@GenerateMocks([GetFollowingFeed])
import 'following_tab_controller_test.mocks.dart';

void main() {
  late FollowingTabController controller;
  late MockGetFollowingFeed mockGetFollowingFeed;

  setUp(() {
    mockGetFollowingFeed = MockGetFollowingFeed();
    controller = FollowingTabController(mockGetFollowingFeed);
  });

  tearDown(() {
    controller.dispose();
  });

  group('FollowingTabController', () {
    group('loadInitialGossips', () {
      test('debe cargar gossips iniciales exitosamente', () async {
        // Arrange
        final gossips = [
          FeedGossip(id: '1', subject: 'Test 1'),
          FeedGossip(id: '2', subject: 'Test 2'),
        ];
        when(mockGetFollowingFeed.execute(any))
            .thenAnswer((_) async => Result.success(PaginatedGossips(
                  gossips: gossips,
                  hasMore: true,
                  cursor: 'cursor123',
                )));

        // Act
        await controller.loadInitialGossips();

        // Assert
        expect(controller.state, isA<FollowingTabLoadedState>());
        final loadedState = controller.state as FollowingTabLoadedState;
        expect(loadedState.gossips.length, 2);
        expect(loadedState.hasMore, true);
        verify(mockGetFollowingFeed.execute(any)).called(1);
      });

      test('debe manejar error al cargar gossips', () async {
        // Arrange
        when(mockGetFollowingFeed.execute(any))
            .thenAnswer((_) async => Result.failure(ServerFailure('Error')));

        // Act
        await controller.loadInitialGossips();

        // Assert
        expect(controller.state, isA<FollowingTabErrorState>());
        final errorState = controller.state as FollowingTabErrorState;
        expect(errorState.message, contains('Error'));
      });

      test('debe actualizar estado a loading durante carga', () async {
        // Arrange
        final states = <FollowingTabState>[];
        controller.addListener(() {
          states.add(controller.state);
        });

        when(mockGetFollowingFeed.execute(any))
            .thenAnswer((_) async => Result.success(PaginatedGossips(
                  gossips: [],
                  hasMore: false,
                  cursor: null,
                )));

        // Act
        await controller.loadInitialGossips();

        // Assert
        expect(states, [
          isA<FollowingTabLoadingState>(),
          isA<FollowingTabLoadedState>(),
        ]);
      });
    });

    group('loadMoreGossips', () {
      test('debe cargar más gossips con paginación', () async {
        // Arrange - Estado inicial con gossips
        final initialGossips = [
          FeedGossip(id: '1', subject: 'Test 1'),
        ];
        controller.state = FollowingTabLoadedState(
          gossips: initialGossips,
          hasMore: true,
          cursor: 'cursor123',
        );

        final newGossips = [
          FeedGossip(id: '2', subject: 'Test 2'),
        ];
        when(mockGetFollowingFeed.execute(any))
            .thenAnswer((_) async => Result.success(PaginatedGossips(
                  gossips: newGossips,
                  hasMore: true,
                  cursor: 'cursor456',
                )));

        // Act
        await controller.loadMoreGossips();

        // Assert
        final loadedState = controller.state as FollowingTabLoadedState;
        expect(loadedState.gossips.length, 2);
        expect(loadedState.cursor, 'cursor456');
        verify(mockGetFollowingFeed.execute(argThat(
          predicate<FeedQuery>((query) => query.cursor == 'cursor123'),
        ))).called(1);
      });

      test('no debe cargar si ya está cargando', () async {
        // Arrange
        controller.state = FollowingTabLoadingState();

        // Act
        await controller.loadMoreGossips();

        // Assert
        verifyNever(mockGetFollowingFeed.execute(any));
      });

      test('no debe cargar si no hay más gossips', () async {
        // Arrange
        controller.state = FollowingTabLoadedState(
          gossips: [],
          hasMore: false,
          cursor: null,
        );

        // Act
        await controller.loadMoreGossips();

        // Assert
        verifyNever(mockGetFollowingFeed.execute(any));
      });
    });

    group('refresh', () {
      test('debe recargar gossips desde el inicio', () async {
        // Arrange
        controller.state = FollowingTabLoadedState(
          gossips: [FeedGossip(id: '1', subject: 'Old')],
          hasMore: false,
          cursor: null,
        );

        final newGossips = [
          FeedGossip(id: '2', subject: 'New'),
        ];
        when(mockGetFollowingFeed.execute(any))
            .thenAnswer((_) async => Result.success(PaginatedGossips(
                  gossips: newGossips,
                  hasMore: true,
                  cursor: 'cursor',
                )));

        // Act
        await controller.refresh();

        // Assert
        final loadedState = controller.state as FollowingTabLoadedState;
        expect(loadedState.gossips.length, 1);
        expect(loadedState.gossips.first.subject, 'New');
        verify(mockGetFollowingFeed.execute(argThat(
          predicate<FeedQuery>((query) => query.cursor == null),
        ))).called(1);
      });
    });
  });
}
```

### Template Mínimo: Controller Simple

```dart
// Para controllers más simples
void main() {
  late MyController controller;
  late MockDependency mockDep;

  setUp(() {
    mockDep = MockDependency();
    controller = MyController(mockDep);
  });

  group('MyController', () {
    test('debe inicializarse correctamente', () {
      expect(controller.state, isA<InitialState>());
    });

    test('debe ejecutar acción exitosamente', () async {
      // Arrange
      when(mockDep.doSomething()).thenAnswer((_) async => Result.success(data));
      
      // Act
      await controller.action();
      
      // Assert
      expect(controller.state, isA<SuccessState>());
    });
  });
}
```

---

## DataSource Tests

### Template: Supabase DataSource

```dart
// test/features/auth/data/datasources/supabase_auth_datasource_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chismes/features/auth/data/datasources/supabase_auth_datasource_impl.dart';

@GenerateMocks([SupabaseClient, GoTrueClient, AuthResponse])
import 'supabase_auth_datasource_test.mocks.dart';

void main() {
  late SupabaseAuthDataSourceImpl dataSource;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(mockSupabaseClient.auth).thenReturn(mockAuth);
    dataSource = SupabaseAuthDataSourceImpl(mockSupabaseClient);
  });

  group('SupabaseAuthDataSourceImpl', () {
    group('signUpWithEmail', () {
      test('debe crear usuario exitosamente', () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        final mockUser = User(
          id: 'user123',
          email: 'test@example.com',
          createdAt: DateTime.now().toIso8601String(),
        );
        
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockResponse);
        
        when(mockResponse.user).thenReturn(mockUser);

        // Act
        final result = await dataSource.signUpWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, isNotNull);
        expect(result.email, 'test@example.com');
        verify(mockAuth.signUp(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('debe lanzar excepción cuando falla el registro', () async {
        // Arrange
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(AuthException('Email already exists'));

        // Act & Assert
        expect(
          () => dataSource.signUpWithEmail(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('debe manejar errores de red', () async {
        // Arrange
        when(mockAuth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('Network error'));

        // Act & Assert
        expect(
          () => dataSource.signUpWithEmail(
            email: 'test@example.com',
            password: 'password123',
          ),
          throwsException,
        );
      });
    });

    group('signInWithEmail', () {
      test('debe autenticar usuario exitosamente', () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        final mockUser = User(
          id: 'user123',
          email: 'test@example.com',
        );
        
        when(mockAuth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockResponse);
        
        when(mockResponse.user).thenReturn(mockUser);

        // Act
        final result = await dataSource.signInWithEmail(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result, isNotNull);
        expect(result.email, 'test@example.com');
      });

      test('debe fallar con credenciales inválidas', () async {
        // Arrange
        when(mockAuth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(AuthException('Invalid credentials'));

        // Act & Assert
        expect(
          () => dataSource.signInWithEmail(
            email: 'test@example.com',
            password: 'wrong',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}
```

---

## Screen Widget Tests

### Template: Screen con Formulario

```dart
// test/features/auth/presentation/screens/otp_verification_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:chismes/features/auth/presentation/screens/otp_verification_screen.dart';
import 'package:chismes/features/auth/presentation/controllers/otp_verification_controller.dart';

@GenerateMocks([OtpVerificationController])
import 'otp_verification_screen_test.mocks.dart';

void main() {
  late MockOtpVerificationController mockController;

  setUp(() {
    mockController = MockOtpVerificationController();
    when(mockController.state).thenReturn(OtpVerificationInitialState());
  });

  Widget createTestWidget({String email = 'test@example.com'}) {
    return MaterialApp(
      home: ChangeNotifierProvider<OtpVerificationController>.value(
        value: mockController,
        child: OtpVerificationScreen(email: email),
      ),
    );
  }

  group('OtpVerificationScreen', () {
    testWidgets('debe renderizar correctamente', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Verificar Código'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(6)); // 6 dígitos OTP
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('debe mostrar email en pantalla', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(createTestWidget(email: 'user@test.com'));

      // Assert
      expect(find.textContaining('user@test.com'), findsOneWidget);
    });

    testWidgets('debe llamar a verifyOtp al presionar botón', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Ingresar código OTP
      final otpFields = find.byType(TextFormField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(otpFields.at(i), '${i + 1}');
      }

      // Act
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      verify(mockController.verifyOtp('123456')).called(1);
    });

    testWidgets('debe mostrar loading indicator cuando está verificando', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(OtpVerificationLoadingState());
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('debe mostrar error cuando falla verificación', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(
        OtpVerificationErrorState('Código inválido'),
      );
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.pump();

      // Assert
      expect(find.text('Código inválido'), findsOneWidget);
    });

    testWidgets('debe navegar cuando verificación es exitosa', (tester) async {
      // Arrange
      when(mockController.state).thenReturn(OtpVerificationSuccessState());
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.pumpAndSettle();

      // Assert - Verificar navegación (depende de implementación)
      // expect(find.byType(NextScreen), findsOneWidget);
    });

    testWidgets('debe deshabilitar botón si código incompleto', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act - Solo ingresar 3 dígitos
      final otpFields = find.byType(TextFormField);
      for (int i = 0; i < 3; i++) {
        await tester.enterText(otpFields.at(i), '${i + 1}');
      }
      await tester.pump();

      // Assert
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.enabled, false);
    });

    testWidgets('debe permitir reenviar código', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget());

      // Act
      await tester.tap(find.text('Reenviar código'));
      await tester.pump();

      // Assert
      verify(mockController.resendOtp()).called(1);
    });
  });
}
```

---

## State Tests

### Template: State Simple

```dart
// test/features/home/presentation/states/following_tab_state_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/home/presentation/states/following_tab_state.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';

void main() {
  group('FollowingTabState', () {
    group('FollowingTabInitialState', () {
      test('debe crear instancia correctamente', () {
        final state = FollowingTabInitialState();
        expect(state, isA<FollowingTabState>());
      });

      test('debe ser igual a otra instancia inicial', () {
        final state1 = FollowingTabInitialState();
        final state2 = FollowingTabInitialState();
        expect(state1, equals(state2));
      });
    });

    group('FollowingTabLoadingState', () {
      test('debe crear instancia correctamente', () {
        final state = FollowingTabLoadingState();
        expect(state, isA<FollowingTabState>());
      });
    });

    group('FollowingTabLoadedState', () {
      test('debe crear instancia con datos', () {
        // Arrange
        final gossips = [
          FeedGossip(id: '1', subject: 'Test 1'),
          FeedGossip(id: '2', subject: 'Test 2'),
        ];

        // Act
        final state = FollowingTabLoadedState(
          gossips: gossips,
          hasMore: true,
          cursor: 'cursor123',
        );

        // Assert
        expect(state.gossips.length, 2);
        expect(state.hasMore, true);
        expect(state.cursor, 'cursor123');
      });

      test('debe ser inmutable', () {
        final gossips = <FeedGossip>[];
        final state = FollowingTabLoadedState(
          gossips: gossips,
          hasMore: false,
          cursor: null,
        );

        // Intentar modificar lista original no debe afectar state
        gossips.add(FeedGossip(id: '1', subject: 'New'));
        
        expect(state.gossips.length, 0);
      });

      test('debe soportar copyWith', () {
        final state = FollowingTabLoadedState(
          gossips: [],
          hasMore: true,
          cursor: 'cursor1',
        );

        final newState = state.copyWith(cursor: 'cursor2');

        expect(newState.cursor, 'cursor2');
        expect(newState.hasMore, true);
        expect(state.cursor, 'cursor1'); // Original no cambió
      });
    });

    group('FollowingTabErrorState', () {
      test('debe crear instancia con mensaje de error', () {
        final state = FollowingTabErrorState('Error de red');
        
        expect(state.message, 'Error de red');
      });

      test('debe ser igual a otro estado con mismo mensaje', () {
        final state1 = FollowingTabErrorState('Error');
        final state2 = FollowingTabErrorState('Error');
        
        expect(state1, equals(state2));
      });
    });
  });
}
```

---

## Service Tests

### Template: Service con Dependencies

```dart
// test/core/services/deep_link_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chismes/core/services/deep_link_service.dart';

@GenerateMocks([AppLinksPlugin, NavigatorObserver])
import 'deep_link_service_test.mocks.dart';

void main() {
  late DeepLinkService service;
  late MockAppLinksPlugin mockAppLinks;

  setUp(() {
    mockAppLinks = MockAppLinksPlugin();
    service = DeepLinkService(mockAppLinks);
  });

  group('DeepLinkService', () {
    group('initialize', () {
      test('debe configurar listener de links', () async {
        // Arrange
        when(mockAppLinks.getInitialLink())
            .thenAnswer((_) async => null);

        // Act
        await service.initialize();

        // Assert
        verify(mockAppLinks.getInitialLink()).called(1);
        verify(mockAppLinks.allUriLinkStream).called(1);
      });

      test('debe procesar initial link si existe', () async {
        // Arrange
        final uri = Uri.parse('chismes://gossip/123');
        when(mockAppLinks.getInitialLink())
            .thenAnswer((_) async => uri);

        // Act
        await service.initialize();

        // Assert
        expect(service.lastProcessedLink, uri);
      });
    });

    group('handleDeepLink', () {
      test('debe parsear link de gossip correctamente', () {
        // Arrange
        final uri = Uri.parse('chismes://gossip/123');

        // Act
        final result = service.handleDeepLink(uri);

        // Assert
        expect(result, isA<GossipDeepLink>());
        expect(result.gossipId, '123');
      });

      test('debe parsear link de perfil correctamente', () {
        // Arrange
        final uri = Uri.parse('chismes://profile/user123');

        // Act
        final result = service.handleDeepLink(uri);

        // Assert
        expect(result, isA<ProfileDeepLink>());
        expect(result.userId, 'user123');
      });

      test('debe manejar links inválidos', () {
        // Arrange
        final uri = Uri.parse('invalid://link');

        // Act
        final result = service.handleDeepLink(uri);

        // Assert
        expect(result, isNull);
      });

      test('debe extraer query parameters', () {
        // Arrange
        final uri = Uri.parse('chismes://gossip/123?referrer=share');

        // Act
        final result = service.handleDeepLink(uri) as GossipDeepLink;

        // Assert
        expect(result.referrer, 'share');
      });
    });

    group('dispose', () {
      test('debe cancelar subscripciones', () {
        // Arrange
        service.initialize();

        // Act
        service.dispose();

        // Assert
        expect(service.isDisposed, true);
      });
    });
  });
}
```

---

## Model Tests

### Template: Model con Serialización

```dart
// test/features/home/data/models/feed_gossip_model_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/home/data/models/feed_gossip_model.dart';
import 'package:chismes/features/home/domain/entities/feed_gossip.dart';

void main() {
  group('FeedGossipModel', () {
    final tJson = {
      'id': '123',
      'subject': 'Test Subject',
      'body': 'Test Body',
      'location': 'Test Location',
      'created_at': '2024-01-01T00:00:00Z',
      'author_id': 'user123',
      'author_username': 'testuser',
      'reactions_count': 10,
      'comments_count': 5,
    };

    final tModel = FeedGossipModel(
      id: '123',
      subject: 'Test Subject',
      body: 'Test Body',
      location: 'Test Location',
      createdAt: '2024-01-01T00:00:00Z',
      authorId: 'user123',
      authorUsername: 'testuser',
      reactionsCount: 10,
      commentsCount: 5,
    );

    group('fromJson', () {
      test('debe deserializar JSON correctamente', () {
        // Act
        final result = FeedGossipModel.fromJson(tJson);

        // Assert
        expect(result.id, '123');
        expect(result.subject, 'Test Subject');
        expect(result.authorUsername, 'testuser');
        expect(result.reactionsCount, 10);
      });

      test('debe manejar campos opcionales', () {
        // Arrange
        final jsonWithOptionals = {
          ...tJson,
          'image_url': 'https://example.com/image.jpg',
          'thumbnail_url': 'https://example.com/thumb.jpg',
        };

        // Act
        final result = FeedGossipModel.fromJson(jsonWithOptionals);

        // Assert
        expect(result.imageUrl, 'https://example.com/image.jpg');
        expect(result.thumbnailUrl, 'https://example.com/thumb.jpg');
      });

      test('debe manejar campos null', () {
        // Arrange
        final jsonWithNulls = {
          ...tJson,
          'image_url': null,
          'body': null,
        };

        // Act
        final result = FeedGossipModel.fromJson(jsonWithNulls);

        // Assert
        expect(result.imageUrl, isNull);
        expect(result.body, isNull);
      });
    });

    group('toJson', () {
      test('debe serializar a JSON correctamente', () {
        // Act
        final json = tModel.toJson();

        // Assert
        expect(json['id'], '123');
        expect(json['subject'], 'Test Subject');
        expect(json['author_username'], 'testuser');
        expect(json['reactions_count'], 10);
      });

      test('debe mantener estructura al serializar y deserializar', () {
        // Act
        final json = tModel.toJson();
        final model = FeedGossipModel.fromJson(json);

        // Assert
        expect(model.id, tModel.id);
        expect(model.subject, tModel.subject);
        expect(model.authorUsername, tModel.authorUsername);
      });
    });

    group('toEntity', () {
      test('debe convertir a entity correctamente', () {
        // Act
        final entity = tModel.toEntity();

        // Assert
        expect(entity, isA<FeedGossip>());
        expect(entity.id, tModel.id);
        expect(entity.subject, tModel.subject);
        expect(entity.authorUsername, tModel.authorUsername);
      });

      test('debe parsear fecha correctamente', () {
        // Act
        final entity = tModel.toEntity();

        // Assert
        expect(entity.createdAt, isA<DateTime>());
        expect(entity.createdAt.year, 2024);
      });
    });

    group('equality', () {
      test('debe ser igual a otro model con mismos valores', () {
        final model1 = tModel;
        final model2 = FeedGossipModel.fromJson(tJson);

        expect(model1, equals(model2));
      });

      test('debe ser diferente con valores diferentes', () {
        final model1 = tModel;
        final model2 = tModel.copyWith(subject: 'Different');

        expect(model1, isNot(equals(model2)));
      });
    });
  });
}
```

---

## Patrones Avanzados

### Testing de Streams

```dart
test('debe emitir valores correctamente', () async {
  // Arrange
  final controller = StreamController<int>();
  final stream = controller.stream;

  // Act
  controller.add(1);
  controller.add(2);
  controller.add(3);
  controller.close();

  // Assert
  await expectLater(
    stream,
    emitsInOrder([1, 2, 3, emitsDone]),
  );
});
```

### Testing de Futures

```dart
test('debe completar future correctamente', () async {
  // Arrange
  final future = service.fetchData();

  // Assert
  await expectLater(future, completion(isNotNull));
});
```

### Testing de Excepciones

```dart
test('debe lanzar excepción específica', () {
  expect(
    () => service.invalidOperation(),
    throwsA(isA<ValidationException>()),
  );
});
```

### Verify con Matchers

```dart
test('debe llamar con argumentos específicos', () {
  // Act
  repository.save(data);

  // Assert
  verify(mockDataSource.insert(argThat(
    predicate<Data>((d) => d.id == 'expected' && d.isValid),
  ))).called(1);
});
```

---

## Checklist por Tipo de Test

### Controllers
- [ ] Estado inicial correcto
- [ ] Transiciones de estado
- [ ] Llamadas a dependencies
- [ ] Error handling
- [ ] Loading states
- [ ] Dispose resources

### DataSources
- [ ] Operaciones CRUD
- [ ] Serialización/Deserialización
- [ ] Error handling de Supabase
- [ ] Network errors
- [ ] Verify calls a Supabase client

### Screens
- [ ] Renderiza correctamente
- [ ] Interacción con widgets
- [ ] Validación de formularios
- [ ] Loading indicators
- [ ] Error messages
- [ ] Navegación

### States
- [ ] Creación de instancias
- [ ] Inmutabilidad
- [ ] Equality
- [ ] copyWith (si aplica)

### Services
- [ ] Initialize correctamente
- [ ] Configuración de listeners
- [ ] Procesamiento de datos
- [ ] Error handling
- [ ] Dispose/cleanup

---

**Última actualización:** 2026-11-12  
**Autor:** Claude Code
