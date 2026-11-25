import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'legal_document.dart';
import 'legal_document_screen.dart';

/// "Al continuar, aceptas los Términos de uso y la Política de privacidad",
/// con los dos nombres tocables.
///
/// Debe estar visible ANTES de cualquier forma de crear la cuenta (Registro
/// con email, Login con Google/Apple): el servidor registra la aceptación de
/// las versiones vigentes al crear el usuario (`016_policy_acceptances.sql`).
class LegalConsentText extends StatefulWidget {
  const LegalConsentText({super.key, this.textAlign = TextAlign.center});

  final TextAlign textAlign;

  @override
  State<LegalConsentText> createState() => _LegalConsentTextState();
}

class _LegalConsentTextState extends State<LegalConsentText> {
  // Marcadores para ubicar los links dentro de la frase traducida (el orden
  // de "términos" y "privacidad" puede cambiar según el idioma)
  static const _termsMarker = '\u0000terms\u0000';
  static const _privacyMarker = '\u0000privacy\u0000';
  static final _markerRe = RegExp('\u0000(terms|privacy)\u0000');

  late final TapGestureRecognizer _termsRecognizer = TapGestureRecognizer()
    ..onTap = () => LegalDocumentScreen.open(context, LegalDocument.termsOfService);
  late final TapGestureRecognizer _privacyRecognizer = TapGestureRecognizer()
    ..onTap = () => LegalDocumentScreen.open(context, LegalDocument.privacyPolicy);

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final linkStyle = TextStyle(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w600,
    );

    final message =
        context.l10n.legalConsentMessage(_termsMarker, _privacyMarker);
    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in _markerRe.allMatches(message)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: message.substring(cursor, match.start)));
      }
      final isTerms = match.group(0) == _termsMarker;
      spans.add(TextSpan(
        text: isTerms
            ? context.l10n.legalTermsOfServiceTitle
            : context.l10n.legalPrivacyPolicyTitle,
        style: linkStyle,
        recognizer: isTerms ? _termsRecognizer : _privacyRecognizer,
      ));
      cursor = match.end;
    }
    if (cursor < message.length) {
      spans.add(TextSpan(text: message.substring(cursor)));
    }

    return Text.rich(
      TextSpan(children: spans),
      key: const Key('legalConsentText'),
      style: baseStyle,
      textAlign: widget.textAlign,
    );
  }
}
