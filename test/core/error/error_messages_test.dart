import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/error/error_messages.dart';
import 'package:chismes/core/error/error_codes.dart';

import '../../helpers/test_l10n_helper.dart';

/// Tests de ErrorMessages
///
/// Estos tests verifican que ErrorMessages retorna mensajes válidos
/// para todos los códigos de error con i18n correctamente configurado.
void main() {
  group('ErrorMessages', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    group('getMessage', () {
      testWidgets('debe retornar mensaje no vacío para todos los ErrorCodes',
          (tester) async {
        await withL10nContext(tester, (context) {
          for (final code in ErrorCode.values) {
            final message = ErrorMessages.getMessage(context, code);

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
          return null;
        });
      });

      testWidgets('debe aceptar parámetros opcionales', (tester) async {
        await withL10nContext(tester, (context) {
          final messageWithoutParams =
              ErrorMessages.getMessage(context, ErrorCode.tooManyRequests);
          final messageWithParams = ErrorMessages.getMessage(
            context,
            ErrorCode.tooManyRequests,
            params: {'message': 'Custom message'},
          );

          expect(messageWithoutParams.isNotEmpty, isTrue);
          expect(messageWithParams, 'Custom message');
          return null;
        });
      });

      testWidgets('rateLimitExceeded debe aceptar parámetros opcionales',
          (tester) async {
        await withL10nContext(tester, (context) {
          final messageWithoutParams =
              ErrorMessages.getMessage(context, ErrorCode.rateLimitExceeded);
          final messageWithParams = ErrorMessages.getMessage(
            context,
            ErrorCode.rateLimitExceeded,
            params: {'message': 'Custom rate limit message'},
          );

          expect(messageWithoutParams.isNotEmpty, isTrue);
          expect(messageWithParams, 'Custom rate limit message');
          return null;
        });
      });
    });

    group('getTitle', () {
      testWidgets('debe retornar título no vacío para todos los ErrorCodes',
          (tester) async {
        await withL10nContext(tester, (context) {
          for (final code in ErrorCode.values) {
            final title = ErrorMessages.getTitle(context, code);

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
          return null;
        });
      });

      testWidgets('errores relacionados deben tener títulos consistentes',
          (tester) async {
        await withL10nContext(tester, (context) {
          // Errores de red deben tener el mismo título
          final networkTitle = ErrorMessages.getTitle(context, ErrorCode.networkError);
          final timeoutTitle = ErrorMessages.getTitle(context, ErrorCode.timeoutError);
          final noInternetTitle =
              ErrorMessages.getTitle(context, ErrorCode.noInternetConnection);

          expect(networkTitle, timeoutTitle);
          expect(timeoutTitle, noInternetTitle);

          // Errores de servidor deben tener el mismo título
          final serverErrorTitle = ErrorMessages.getTitle(context, ErrorCode.serverError);
          final maintenanceTitle =
              ErrorMessages.getTitle(context, ErrorCode.serverMaintenance);
          final unavailableTitle =
              ErrorMessages.getTitle(context, ErrorCode.serviceUnavailable);

          expect(serverErrorTitle, maintenanceTitle);
          expect(maintenanceTitle, unavailableTitle);

          // Errores de auth deben tener el mismo título
          final unauthorizedTitle =
              ErrorMessages.getTitle(context, ErrorCode.unauthorized);
          final invalidCredsTitle =
              ErrorMessages.getTitle(context, ErrorCode.invalidCredentials);
          final sessionExpiredTitle =
              ErrorMessages.getTitle(context, ErrorCode.sessionExpired);

          expect(unauthorizedTitle, invalidCredsTitle);
          expect(invalidCredsTitle, sessionExpiredTitle);
          return null;
        });
      });
    });
  });
}
