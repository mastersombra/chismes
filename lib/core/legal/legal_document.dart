/// Documentos legales que la app muestra (textos en `assets/legal/`).
///
/// La versión vigente de cada uno vive en la tabla `legal_documents`
/// (`016_policy_acceptances.sql`), y el servidor registra su aceptación al
/// crear la cuenta. Al cambiar un documento, subir la "Versión" de su
/// encabezado (es y en) y la de la tabla en una migración nueva.
enum LegalDocument {
  privacyPolicy('privacy_policy'),
  termsOfService('terms_of_service');

  const LegalDocument(this.assetName);

  /// Nombre base del archivo (igual al `document` de `legal_documents`)
  final String assetName;

  /// Idiomas con traducción. Cualquier otro muestra el español, que es la
  /// versión que prevalece.
  static const supportedLanguages = {'es', 'en'};
  static const fallbackLanguage = 'es';

  /// Ruta del asset para el idioma (`languageCode` de la locale)
  String assetPath(String languageCode) {
    final language = supportedLanguages.contains(languageCode)
        ? languageCode
        : fallbackLanguage;
    return 'assets/legal/$assetName.$language.md';
  }
}
