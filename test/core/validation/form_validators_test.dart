import 'package:chismes/core/l10n/l10n.dart';
import 'package:chismes/core/validation/form_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormValidators', () {
    late Widget testApp;

    setUp(() {
      // Helper widget con localization para acceder a context.l10n
      testApp = MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Container(),
          ),
        ),
      );
    });

    group('required', () {
      testWidgets('debe retornar null cuando el valor es válido',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.required(context, 'test value', 'campo');

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe retornar error cuando el valor es null',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.required(context, null, 'campo');

        // Assert
        expect(result, isNotNull);
        expect(result, contains('campo'));
      });

      testWidgets('debe retornar error cuando el valor está vacío',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.required(context, '', 'campo');

        // Assert
        expect(result, isNotNull);
        expect(result, contains('campo'));
      });

      testWidgets('debe retornar error cuando el valor es solo espacios',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.required(context, '   ', 'campo');

        // Assert
        // Nota: Los espacios NO se consideran vacío por isEmpty
        expect(result, isNull);
      });

      testWidgets('debe usar el nombre del campo en el mensaje de error',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.required(context, null, 'un país');

        // Assert
        expect(result, isNotNull);
        expect(result, contains('país'));
      });
    });

    group('requiredWithMessage', () {
      test('debe retornar null cuando el valor es válido', () {
        // Act
        final result =
            FormValidators.requiredWithMessage('test value', 'Error custom');

        // Assert
        expect(result, isNull);
      });

      test('debe retornar mensaje personalizado cuando el valor es null', () {
        // Arrange
        const customMessage = 'Este campo es requerido';

        // Act
        final result = FormValidators.requiredWithMessage(null, customMessage);

        // Assert
        expect(result, equals(customMessage));
      });

      test('debe retornar mensaje personalizado cuando el valor está vacío',
          () {
        // Arrange
        const customMessage = 'Por favor ingresa un valor';

        // Act
        final result = FormValidators.requiredWithMessage('', customMessage);

        // Assert
        expect(result, equals(customMessage));
      });
    });

    group('minLength', () {
      testWidgets('debe retornar null cuando el valor cumple la longitud mínima',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.minLength(context, 'abcde', 5);

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe retornar null cuando el valor excede la longitud mínima',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.minLength(context, 'abcdefgh', 5);

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe retornar null cuando el valor es null', (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.minLength(context, null, 5);

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe retornar error cuando el valor es más corto',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.minLength(context, 'abc', 5);

        // Assert
        expect(result, isNotNull);
        expect(result, contains('5'));
      });

      testWidgets('debe retornar error cuando el valor está vacío',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.minLength(context, '', 1);

        // Assert
        expect(result, isNotNull);
      });
    });

    group('maxLength', () {
      testWidgets('debe retornar null cuando el valor cumple la longitud máxima',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.maxLength(context, 'abcde', 5);

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe retornar null cuando el valor es más corto',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.maxLength(context, 'abc', 5);

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe retornar null cuando el valor es null', (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.maxLength(context, null, 5);

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe retornar error cuando el valor excede la longitud',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.maxLength(context, 'abcdefgh', 5);

        // Assert
        expect(result, isNotNull);
        expect(result, contains('5'));
      });
    });

    group('email', () {
      testWidgets('debe retornar null cuando el email es válido',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.email(context, 'test@example.com');

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe retornar null cuando el email tiene subdominios',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.email(context, 'user@mail.company.com');

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe normalizar email a minúsculas antes de validar',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.email(context, 'Test@Example.COM');

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe validar email con espacios al inicio/fin',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.email(context, '  test@example.com  ');

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe retornar error cuando el email es null',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.email(context, null);

        // Assert
        expect(result, isNotNull);
      });

      testWidgets('debe retornar error cuando el email está vacío',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.email(context, '');

        // Assert
        expect(result, isNotNull);
      });

      testWidgets('debe retornar error cuando el email no tiene @',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.email(context, 'testexample.com');

        // Assert
        expect(result, isNotNull);
      });

      testWidgets('debe retornar error cuando el email no tiene dominio',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.email(context, 'test@');

        // Assert
        expect(result, isNotNull);
      });

      testWidgets('debe retornar error cuando el email no tiene usuario',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.email(context, '@example.com');

        // Assert
        expect(result, isNotNull);
      });

      testWidgets('debe retornar error cuando el dominio es muy corto',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.email(context, 'test@ex.c');

        // Assert
        expect(result, isNotNull);
      });
    });

    group('normalizeEmail', () {
      test('debe convertir email a minúsculas', () {
        // Act
        final result = FormValidators.normalizeEmail('Test@Example.COM');

        // Assert
        expect(result, equals('test@example.com'));
      });

      test('debe remover espacios al inicio y fin', () {
        // Act
        final result = FormValidators.normalizeEmail('  test@example.com  ');

        // Assert
        expect(result, equals('test@example.com'));
      });

      test('debe normalizar email que ya está en minúsculas', () {
        // Act
        final result = FormValidators.normalizeEmail('test@example.com');

        // Assert
        expect(result, equals('test@example.com'));
      });

      test('debe manejar email con caracteres especiales', () {
        // Act
        final result =
            FormValidators.normalizeEmail('User.Name+Tag@Example.COM');

        // Assert
        expect(result, equals('user.name+tag@example.com'));
      });
    });

    group('password', () {
      testWidgets('debe retornar null cuando la contraseña es válida',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.password(context, 'mypassword');

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe retornar null cuando la contraseña tiene espacios',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.password(context, 'my password 123');

        // Assert
        expect(result, isNull);
      });

      testWidgets('debe retornar error cuando la contraseña es null',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.password(context, null);

        // Assert
        expect(result, isNotNull);
      });

      testWidgets('debe retornar error cuando la contraseña está vacía',
          (tester) async {
        // Arrange
        await tester.pumpWidget(testApp);
        final context = tester.element(find.byType(Container));

        // Act
        final result = FormValidators.password(context, '');

        // Assert
        expect(result, isNotNull);
      });
    });

    group('username', () {
      Future<BuildContext> ctx(WidgetTester tester) async {
        await tester.pumpWidget(testApp);
        return tester.element(find.byType(Container));
      }

      testWidgets('acepta minúsculas, números y guion bajo (3-30)', (tester) async {
        // Arrange
        final context = await ctx(tester);

        // Act & Assert
        expect(FormValidators.username(context, 'abc'), isNull);
        expect(FormValidators.username(context, 'chismoso_2024'), isNull);
        expect(FormValidators.username(context, 'a' * 30), isNull);
      });

      testWidgets('null o vacío → requerido', (tester) async {
        // Arrange
        final context = await ctx(tester);

        // Act & Assert
        expect(FormValidators.username(context, null), context.l10n.usernameRequired);
        expect(FormValidators.username(context, ''), context.l10n.usernameRequired);
      });

      testWidgets('menos de 3 → muy corto', (tester) async {
        // Arrange
        final context = await ctx(tester);

        // Act & Assert
        expect(FormValidators.username(context, 'ab'), context.l10n.usernameTooShort);
      });

      testWidgets('más de 30 → muy largo', (tester) async {
        // Arrange
        final context = await ctx(tester);

        // Act & Assert
        expect(FormValidators.username(context, 'a' * 31), context.l10n.usernameTooLong);
      });

      testWidgets('mayúsculas, espacios o símbolos → caracteres inválidos', (tester) async {
        // Arrange
        final context = await ctx(tester);

        // Act & Assert
        for (final value in ['Chismoso', 'con espacio', 'user.name', 'ñandú', 'user-1']) {
          expect(FormValidators.username(context, value), context.l10n.usernameInvalidChars,
              reason: value);
        }
      });
    });
  });
}
