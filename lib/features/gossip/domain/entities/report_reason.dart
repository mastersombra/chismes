/// Razones para reportar un gossip
///
/// Basado en las reglas de moderación y política de contenido.
/// Estas razones están alineadas con el Edge Function report-gossip.
enum ReportReason {
  /// Contenido spam o repetitivo
  spam('spam', 'Spam'),

  /// Acoso o intimidación
  harassment('harassment', 'Acoso o intimidación'),

  /// Contenido violento o amenazas
  violence('violence', 'Violencia o amenazas'),

  /// Contenido sexual inapropiado
  sexualContent('sexual_content', 'Contenido sexual'),

  /// Desinformación o noticias falsas
  misinformation('misinformation', 'Desinformación'),

  /// Otra razón no especificada
  other('other', 'Otro motivo');

  /// Valor que se envía al backend (snake_case)
  final String value;

  /// Texto descriptivo para mostrar al usuario
  final String displayName;

  const ReportReason(this.value, this.displayName);

  /// Convierte desde el valor del backend
  static ReportReason fromValue(String value) {
    return ReportReason.values.firstWhere(
      (reason) => reason.value == value,
      orElse: () => ReportReason.other,
    );
  }
}
