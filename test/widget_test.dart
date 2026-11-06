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

import 'helpers/mock_app_logger_helper.dart';

@GenerateMocks([LoginController])
import 'widget_test.mocks.dart';

void main() {
  late MockLoginController mockLoginController;

  setUpAll(() {
    // Provide dummy values for complex types
    provideDummy<AuthState>(const AuthInitial());
  });

  setUp(() {
    // Registrar mocks necesarios
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
    // Limpiar mocks
    if (getIt.isRegistered<LoginController>()) {
      getIt.unregister<LoginController>();
    }
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChismesApp());
    await tester.pumpAndSettle();

    // Verify that the app starts with the login screen.
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
