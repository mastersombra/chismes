import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/features/auth/domain/validators/auth_validator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de SEGURIDAD para AuthValidator
///
/// Estos tests verifican que los mensajes de validación:
/// - NO expongan información técnica sensible
/// - NO filtren datos del usuario (contraseñas, emails)
/// - Tengan longitud razonable
void main() {
  group('AuthValidator - Security Tests', () {
    group('validatePassword - Security', () {
      test('mensajes NO revelan la contraseña ingresada', () {
        // Contraseñas débiles con diferentes problemas
        final weakPasswords = [
          'weak123',           // Muy corta
          'ALLUPPERCASE123!',  // Sin minúscula
          'alllowercase123!',  // Sin mayúscula
          'NoNumbers!@#',      // Sin número
          'NoSpecial123A',     // Sin carácter especial
        ];

        for (final password in weakPasswords) {
          final result = AuthValidator.validatePassword(password);

          // CRÍTICO: El mensaje NO debe contener la contraseña
          final msg = result?.technicalMessage ?? '';
          expect(
            msg,
            isNot(contains(password)),
            reason: 'Mensaje NO debe contener contraseña ingresada: $password',
          );

          // Verifica que no contiene palabras que filtran info
          expect(msg.toLowerCase(), isNot(contains('contraseña:')));
          expect(msg.toLowerCase(), isNot(contains('password:')));
          expect(msg.toLowerCase(), isNot(contains('value:')));
        }
      });

      test('mensajes de error son seguros y descriptivos', () {
        // Test cases: (password, expectedCode)
        final testCases = [
          (null, ErrorCode.missingRequiredField),
          ('', ErrorCode.missingRequiredField),
          ('Short1!', ErrorCode.weakPassword),
          ('NOLOW123!', ErrorCode.weakPassword),
          ('noupper123!', ErrorCode.weakPassword),
          ('NoNumbers!@', ErrorCode.weakPassword),
          ('NoSpecial123A', ErrorCode.weakPassword),
          ('A1!${'a' * 126}', ErrorCode.invalidInput),
        ];

        for (final (password, expectedCode) in testCases) {
          final result = AuthValidator.validatePassword(password);

          expect(result?.code, expectedCode);

          // SEGURIDAD: Verifica longitud razonable
          if (result?.technicalMessage != null) {
            expect(
              result!.technicalMessage!.length,
              lessThan(200),
              reason: 'Mensaje debe ser conciso',
            );
          }
        }
      });
    });

    group('validateUsername - Security', () {
      test('mensaje no revela lista de palabras reservadas', () {
        // Intentar username con palabra reservada
        final result = AuthValidator.validateUsername('admin');

        // Debe fallar pero NO debe listar todas las palabras reservadas
        expect(result, isNotNull);
        final msg = result?.technicalMessage ?? '';

        // No debe contener lista completa de palabras reservadas
        expect(msg, isNot(contains('root, admin, superuser')));

        // Mensaje debe ser conciso
        expect(msg.length, lessThan(200));
      });
    });

    group('General Security Compliance', () {
      test('todos los mensajes cumplen con límite de longitud', () {
        // Probar varios validadores
        final validations = [
          AuthValidator.validateEmail('invalid'),
          AuthValidator.validatePassword('weak'),
          AuthValidator.validateUsername('ab'),
        ];

        for (final result in validations.where((r) => r != null)) {
          if (result?.technicalMessage != null) {
            expect(
              result!.technicalMessage!.length,
              lessThan(200),
              reason: 'Mensaje técnico debe ser conciso',
            );
          }
        }
      });
    });
  });
}
