import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/error/error_messages.dart';
import 'package:chismes/core/error/error_codes.dart';

/// Tests de ErrorMessages
///
/// Estos tests verifican que ErrorMessages retorna mensajes válidos
/// para todos los códigos de error, sin depender de strings exactos
/// ya que ahora usa i18n.
///
/// TODO: Los tests antiguos fueron movidos a error_messages_test.dart.deprecated
/// porque esperaban strings hardcodeados en español. Una vez que se configure
/// correctamente EasyLocalization para tests, restaurar esos tests actualizados.
void main() {
  group('ErrorMessages', () {
    group('getMessage', () {
      test('debe retornar mensaje no vacío para todos los ErrorCodes', () {
        for (final code in ErrorCode.values) {
          final message = ErrorMessages.getMessage(code);

          expect(
            message.isNotEmpty,
            isTrue,
            reason: 'ErrorCode.$code debe retornar un mensaje no vacío',
          );

          expect(
            message.length,
            greaterThan(5),
            reason: 'ErrorCode.$code debe retornar un mensaje con contenido',
          );
        }
      });

      test('debe aceptar parámetros opcionales', () {
        final messageWithoutParams =
            ErrorMessages.getMessage(ErrorCode.tooManyRequests);
        final messageWithParams = ErrorMessages.getMessage(
          ErrorCode.tooManyRequests,
          params: {'message': 'Custom message'},
        );

        expect(messageWithoutParams.isNotEmpty, isTrue);
        expect(messageWithParams, 'Custom message');
      });

      test('rateLimitExceeded debe aceptar parámetros opcionales', () {
        final messageWithoutParams =
            ErrorMessages.getMessage(ErrorCode.rateLimitExceeded);
        final messageWithParams = ErrorMessages.getMessage(
          ErrorCode.rateLimitExceeded,
          params: {'message': 'Custom rate limit message'},
        );

        expect(messageWithoutParams.isNotEmpty, isTrue);
        expect(messageWithParams, 'Custom rate limit message');
      });
    });

    group('getTitle', () {
      test('debe retornar título no vacío para todos los ErrorCodes', () {
        for (final code in ErrorCode.values) {
          final title = ErrorMessages.getTitle(code);

          expect(
            title.isNotEmpty,
            isTrue,
            reason: 'ErrorCode.$code debe retornar un título no vacío',
          );

          expect(
            title.length,
            greaterThan(3),
            reason: 'ErrorCode.$code debe retornar un título con contenido',
          );
        }
      });

      test('errores relacionados deben tener títulos consistentes', () {
        // Errores de red deben tener el mismo título
        final networkTitle = ErrorMessages.getTitle(ErrorCode.networkError);
        final timeoutTitle = ErrorMessages.getTitle(ErrorCode.timeoutError);
        final noInternetTitle =
            ErrorMessages.getTitle(ErrorCode.noInternetConnection);

        expect(networkTitle, timeoutTitle);
        expect(timeoutTitle, noInternetTitle);

        // Errores de servidor deben tener el mismo título
        final serverErrorTitle = ErrorMessages.getTitle(ErrorCode.serverError);
        final maintenanceTitle =
            ErrorMessages.getTitle(ErrorCode.serverMaintenance);
        final unavailableTitle =
            ErrorMessages.getTitle(ErrorCode.serviceUnavailable);

        expect(serverErrorTitle, maintenanceTitle);
        expect(maintenanceTitle, unavailableTitle);

        // Errores de auth deben tener el mismo título
        final unauthorizedTitle =
            ErrorMessages.getTitle(ErrorCode.unauthorized);
        final invalidCredsTitle =
            ErrorMessages.getTitle(ErrorCode.invalidCredentials);
        final sessionExpiredTitle =
            ErrorMessages.getTitle(ErrorCode.sessionExpired);

        expect(unauthorizedTitle, invalidCredsTitle);
        expect(invalidCredsTitle, sessionExpiredTitle);
      });
    });
  });
}
