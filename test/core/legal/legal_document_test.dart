import 'dart:io';

import 'package:chismes/core/legal/legal_document.dart';
import 'package:chismes/core/widgets/simple_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// Versión del encabezado "**Versión:** X.Y" / "**Version:** X.Y"
String? _headerVersion(String markdown) => RegExp(
      r'^\*\*Versi[oó]n:\*\*\s*([0-9]+\.[0-9]+)',
      multiLine: true,
    ).firstMatch(markdown)?.group(1);

void main() {
  group('LegalDocument.assetPath', () {
    test('usa el idioma si tiene traducción', () {
      expect(LegalDocument.privacyPolicy.assetPath('es'),
          'assets/legal/privacy_policy.es.md');
      expect(LegalDocument.termsOfService.assetPath('en'),
          'assets/legal/terms_of_service.en.md');
    });

    test('otro idioma → español (la versión que prevalece)', () {
      expect(LegalDocument.privacyPolicy.assetPath('pt'),
          'assets/legal/privacy_policy.es.md');
    });
  });

  // Guardas contra desincronización: los textos, sus traducciones y la versión
  // que el servidor registra al crear la cuenta deben ir juntos.
  group('assets/legal (sincronización)', () {
    final migration =
        File('supabase/migrations/016_policy_acceptances.sql').readAsStringSync();

    for (final document in LegalDocument.values) {
      group(document.name, () {
        final texts = {
          for (final language in LegalDocument.supportedLanguages)
            language: File(document.assetPath(language)).readAsStringSync(),
        };

        test('existe en cada idioma y lo entiende el renderer', () {
          for (final entry in texts.entries) {
            final blocks = parseMarkdown(entry.value);
            expect(blocks.first.type, MarkdownBlockType.heading,
                reason: '${entry.key}: debe empezar con el título');
            expect(blocks.length, greaterThan(50), reason: entry.key);
          }
        });

        test('todas las traducciones tienen la misma versión', () {
          final versions = texts.map((k, v) => MapEntry(k, _headerVersion(v)));
          expect(versions.values.toSet(), hasLength(1),
              reason: 'Versiones por idioma: $versions');
          expect(versions.values.first, isNotNull);
        });

        test('la versión coincide con legal_documents (migración 016)', () {
          final version = _headerVersion(texts['es']!);
          expect(
            migration,
            contains("('${document.assetName}', '$version')"),
            reason: 'Al subir la versión del documento, subirla también en '
                'legal_documents con una migración nueva',
          );
        });

        test('mismo número de secciones en cada idioma', () {
          final counts = texts.map((k, v) => MapEntry(
                k,
                parseMarkdown(v)
                    .where((b) => b.type == MarkdownBlockType.heading)
                    .length,
              ));
          expect(counts.values.toSet(), hasLength(1), reason: '$counts');
        });
      });
    }
  });
}
