import 'package:chismes/core/widgets/simple_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMarkdown', () {
    test('títulos de nivel 1 a 3 (4+ cuenta como 3)', () {
      final blocks = parseMarkdown('# Uno\n## Dos\n### Tres\n#### Cuatro');

      expect(blocks, const [
        MarkdownBlock(MarkdownBlockType.heading, text: 'Uno', level: 1),
        MarkdownBlock(MarkdownBlockType.heading, text: 'Dos', level: 2),
        MarkdownBlock(MarkdownBlockType.heading, text: 'Tres', level: 3),
        MarkdownBlock(MarkdownBlockType.heading, text: 'Cuatro', level: 3),
      ]);
    });

    test('une líneas de un párrafo y separa por línea en blanco', () {
      final blocks = parseMarkdown('Hola\nmundo\n\nOtro párrafo');

      expect(blocks, const [
        MarkdownBlock(MarkdownBlockType.paragraph, text: 'Hola mundo'),
        MarkdownBlock(MarkdownBlockType.paragraph, text: 'Otro párrafo'),
      ]);
    });

    test('dos espacios al final de la línea = salto de línea', () {
      final blocks = parseMarkdown('**Fecha:** hoy  \n**Versión:** 1.0');

      expect(blocks.single.text, '**Fecha:** hoy\n**Versión:** 1.0');
    });

    test('viñetas con sub-niveles y listas numeradas', () {
      final blocks = parseMarkdown('- Uno\n  - Sub\n* Dos\n1. Primero\n  2. Sub');

      expect(blocks, const [
        MarkdownBlock(MarkdownBlockType.bullet, text: 'Uno'),
        MarkdownBlock(MarkdownBlockType.bullet, text: 'Sub', level: 1),
        MarkdownBlock(MarkdownBlockType.bullet, text: 'Dos'),
        MarkdownBlock(MarkdownBlockType.numbered, text: 'Primero', number: '1'),
        MarkdownBlock(MarkdownBlockType.numbered,
            text: 'Sub', level: 1, number: '2'),
      ]);
    });

    test('separadores ---, *** y ___ (y no son viñetas)', () {
      final blocks = parseMarkdown('---\n***\n___');

      expect(blocks.map((b) => b.type),
          everyElement(MarkdownBlockType.rule));
      expect(blocks, hasLength(3));
    });

    test('un bloque corta el párrafo en curso', () {
      final blocks = parseMarkdown('Texto\n- viñeta\nTexto 2\n## Título');

      expect(blocks.map((b) => b.type), [
        MarkdownBlockType.paragraph,
        MarkdownBlockType.bullet,
        MarkdownBlockType.paragraph,
        MarkdownBlockType.heading,
      ]);
    });

    test('acepta saltos de línea de Windows y tabs como indentación', () {
      final blocks = parseMarkdown('# T\r\n\t- sub\r\n');

      expect(blocks.first.text, 'T');
      expect(blocks.last.level, 1);
    });

    test('documento vacío → sin bloques', () {
      expect(parseMarkdown(''), isEmpty);
      expect(parseMarkdown('\n\n  \n'), isEmpty);
    });

    test('MarkdownBlock: igualdad, hashCode y toString', () {
      const a = MarkdownBlock(MarkdownBlockType.bullet, text: 'x', level: 1);
      const b = MarkdownBlock(MarkdownBlockType.bullet, text: 'x', level: 1);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const MarkdownBlock(MarkdownBlockType.bullet, text: 'y')));
      expect(a.toString(), contains('text: "x"'));
    });
  });

  group('parseInline', () {
    String plain(String text) =>
        TextSpan(children: parseInline(text)).toPlainText();

    test('negrita sin los asteriscos', () {
      final spans = parseInline('Hola **mundo** fin');

      expect(plain('Hola **mundo** fin'), 'Hola mundo fin');
      final bold = spans[1] as TextSpan;
      expect(bold.style?.fontWeight, FontWeight.w700);
    });

    test('link → "texto (url)"; si el texto es la url, solo la url', () {
      expect(plain('Ver [OpenAI](https://openai.com).'),
          'Ver OpenAI (https://openai.com).');
      expect(plain('[https://x.co](https://x.co)'), 'https://x.co');
    });

    test('código sin backticks y con estilo de código', () {
      const style = TextStyle(fontFamily: 'Courier');
      final spans = parseInline('Permiso `GPS` ok', codeStyle: style);

      expect(plain('Permiso `GPS` ok'), 'Permiso GPS ok');
      expect((spans[1] as TextSpan).style, style);
      expect((parseInline('`a`').single as TextSpan).style?.fontFamily,
          'monospace');
    });

    test('negrita con link adentro', () {
      expect(plain('**Fuente: [A](https://a.co)**'), 'Fuente: A (https://a.co)');
    });

    test('texto sin sintaxis queda igual', () {
      expect(plain('Solo texto * suelto'), 'Solo texto * suelto');
    });
  });

  group('SimpleMarkdown (widget)', () {
    Future<void> pump(WidgetTester tester, String data) => tester.pumpWidget(
          MaterialApp(home: Scaffold(body: SimpleMarkdown(data: data))),
        );

    testWidgets('renderiza todos los tipos de bloque', (tester) async {
      await pump(
        tester,
        '# Título\n## Sección\n### Sub\n\nPárrafo **fuerte**\n\n'
        '- Viñeta\n  - Sub viñeta\n1. Numerada\n\n---\n',
      );

      expect(find.text('Título'), findsOneWidget);
      expect(find.text('Sección'), findsOneWidget);
      expect(find.text('Sub'), findsOneWidget);
      expect(find.text('Párrafo fuerte', findRichText: true), findsOneWidget);
      expect(find.text('•'), findsOneWidget);
      expect(find.text('◦'), findsOneWidget);
      expect(find.text('1.'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
      expect(find.byType(SelectionArea), findsOneWidget);
    });

    testWidgets('los títulos son headers para el lector de pantalla',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, '## Tus derechos');

      expect(
        tester.getSemantics(find.text('Tus derechos')),
        matchesSemantics(isHeader: true, label: 'Tus derechos'),
      );
      handle.dispose();
    });

    testWidgets('la viñeta se indenta según su nivel', (tester) async {
      await pump(tester, '- a\n    - b');

      final padding = tester.widget<Padding>(find
          .ancestor(of: find.text('◦'), matching: find.byType(Padding))
          .first);
      expect((padding.padding as EdgeInsets).left, greaterThan(0));
      expect(find.text('b', findRichText: true), findsOneWidget);
    });
  });
}
