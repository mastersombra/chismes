import 'package:chismes/features/profile/presentation/widgets/delete_account_dialog.dart';
import 'package:chismes/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  late bool? result;

  Future<AppLocalizations> openDialog(WidgetTester tester) async {
    result = null;
    await tester.pumpWidget(testableWidget(
      child: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => result = await DeleteAccountDialog.show(context),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(DeleteAccountDialog)))!;
  }

  FilledButton confirmButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byKey(const Key('deleteAccountConfirmButton')));

  testWidgets('explica qué se borra y qué se conserva', (tester) async {
    final l10n = await openDialog(tester);

    expect(find.text(l10n.profileDeleteAccountDialogTitle), findsOneWidget);
    expect(find.text(l10n.profileDeleteAccountDialogContent), findsOneWidget);
    expect(find.text(l10n.profileDeleteAccountDialogRetention), findsOneWidget);
    expect(
      find.text(l10n.profileDeleteAccountConfirmLabel(l10n.profileDeleteAccountConfirmWord)),
      findsOneWidget,
    );
  });

  testWidgets('el botón está deshabilitado hasta escribir la palabra exacta', (tester) async {
    final l10n = await openDialog(tester);
    final field = find.byKey(const Key('deleteAccountConfirmField'));

    expect(confirmButton(tester).onPressed, isNull);

    await tester.enterText(field, 'ELIMIN');
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNull);

    // Sin importar mayúsculas ni espacios alrededor
    await tester.enterText(field, '  ${l10n.profileDeleteAccountConfirmWord.toLowerCase()} ');
    await tester.pump();
    expect(confirmButton(tester).onPressed, isNotNull);
  });

  testWidgets('confirmar devuelve true', (tester) async {
    final l10n = await openDialog(tester);

    await tester.enterText(
      find.byKey(const Key('deleteAccountConfirmField')),
      l10n.profileDeleteAccountConfirmWord,
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('deleteAccountConfirmButton')));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.byType(DeleteAccountDialog), findsNothing);
  });

  testWidgets('cancelar devuelve false', (tester) async {
    final l10n = await openDialog(tester);

    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('cerrar tocando fuera devuelve false', (tester) async {
    await openDialog(tester);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });
}
