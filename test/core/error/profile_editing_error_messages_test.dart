import 'package:chismes/core/error/error_codes.dart';
import 'package:chismes/core/error/error_messages.dart';
import 'package:chismes/core/error/failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_l10n_helper.dart';

/// Códigos y mensajes de Editar perfil (update-profile)
void main() {
  group('UsernameCooldownFailure', () {
    test('usa el código usernameChangeCooldown por defecto', () {
      // Act
      const failure = UsernameCooldownFailure();

      // Assert
      expect(failure.code, ErrorCode.usernameChangeCooldown);
      expect(failure.availableAt, isNull);
    });

    test('igualdad incluye la fecha', () {
      // Arrange
      final at = DateTime.utc(2026, 12, 20);

      // Assert
      expect(UsernameCooldownFailure(availableAt: at), UsernameCooldownFailure(availableAt: at));
      expect(UsernameCooldownFailure(availableAt: at), isNot(const UsernameCooldownFailure()));
    });
  });

  group('ErrorMessages (editar perfil)', () {
    setUpAll(TestWidgetsFlutterBinding.ensureInitialized);

    testWidgets('getMessage de los códigos nuevos (es)', (tester) async {
      await withL10nContext(tester, (context) {
        // Act & Assert
        expect(ErrorMessages.getMessage(context, ErrorCode.usernameChangeCooldown),
            'Ya cambiaste tu usuario hace poco. Podrás cambiarlo de nuevo en unos días.');
        expect(ErrorMessages.getMessage(context, ErrorCode.usernameReserved),
            'Ese nombre de usuario no está disponible.');
        expect(ErrorMessages.getMessage(context, ErrorCode.moderationUnavailable),
            'No pudimos revisar el cambio ahora. Intenta de nuevo en unos minutos.');
        expect(ErrorMessages.getMessage(context, ErrorCode.invalidImage),
            'La foto debe ser JPG, PNG o WebP.');
        return null;
      });
    });

    testWidgets('getTitle de los códigos nuevos es el general', (tester) async {
      await withL10nContext(tester, (context) {
        final general = ErrorMessages.getTitle(context, ErrorCode.rateLimitExceeded);

        for (final code in [
          ErrorCode.usernameChangeCooldown,
          ErrorCode.usernameReserved,
          ErrorCode.moderationUnavailable,
          ErrorCode.invalidImage,
        ]) {
          expect(ErrorMessages.getTitle(context, code), general, reason: '$code');
        }
        return null;
      });
    });

    testWidgets('forFailure de cooldown con fecha muestra el día', (tester) async {
      await withL10nContext(tester, (context) {
        // Arrange
        final at = DateTime(2026, 12, 20, 12);
        final failure = UsernameCooldownFailure(availableAt: at);
        final date = MaterialLocalizations.of(context).formatMediumDate(at);

        // Act
        final message = ErrorMessages.forFailure(context, failure);

        // Assert
        expect(message, 'Ya cambiaste tu usuario hace poco. Podrás cambiarlo de nuevo el $date.');
        return null;
      });
    });

    testWidgets('forFailure de cooldown sin fecha usa el mensaje genérico', (tester) async {
      await withL10nContext(tester, (context) {
        // Act
        final message = ErrorMessages.forFailure(context, const UsernameCooldownFailure());

        // Assert
        expect(message, ErrorMessages.getMessage(context, ErrorCode.usernameChangeCooldown));
        return null;
      });
    });

    testWidgets('mensajes en inglés', (tester) async {
      await withL10nContext(
        tester,
        (context) {
          for (final code in [
            ErrorCode.usernameChangeCooldown,
            ErrorCode.usernameReserved,
            ErrorCode.moderationUnavailable,
            ErrorCode.invalidImage,
          ]) {
            expect(ErrorMessages.getMessage(context, code), isNotEmpty);
          }
          final at = DateTime(2026, 12, 20, 12);
          expect(
            ErrorMessages.forFailure(context, UsernameCooldownFailure(availableAt: at)),
            contains(MaterialLocalizations.of(context).formatMediumDate(at)),
          );
          return null;
        },
        locale: const Locale('en'),
      );
    });
  });
}
