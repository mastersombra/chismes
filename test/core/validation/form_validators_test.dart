import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/validation/form_validators.dart';
import '../../helpers/easy_localization_test_helper.dart';

void main() {
  group('FormValidators', () {
    group('required', () {
      testWidgets('debe retornar null cuando el valor no es null ni vacío', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.required('valor válido', 'campo');
        expect(result, isNull);
      });

      testWidgets('debe retornar error cuando el valor es null', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.required(null, 'un país');
        expect(result, 'Selecciona un país');
      });

      testWidgets('debe retornar error cuando el valor está vacío', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.required('', 'una ciudad');
        expect(result, 'Selecciona una ciudad');
      });

      testWidgets('debe retornar error cuando el valor solo contiene espacios', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.required('   ', 'una opción');
        expect(result, isNull); // Espacios no son considerados vacíos
      });

      testWidgets('debe usar el nombre del campo en el mensaje de error', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.required(null, 'tu nombre');
        final result2 = FormValidators.required('', 'el email');
        final result3 = FormValidators.required(null, 'la dirección');

        expect(result1, 'Selecciona tu nombre');
        expect(result2, 'Selecciona el email');
        expect(result3, 'Selecciona la dirección');
      });

      testWidgets('debe funcionar con texto con caracteres especiales', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.required('Texto con ñ y á', 'campo');
        expect(result, isNull);
      });

      testWidgets('debe funcionar con números como string', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.required('123', 'campo');
        expect(result, isNull);
      });
    });

    group('requiredWithMessage', () {
      testWidgets('debe retornar null cuando el valor no es null ni vacío', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.requiredWithMessage('valor', 'Error personalizado');
        expect(result, isNull);
      });

      testWidgets('debe retornar el mensaje personalizado cuando el valor es null', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.requiredWithMessage(null, 'Este campo es obligatorio');
        expect(result, 'Este campo es obligatorio');
      });

      testWidgets('debe retornar el mensaje personalizado cuando el valor está vacío', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.requiredWithMessage('', 'Debes completar este campo');
        expect(result, 'Debes completar este campo');
      });

      testWidgets('debe usar el mensaje exacto proporcionado', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final customMessage = 'Por favor, ingresa tu información';
        final result = FormValidators.requiredWithMessage('', customMessage);
        expect(result, customMessage);
      });

      testWidgets('debe permitir mensajes multiidioma', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.requiredWithMessage('', 'This field is required');
        final result2 = FormValidators.requiredWithMessage('', 'Este campo es requerido');
        final result3 = FormValidators.requiredWithMessage('', 'Ce champ est requis');

        expect(result1, 'This field is required');
        expect(result2, 'Este campo es requerido');
        expect(result3, 'Ce champ est requis');
      });

      testWidgets('debe funcionar con mensajes largos', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final longMessage = 'Este es un mensaje de error muy largo que explica en detalle por qué el campo es requerido';
        final result = FormValidators.requiredWithMessage(null, longMessage);
        expect(result, longMessage);
      });
    });

    group('minLength', () {
      testWidgets('debe retornar null cuando el valor cumple con la longitud mínima', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.minLength('12345', 5);
        expect(result, isNull);
      });

      testWidgets('debe retornar null cuando el valor excede la longitud mínima', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.minLength('123456', 5);
        expect(result, isNull);
      });

      testWidgets('debe retornar null cuando el valor es null', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.minLength(null, 5);
        expect(result, isNull);
      });

      testWidgets('debe retornar error cuando el valor es más corto que minChars', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.minLength('1234', 5);
        expect(result, 'Debe tener al menos 5 caracteres');
      });

      testWidgets('debe retornar error cuando el valor está vacío', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.minLength('', 5);
        expect(result, 'Debe tener al menos 5 caracteres');
      });

      testWidgets('debe usar el número correcto en el mensaje de error', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.minLength('ab', 3);
        final result2 = FormValidators.minLength('1234', 10);
        final result3 = FormValidators.minLength('x', 8);

        expect(result1, 'Debe tener al menos 3 caracteres');
        expect(result2, 'Debe tener al menos 10 caracteres');
        expect(result3, 'Debe tener al menos 8 caracteres');
      });

      testWidgets('debe contar caracteres Unicode correctamente', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.minLength('😀😀😀', 3);
        final result2 = FormValidators.minLength('ñáéíóú', 6);

        expect(result1, isNull);
        expect(result2, isNull);
      });

      testWidgets('debe funcionar con minLength de 1', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.minLength('a', 1);
        final result2 = FormValidators.minLength('', 1);

        expect(result1, isNull);
        expect(result2, 'Debe tener al menos 1 caracteres');
      });

      testWidgets('debe contar espacios como caracteres', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.minLength('   ', 3);
        expect(result, isNull);
      });
    });

    group('maxLength', () {
      testWidgets('debe retornar null cuando el valor está dentro del límite', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.maxLength('12345', 10);
        expect(result, isNull);
      });

      testWidgets('debe retornar null cuando el valor alcanza exactamente el límite', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.maxLength('12345', 5);
        expect(result, isNull);
      });

      testWidgets('debe retornar null cuando el valor es null', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.maxLength(null, 10);
        expect(result, isNull);
      });

      testWidgets('debe retornar error cuando el valor excede maxChars', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.maxLength('123456', 5);
        expect(result, 'No puede exceder 5 caracteres');
      });

      testWidgets('debe usar el número correcto en el mensaje de error', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.maxLength('abcdef', 5);
        final result2 = FormValidators.maxLength('texto muy largo', 10);
        final result3 = FormValidators.maxLength('demasiado', 3);

        expect(result1, 'No puede exceder 5 caracteres');
        expect(result2, 'No puede exceder 10 caracteres');
        expect(result3, 'No puede exceder 3 caracteres');
      });

      testWidgets('debe contar caracteres Unicode correctamente', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.maxLength('😀😀😀😀', 3);
        final result2 = FormValidators.maxLength('ñáéíóú', 5);

        expect(result1, 'No puede exceder 3 caracteres');
        expect(result2, 'No puede exceder 5 caracteres');
      });

      testWidgets('debe permitir strings vacíos', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.maxLength('', 5);
        expect(result, isNull);
      });

      testWidgets('debe funcionar con maxLength de 1', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.maxLength('a', 1);
        final result2 = FormValidators.maxLength('ab', 1);

        expect(result1, isNull);
        expect(result2, 'No puede exceder 1 caracteres');
      });

      testWidgets('debe contar espacios como caracteres', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.maxLength('      ', 5);
        expect(result, 'No puede exceder 5 caracteres');
      });
    });

    group('email', () {
      testWidgets('debe retornar null para emails válidos simples', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.email('test@example.com');
        final result2 = FormValidators.email('user@domain.org');
        final result3 = FormValidators.email('admin@site.net');

        expect(result1, isNull);
        expect(result2, isNull);
        expect(result3, isNull);
      });

      testWidgets('debe retornar null para emails con guiones y puntos', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.email('test.user@example.com');
        final result2 = FormValidators.email('user-name@domain.org');
        final result3 = FormValidators.email('first.last@my-site.com');

        expect(result1, isNull);
        expect(result2, isNull);
        expect(result3, isNull);
      });

      testWidgets('debe retornar null para emails con guiones bajos', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.email('test_user@example.com');
        expect(result, isNull);
      });

      testWidgets('debe retornar null para emails con números', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.email('user123@example456.com');
        expect(result, isNull);
      });

      testWidgets('debe retornar error cuando el valor es null', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.email(null);
        expect(result, 'Ingresa un email');
      });

      testWidgets('debe retornar error cuando el valor está vacío', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.email('');
        expect(result, 'Ingresa un email');
      });

      testWidgets('debe retornar error para emails sin @', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.email('testexample.com');
        expect(result, 'Email inválido');
      });

      testWidgets('debe retornar error para emails sin dominio', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.email('test@');
        expect(result, 'Email inválido');
      });

      testWidgets('debe retornar error para emails sin nombre de usuario', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.email('@example.com');
        expect(result, 'Email inválido');
      });

      testWidgets('debe retornar error para emails sin extensión', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.email('test@example');
        expect(result, 'Email inválido');
      });

      testWidgets('debe retornar error para emails con espacios', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.email('test @example.com');
        final result2 = FormValidators.email('test@ example.com');
        final result3 = FormValidators.email('test@example .com');

        expect(result1, 'Email inválido');
        expect(result2, 'Email inválido');
        expect(result3, 'Email inválido');
      });

      testWidgets('debe retornar error para emails con múltiples @', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result = FormValidators.email('test@@example.com');
        expect(result, 'Email inválido');
      });

      testWidgets('debe retornar error para emails inválidos comunes', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.email('plaintext');
        final result2 = FormValidators.email('missing@domain');
        final result3 = FormValidators.email('@nodomain.com');
        final result4 = FormValidators.email('no@domain@example.com');

        expect(result1, 'Email inválido');
        expect(result2, 'Email inválido');
        expect(result3, 'Email inválido');
        expect(result4, 'Email inválido');
      });

      testWidgets('debe validar extensiones de dominio de diferentes longitudes', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.email('test@example.co');
        final result2 = FormValidators.email('test@example.com');
        final result3 = FormValidators.email('test@example.info');

        expect(result1, isNull);
        expect(result2, isNull);
        expect(result3, isNull);
      });

      testWidgets('debe validar subdominios', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final result1 = FormValidators.email('test@mail.example.com');
        final result2 = FormValidators.email('user@subdomain.domain.org');

        expect(result1, isNull);
        expect(result2, isNull);
      });
    });

    group('Combinación de validadores', () {
      testWidgets('required y minLength pueden usarse juntos conceptualmente', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final value = 'test';

        final requiredResult = FormValidators.required(value, 'campo');
        final minLengthResult = FormValidators.minLength(value, 3);

        expect(requiredResult, isNull);
        expect(minLengthResult, isNull);
      });

      testWidgets('minLength y maxLength pueden validar el mismo valor', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final value = '12345';

        final minResult = FormValidators.minLength(value, 3);
        final maxResult = FormValidators.maxLength(value, 10);

        expect(minResult, isNull);
        expect(maxResult, isNull);
      });

      testWidgets('email puede fallar mientras required pasa', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final value = 'not-an-email';

        final requiredResult = FormValidators.required(value, 'email');
        final emailResult = FormValidators.email(value);

        expect(requiredResult, isNull);
        expect(emailResult, 'Email inválido');
      });
    });

    group('Casos edge', () {
      testWidgets('debe manejar strings muy largos', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final longString = 'a' * 1000;

        final minResult = FormValidators.minLength(longString, 100);
        final maxResult = FormValidators.maxLength(longString, 500);

        expect(minResult, isNull);
        expect(maxResult, 'No puede exceder 500 caracteres');
      });

      testWidgets('debe manejar caracteres especiales en todos los validadores', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

        expect(FormValidators.required(specialChars, 'campo'), isNull);
        expect(FormValidators.minLength(specialChars, 10), isNull);
        expect(FormValidators.maxLength(specialChars, 50), isNull);
      });

      testWidgets('debe manejar emojis en todos los validadores', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final emojis = '😀😃😄😁';

        expect(FormValidators.required(emojis, 'campo'), isNull);
        expect(FormValidators.minLength(emojis, 3), isNull);
        expect(FormValidators.maxLength(emojis, 10), isNull);
      });

      testWidgets('debe manejar saltos de línea', (tester) async {
        await initializeEasyLocalizationForTest(tester);
        final multiline = 'línea1\nlínea2\nlínea3';

        expect(FormValidators.required(multiline, 'campo'), isNull);
        expect(FormValidators.minLength(multiline, 10), isNull);
      });
    });
  });
}
