import 'dart:convert';

import 'package:chismes/core/legal/legal_document.dart';
import 'package:chismes/core/legal/legal_document_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/widget_test_wrapper.dart';

/// Bundle en memoria: rutas conocidas devuelven su texto, el resto falla
class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this.files);

  final Map<String, String> files;
  final requested = <String>[];

  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    final text = files[key];
    if (text == null) throw FlutterError('Asset no encontrado: $key');
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));
  }
}

void main() {
  Future<_FakeBundle> pump(
    WidgetTester tester, {
    required LegalDocument document,
    Locale locale = const Locale('es'),
    Map<String, String> files = const {},
  }) async {
    final bundle = _FakeBundle(files);
    await tester.pumpWidget(testableWidget(
      locale: locale,
      useScaffold: false,
      child: DefaultAssetBundle(
        bundle: bundle,
        child: LegalDocumentScreen(document: document),
      ),
    ));
    await tester.pumpAndSettle();
    return bundle;
  }

  testWidgets('muestra la política en español con su título', (tester) async {
    final bundle = await pump(
      tester,
      document: LegalDocument.privacyPolicy,
      files: {
        'assets/legal/privacy_policy.es.md': '# Política\n\n- Dato uno',
      },
    );

    expect(find.text('Política de privacidad'), findsOneWidget); // AppBar
    expect(find.text('Política'), findsOneWidget);
    expect(find.text('Dato uno', findRichText: true), findsOneWidget);
    expect(bundle.requested, ['assets/legal/privacy_policy.es.md']);
  });

  testWidgets('en inglés carga la traducción', (tester) async {
    final bundle = await pump(
      tester,
      document: LegalDocument.termsOfService,
      locale: const Locale('en'),
      files: {'assets/legal/terms_of_service.en.md': '# Terms'},
    );

    expect(find.text('Terms of use'), findsOneWidget);
    expect(find.text('Terms'), findsOneWidget);
    expect(bundle.requested, ['assets/legal/terms_of_service.en.md']);
  });

  testWidgets('si no carga, muestra un error (no se queda cargando)',
      (tester) async {
    await pump(tester, document: LegalDocument.privacyPolicy);

    expect(find.byKey(const Key('legalDocumentError')), findsOneWidget);
    expect(find.text('No se pudo abrir el documento.'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('los assets reales se cargan (pubspec los incluye)',
      (tester) async {
    await tester.pumpWidget(testableWidget(
      useScaffold: false,
      child: const LegalDocumentScreen(document: LegalDocument.termsOfService),
    ));
    await tester.runAsync(() => rootBundle
        .loadString(LegalDocument.termsOfService.assetPath('es')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('legalDocumentError')), findsNothing);
    expect(find.textContaining('Términos de Uso'), findsWidgets);
  });

  testWidgets('open() empuja la pantalla del documento', (tester) async {
    await tester.pumpWidget(testableWidget(
      child: DefaultAssetBundle(
        bundle: _FakeBundle({'assets/legal/privacy_policy.es.md': '# P'}),
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                LegalDocumentScreen.open(context, LegalDocument.privacyPolicy),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.byType(LegalDocumentScreen), findsOneWidget);
  });
}
