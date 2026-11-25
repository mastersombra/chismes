import 'dart:convert';

import 'package:chismes/core/legal/legal_document.dart';
import 'package:chismes/core/legal/legal_document_screen.dart';
import 'package:chismes/features/profile/presentation/widgets/legal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_test_wrapper.dart';

class _FakeBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode('# Doc')));
}

void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(testableWidget(
        child: DefaultAssetBundle(bundle: _FakeBundle(), child: const LegalCard()),
      ));

  LegalDocument openedDocument(WidgetTester tester) => tester
      .widget<LegalDocumentScreen>(find.byType(LegalDocumentScreen))
      .document;

  testWidgets('muestra la sección Legal con los dos documentos',
      (tester) async {
    await pump(tester);

    expect(find.text('Legal'), findsOneWidget);
    expect(find.text('Política de privacidad'), findsOneWidget);
    expect(find.text('Términos de uso'), findsOneWidget);
  });

  testWidgets('abre la Política de privacidad', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('legalPrivacyPolicyTile')));
    await tester.pumpAndSettle();

    expect(openedDocument(tester), LegalDocument.privacyPolicy);
  });

  testWidgets('abre los Términos de uso', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('legalTermsOfServiceTile')));
    await tester.pumpAndSettle();

    expect(openedDocument(tester), LegalDocument.termsOfService);
  });
}
