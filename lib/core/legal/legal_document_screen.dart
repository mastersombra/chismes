import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_spacing.dart';
import '../widgets/simple_markdown.dart';
import 'legal_document.dart';

/// Muestra un documento legal (Política de privacidad o Términos de uso) en
/// el idioma de la app, desde `assets/legal/` (funciona sin conexión).
///
/// Cuando las políticas estén hospedadas (chismes.app), esta pantalla sigue
/// siendo la versión que se lee dentro de la app.
class LegalDocumentScreen extends StatefulWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  /// Abre el documento encima de la ruta actual
  static Future<void> open(BuildContext context, LegalDocument document) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LegalDocumentScreen(document: document),
      ),
    );
  }

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  Future<String>? _content;
  String? _loadedPath;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Depende de la locale y del AssetBundle: se resuelve aquí, no en initState
    final path = widget.document.assetPath(
      Localizations.localeOf(context).languageCode,
    );
    if (path != _loadedPath) {
      _loadedPath = path;
      _content = DefaultAssetBundle.of(context).loadString(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.document) {
      LegalDocument.privacyPolicy => context.l10n.legalPrivacyPolicyTitle,
      LegalDocument.termsOfService => context.l10n.legalTermsOfServiceTitle,
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        top: false,
        child: FutureBuilder<String>(
          future: _content,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    context.l10n.legalDocumentLoadError,
                    key: const Key('legalDocumentError'),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return SimpleMarkdown(data: snapshot.data!);
          },
        ),
      ),
    );
  }
}
