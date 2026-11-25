import 'dart:convert';

import 'package:chismes/core/legal/legal_consent_text.dart';
import 'package:chismes/core/legal/legal_document.dart';
import 'package:chismes/core/legal/legal_document_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_wrapper.dart';

class _FakeBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode('# $key')));
}

void main() {
  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('es')}) =>
      tester.pumpWidget(testableWidget(
        locale: locale,
        child: DefaultAssetBundle(
          bundle: _FakeBundle(),
          child: const LegalConsentText(),
        ),
      ));

  String plainText(WidgetTester tester) => tester
      .widget<Text>(find.byKey(const Key('legalConsentText')))
      .textSpan!
      .toPlainText();

  testWidgets('frase completa en español, sin marcadores', (tester) async {
    await pump(tester);

    expect(plainText(tester),
        'Al continuar, aceptas los Términos de uso y la Política de privacidad.');
  });

  testWidgets('frase completa en inglés', (tester) async {
    await pump(tester, locale: const Locale('en'));

    expect(plainText(tester),
        'By continuing, you agree to the Terms of use and the Privacy policy.');
  });

  Future<void> tapLink(WidgetTester tester, String label) async {
    final text = tester.widget<Text>(find.byKey(const Key('legalConsentText')));
    final span = (text.textSpan! as TextSpan)
        .children!
        .whereType<TextSpan>()
        .firstWhere((s) => s.text == label);
    (span.recognizer! as TapGestureRecognizer).onTap!();
    await tester.pumpAndSettle();
  }

  testWidgets('tocar "Términos de uso" abre los términos', (tester) async {
    await pump(tester);

    await tapLink(tester, 'Términos de uso');

    final screen =
        tester.widget<LegalDocumentScreen>(find.byType(LegalDocumentScreen));
    expect(screen.document, LegalDocument.termsOfService);
  });

  testWidgets('tocar "Política de privacidad" abre la política',
      (tester) async {
    await pump(tester);

    await tapLink(tester, 'Política de privacidad');

    final screen =
        tester.widget<LegalDocumentScreen>(find.byType(LegalDocumentScreen));
    expect(screen.document, LegalDocument.privacyPolicy);
  });

  testWidgets('libera los recognizers al desmontarse', (tester) async {
    await pump(tester);

    await tester.pumpWidget(const SizedBox());

    expect(tester.takeException(), isNull);
  });
}
