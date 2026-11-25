import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Renderer mínimo de Markdown para los documentos de la app (políticas
/// legales en `assets/legal/`).
///
/// **Soporta solo lo que usan esos documentos** (a propósito: sin dependencias
/// externas y con el estilo del tema):
/// - Títulos `#`, `##`, `###` (y `####`+ como `###`)
/// - Viñetas `- ` / `* ` con sub-niveles por indentación (2 espacios)
/// - Listas numeradas `1. `
/// - Separador `---`
/// - Párrafos (líneas seguidas se unen; dos espacios al final = salto de línea)
/// - Inline: `**negrita**`, `` `código` `` y `[texto](url)`
///
/// Los links se muestran como "texto (url)" sin ser tocables: el documento
/// va dentro de un [SelectionArea] para poder copiar URLs y emails.
///
/// Cualquier otra sintaxis se muestra como texto plano.
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown({
    super.key,
    required this.data,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final String data;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final blocks = parseMarkdown(data);
    return SelectionArea(
      child: ListView.builder(
        padding: padding,
        itemCount: blocks.length,
        itemBuilder: (context, index) =>
            MarkdownBlockView(block: blocks[index]),
      ),
    );
  }
}

/// Tipo de bloque del documento
enum MarkdownBlockType { heading, paragraph, bullet, numbered, rule }

/// Bloque ya parseado (el texto conserva la sintaxis inline)
@immutable
class MarkdownBlock {
  const MarkdownBlock(
    this.type, {
    this.text = '',
    this.level = 0,
    this.number,
  });

  final MarkdownBlockType type;

  /// Texto con sintaxis inline (`**`, `` ` ``, links)
  final String text;

  /// Heading: 1–3. Viñeta/numerada: nivel de indentación (0 = raíz)
  final int level;

  /// Número de la lista numerada (como está escrito)
  final String? number;

  @override
  bool operator ==(Object other) =>
      other is MarkdownBlock &&
      other.type == type &&
      other.text == text &&
      other.level == level &&
      other.number == number;

  @override
  int get hashCode => Object.hash(type, text, level, number);

  @override
  String toString() => 'MarkdownBlock($type, level: $level, '
      'number: $number, text: "$text")';
}

final _headingRe = RegExp(r'^(#{1,6})\s+(.*)$');
final _bulletRe = RegExp(r'^(\s*)[-*]\s+(.*)$');
final _numberedRe = RegExp(r'^(\s*)(\d+)\.\s+(.*)$');
final _ruleRe = RegExp(r'^\s*(-{3,}|\*{3,}|_{3,})\s*$');

/// Parsea el documento en bloques. Función pura (testeable sin widgets).
List<MarkdownBlock> parseMarkdown(String source) {
  final blocks = <MarkdownBlock>[];
  final paragraph = StringBuffer();
  var hardBreak = false;

  void flushParagraph() {
    if (paragraph.isNotEmpty) {
      blocks.add(MarkdownBlock(
        MarkdownBlockType.paragraph,
        text: paragraph.toString(),
      ));
      paragraph.clear();
    }
    hardBreak = false;
  }

  for (final rawLine in source.replaceAll('\r\n', '\n').split('\n')) {
    final line = rawLine.trimRight();

    if (line.isEmpty) {
      flushParagraph();
      continue;
    }

    if (_ruleRe.hasMatch(line)) {
      flushParagraph();
      blocks.add(const MarkdownBlock(MarkdownBlockType.rule));
      continue;
    }

    final heading = _headingRe.firstMatch(line);
    if (heading != null) {
      flushParagraph();
      final level = heading.group(1)!.length.clamp(1, 3);
      blocks.add(MarkdownBlock(
        MarkdownBlockType.heading,
        text: heading.group(2)!.trim(),
        level: level,
      ));
      continue;
    }

    final bullet = _bulletRe.firstMatch(line);
    if (bullet != null) {
      flushParagraph();
      blocks.add(MarkdownBlock(
        MarkdownBlockType.bullet,
        text: bullet.group(2)!,
        level: _indentLevel(bullet.group(1)!),
      ));
      continue;
    }

    final numbered = _numberedRe.firstMatch(line);
    if (numbered != null) {
      flushParagraph();
      blocks.add(MarkdownBlock(
        MarkdownBlockType.numbered,
        text: numbered.group(3)!,
        level: _indentLevel(numbered.group(1)!),
        number: numbered.group(2),
      ));
      continue;
    }

    // Línea de párrafo
    if (paragraph.isNotEmpty) paragraph.write(hardBreak ? '\n' : ' ');
    paragraph.write(line.trim());
    hardBreak = rawLine.endsWith('  ');
  }
  flushParagraph();
  return blocks;
}

int _indentLevel(String indent) =>
    indent.replaceAll('\t', '  ').length ~/ 2;

final _inlineRe = RegExp(r'\*\*(.+?)\*\*|`([^`]+)`|\[([^\]]+)\]\(([^)\s]+)\)');

/// Convierte la sintaxis inline en spans (negrita, código, links)
List<InlineSpan> parseInline(String text, {TextStyle? codeStyle}) {
  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final match in _inlineRe.allMatches(text)) {
    if (match.start > cursor) {
      spans.add(TextSpan(text: text.substring(cursor, match.start)));
    }
    if (match.group(1) != null) {
      spans.add(TextSpan(
        children: parseInline(match.group(1)!, codeStyle: codeStyle),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
    } else if (match.group(2) != null) {
      spans.add(TextSpan(
        text: match.group(2),
        style: codeStyle ?? const TextStyle(fontFamily: 'monospace'),
      ));
    } else {
      final label = match.group(3)!;
      final url = match.group(4)!;
      spans.add(TextSpan(text: label == url ? url : '$label ($url)'));
    }
    cursor = match.end;
  }
  if (cursor < text.length) {
    spans.add(TextSpan(text: text.substring(cursor)));
  }
  return spans;
}

/// Widget de un bloque (público para tests y para reusar en otras vistas)
class MarkdownBlockView extends StatelessWidget {
  const MarkdownBlockView({super.key, required this.block});

  final MarkdownBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final body = textTheme.bodyMedium?.copyWith(height: 1.5);
    final codeStyle = TextStyle(
      fontFamily: 'monospace',
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
    );

    Text rich(String text, TextStyle? style) => Text.rich(
          TextSpan(children: parseInline(text, codeStyle: codeStyle)),
          style: style,
        );

    switch (block.type) {
      case MarkdownBlockType.heading:
        final style = switch (block.level) {
          1 => textTheme.headlineSmall,
          2 => textTheme.titleLarge,
          _ => textTheme.titleMedium,
        };
        return Padding(
          padding: EdgeInsets.only(
            top: block.level == 1 ? 0 : AppSpacing.lg,
            bottom: AppSpacing.sm,
          ),
          child: Semantics(
            header: true,
            child: rich(
              block.text,
              style?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        );

      case MarkdownBlockType.paragraph:
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: rich(block.text, body),
        );

      case MarkdownBlockType.bullet:
      case MarkdownBlockType.numbered:
        final marker = block.type == MarkdownBlockType.bullet
            ? (block.level == 0 ? '•' : '◦')
            : '${block.number}.';
        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg * block.level,
            bottom: AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: AppSpacing.xl,
                child: Text(marker, style: body),
              ),
              Expanded(child: rich(block.text, body)),
            ],
          ),
        );

      case MarkdownBlockType.rule:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Divider(height: 1),
        );
    }
  }
}
