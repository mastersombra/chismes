import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/validation/form_validators.dart';

void main() {
  group('FormValidators', () {
    group('required', () {
      test('debe retornar null cuando el valor no es null ni vacío', () {
        final result = FormValidators.required('valor válido', 'campo');
        expect(result, isNull);
      });

      test('debe retornar error cuando el valor es null', () {
        final result = FormValidators.required(null, 'un país');
        expect(result, 'Selecciona un país');
      });

      test('debe retornar error cuando el valor está vacío', () {
        final result = FormValidators.required('', 'una ciudad');
        expect(result, 'Selecciona una ciudad');
      });

      test('debe retornar error cuando el valor solo contiene espacios', () {
        final result = FormValidators.required('   ', 'una opción');
        expect(result, isNull); // Espacios no son considerados vacíos
      });

      test('debe usar el nombre del campo en el mensaje de error', () {
        final result1 = FormValidators.required(null, 'tu nombre');
        final result2 = FormValidators.required('', 'el email');
        final result3 = FormValidators.required(null, 'la dirección');

        expect(result1, 'Selecciona tu nombre');
        expect(result2, 'Selecciona el email');
        expect(result3, 'Selecciona la dirección');
      });

      test('debe funcionar con texto con caracteres especiales', () {
        final result = FormValidators.required('Texto con ñ y á', 'campo');
        expect(result, isNull);
      });

      test('debe funcionar con números como string', () {
        final result = FormValidators.required('123', 'campo');
        expect(result, isNull);
      });
    });

    group('requiredWithMessage', () {
      test('debe retornar null cuando el valor no es null ni vacío', () {
        final result = FormValidators.requiredWithMessage('valor', 'Error personalizado');
        expect(result, isNull);
      });

      test('debe retornar el mensaje personalizado cuando el valor es null', () {
        final result = FormValidators.requiredWithMessage(null, 'Este campo es obligatorio');
        expect(result, 'Este campo es obligatorio');
      });

      test('debe retornar el mensaje personalizado cuando el valor está vacío', () {
        final result = FormValidators.requiredWithMessage('', 'Debes completar este campo');
        expect(result, 'Debes completar este campo');
      });

      test('debe usar el mensaje exacto proporcionado', () {
        final customMessage = 'Por favor, ingresa tu información';
        final result = FormValidators.requiredWithMessage('', customMessage);
        expect(result, customMessage);
      });

      test('debe permitir mensajes multiidioma', () {
        final result1 = FormValidators.requiredWithMessage('', 'This field is required');
        final result2 = FormValidators.requiredWithMessage('', 'Este campo es requerido');
        final result3 = FormValidators.requiredWithMessage('', 'Ce champ est requis');

        expect(result1, 'This field is required');
        expect(result2, 'Este campo es requerido');
        expect(result3, 'Ce champ est requis');
      });

      test('debe funcionar con mensajes largos', () {
        final longMessage = 'Este es un mensaje de error muy largo que explica en detalle por qué el campo es requerido';
        final result = FormValidators.requiredWithMessage(null, longMessage);
        expect(result, longMessage);
      });
    });

    group('minLength', () {
      test('debe retornar null cuando el valor cumple con la longitud mínima', () {
        final result = FormValidators.minLength('12345', 5);
        expect(result, isNull);
      });

      test('debe retornar null cuando el valor excede la longitud mínima', () {
        final result = FormValidators.minLength('123456', 5);
        expect(result, isNull);
      });

      test('debe retornar null cuando el valor es null', () {
        final result = FormValidators.minLength(null, 5);
        expect(result, isNull);
      });

      test('debe retornar error cuando el valor es más corto que minChars', () {
        final result = FormValidators.minLength('1234', 5);
        expect(result, 'Debe tener al menos 5 caracteres');
      });

      test('debe retornar error cuando el valor está vacío', () {
        final result = FormValidators.minLength('', 5);
        expect(result, 'Debe tener al menos 5 caracteres');
      });

      test('debe usar el número correcto en el mensaje de error', () {
        final result1 = FormValidators.minLength('ab', 3);
        final result2 = FormValidators.minLength('1234', 10);
        final result3 = FormValidators.minLength('x', 8);

        expect(result1, 'Debe tener al menos 3 caracteres');
        expect(result2, 'Debe tener al menos 10 caracteres');
        expect(result3, 'Debe tener al menos 8 caracteres');
      });

      test('debe contar caracteres Unicode correctamente', () {
        final result1 = FormValidators.minLength('😀😀😀', 3);
        final result2 = FormValidators.minLength('ñáéíóú', 6);

        expect(result1, isNull);
        expect(result2, isNull);
      });

      test('debe funcionar con minLength de 1', () {
        final result1 = FormValidators.minLength('a', 1);
        final result2 = FormValidators.minLength('', 1);

        expect(result1, isNull);
        expect(result2, 'Debe tener al menos 1 caracteres');
      });

      test('debe contar espacios como caracteres', () {
        final result = FormValidators.minLength('   ', 3);
        expect(result, isNull);
      });
    });

    group('maxLength', () {
      test('debe retornar null cuando el valor está dentro del límite', () {
        final result = FormValidators.maxLength('12345', 10);
        expect(result, isNull);
      });

      test('debe retornar null cuando el valor alcanza exactamente el límite', () {
        final result = FormValidators.maxLength('12345', 5);
        expect(result, isNull);
      });

      test('debe retornar null cuando el valor es null', () {
        final result = FormValidators.maxLength(null, 10);
        expect(result, isNull);
      });

      test('debe retornar error cuando el valor excede maxChars', () {
        final result = FormValidators.maxLength('123456', 5);
        expect(result, 'No puede exceder 5 caracteres');
      });

      test('debe usar el número correcto en el mensaje de error', () {
        final result1 = FormValidators.maxLength('abcdef', 5);
        final result2 = FormValidators.maxLength('texto muy largo', 10);
        final result3 = FormValidators.maxLength('demasiado', 3);

        expect(result1, 'No puede exceder 5 caracteres');
        expect(result2, 'No puede exceder 10 caracteres');
        expect(result3, 'No puede exceder 3 caracteres');
      });

      test('debe contar caracteres Unicode correctamente', () {
        final result1 = FormValidators.maxLength('😀😀😀😀', 3);
        final result2 = FormValidators.maxLength('ñáéíóú', 5);

        expect(result1, 'No puede exceder 3 caracteres');
        expect(result2, 'No puede exceder 5 caracteres');
      });

      test('debe permitir strings vacíos', () {
        final result = FormValidators.maxLength('', 5);
        expect(result, isNull);
      });

      test('debe funcionar con maxLength de 1', () {
        final result1 = FormValidators.maxLength('a', 1);
        final result2 = FormValidators.maxLength('ab', 1);

        expect(result1, isNull);
        expect(result2, 'No puede exceder 1 caracteres');
      });

      test('debe contar espacios como caracteres', () {
        final result = FormValidators.maxLength('      ', 5);
        expect(result, 'No puede exceder 5 caracteres');
      });
    });

    group('email', () {
      test('debe retornar null para emails válidos simples', () {
        final result1 = FormValidators.email('test@example.com');
        final result2 = FormValidators.email('user@domain.org');
        final result3 = FormValidators.email('admin@site.net');

        expect(result1, isNull);
        expect(result2, isNull);
        expect(result3, isNull);
      });

      test('debe retornar null para emails con guiones y puntos', () {
        final result1 = FormValidators.email('test.user@example.com');
        final result2 = FormValidators.email('user-name@domain.org');
        final result3 = FormValidators.email('first.last@my-site.com');

        expect(result1, isNull);
        expect(result2, isNull);
        expect(result3, isNull);
      });

      test('debe retornar null para emails con guiones bajos', () {
        final result = FormValidators.email('test_user@example.com');
        expect(result, isNull);
      });

      test('debe retornar null para emails con números', () {
        final result = FormValidators.email('user123@example456.com');
        expect(result, isNull);
      });

      test('debe retornar error cuando el valor es null', () {
        final result = FormValidators.email(null);
        expect(result, 'Ingresa un email');
      });

      test('debe retornar error cuando el valor está vacío', () {
        final result = FormValidators.email('');
        expect(result, 'Ingresa un email');
      });

      test('debe retornar error para emails sin @', () {
        final result = FormValidators.email('testexample.com');
        expect(result, 'Email inválido');
      });

      test('debe retornar error para emails sin dominio', () {
        final result = FormValidators.email('test@');
        expect(result, 'Email inválido');
      });

      test('debe retornar error para emails sin nombre de usuario', () {
        final result = FormValidators.email('@example.com');
        expect(result, 'Email inválido');
      });

      test('debe retornar error para emails sin extensión', () {
        final result = FormValidators.email('test@example');
        expect(result, 'Email inválido');
      });

      test('debe retornar error para emails con espacios', () {
        final result1 = FormValidators.email('test @example.com');
        final result2 = FormValidators.email('test@ example.com');
        final result3 = FormValidators.email('test@example .com');

        expect(result1, 'Email inválido');
        expect(result2, 'Email inválido');
        expect(result3, 'Email inválido');
      });

      test('debe retornar error para emails con múltiples @', () {
        final result = FormValidators.email('test@@example.com');
        expect(result, 'Email inválido');
      });

      test('debe retornar error para emails inválidos comunes', () {
        final result1 = FormValidators.email('plaintext');
        final result2 = FormValidators.email('missing@domain');
        final result3 = FormValidators.email('@nodomain.com');
        final result4 = FormValidators.email('no@domain@example.com');

        expect(result1, 'Email inválido');
        expect(result2, 'Email inválido');
        expect(result3, 'Email inválido');
        expect(result4, 'Email inválido');
      });

      test('debe validar extensiones de dominio de diferentes longitudes', () {
        final result1 = FormValidators.email('test@example.co');
        final result2 = FormValidators.email('test@example.com');
        final result3 = FormValidators.email('test@example.info');

        expect(result1, isNull);
        expect(result2, isNull);
        expect(result3, isNull);
      });

      test('debe validar subdominios', () {
        final result1 = FormValidators.email('test@mail.example.com');
        final result2 = FormValidators.email('user@subdomain.domain.org');

        expect(result1, isNull);
        expect(result2, isNull);
      });
    });

    group('Combinación de validadores', () {
      test('required y minLength pueden usarse juntos conceptualmente', () {
        final value = 'test';

        final requiredResult = FormValidators.required(value, 'campo');
        final minLengthResult = FormValidators.minLength(value, 3);

        expect(requiredResult, isNull);
        expect(minLengthResult, isNull);
      });

      test('minLength y maxLength pueden validar el mismo valor', () {
        final value = '12345';

        final minResult = FormValidators.minLength(value, 3);
        final maxResult = FormValidators.maxLength(value, 10);

        expect(minResult, isNull);
        expect(maxResult, isNull);
      });

      test('email puede fallar mientras required pasa', () {
        final value = 'not-an-email';

        final requiredResult = FormValidators.required(value, 'email');
        final emailResult = FormValidators.email(value);

        expect(requiredResult, isNull);
        expect(emailResult, 'Email inválido');
      });
    });

    group('Casos edge', () {
      test('debe manejar strings muy largos', () {
        final longString = 'a' * 1000;

        final minResult = FormValidators.minLength(longString, 100);
        final maxResult = FormValidators.maxLength(longString, 500);

        expect(minResult, isNull);
        expect(maxResult, 'No puede exceder 500 caracteres');
      });

      test('debe manejar caracteres especiales en todos los validadores', () {
        final specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

        expect(FormValidators.required(specialChars, 'campo'), isNull);
        expect(FormValidators.minLength(specialChars, 10), isNull);
        expect(FormValidators.maxLength(specialChars, 50), isNull);
      });

      test('debe manejar emojis en todos los validadores', () {
        final emojis = '😀😃😄😁';

        expect(FormValidators.required(emojis, 'campo'), isNull);
        expect(FormValidators.minLength(emojis, 3), isNull);
        expect(FormValidators.maxLength(emojis, 10), isNull);
      });

      test('debe manejar saltos de línea', () {
        final multiline = 'línea1\nlínea2\nlínea3';

        expect(FormValidators.required(multiline, 'campo'), isNull);
        expect(FormValidators.minLength(multiline, 10), isNull);
      });
    });
  });
}
