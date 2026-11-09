import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/error/error_messages.dart';
import 'package:chismes/core/error/error_codes.dart';

import '../../helpers/easy_localization_test_helper.dart';

/// Tests de ErrorMessages
///
/// Estos tests verifican que ErrorMessages retorna mensajes válidos
/// para todos los códigos de error con i18n correctamente configurado.
void main() {
  group('ErrorMessages', () {
    // Inicializar EasyLocalization antes de todos los tests
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    testWidgets('debe estar inicializado EasyLocalization', (tester) async {
      await initializeEasyLocalizationForTest(tester);
    });
    group('getMessage', () {
      testWidgets('debe retornar mensaje no vacío para todos los ErrorCodes',
          (tester) async {
        await initializeEasyLocalizationForTest(tester);

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

      testWidgets('debe aceptar parámetros opcionales', (tester) async {
        await initializeEasyLocalizationForTest(tester);

        final messageWithoutParams =
            ErrorMessages.getMessage(ErrorCode.tooManyRequests);
        final messageWithParams = ErrorMessages.getMessage(
          ErrorCode.tooManyRequests,
          params: {'message': 'Custom message'},
        );

        expect(messageWithoutParams.isNotEmpty, isTrue);
        expect(messageWithParams, 'Custom message');
      });

      testWidgets('rateLimitExceeded debe aceptar parámetros opcionales',
          (tester) async {
        await initializeEasyLocalizationForTest(tester);

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
      testWidgets('debe retornar título no vacío para todos los ErrorCodes',
          (tester) async {
        await initializeEasyLocalizationForTest(tester);

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

      testWidgets('errores relacionados deben tener títulos consistentes',
          (tester) async {
        await initializeEasyLocalizationForTest(tester);

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
