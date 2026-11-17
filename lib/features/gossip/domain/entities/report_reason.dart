import 'package:flutter/widgets.dart';

import '../../../../core/l10n/l10n.dart';

/// Razones para reportar un gossip
///
/// Basado en las reglas de moderación y política de contenido.
/// Estas razones están alineadas con el Edge Function report-gossip.
enum ReportReason {
  /// Contenido spam o repetitivo
  spam('spam'),

  /// Acoso o intimidación
  harassment('harassment'),

  /// Contenido violento o amenazas
  violence('violence'),

  /// Contenido sexual inapropiado
  sexualContent('sexual_content'),

  /// Desinformación o noticias falsas
  misinformation('misinformation'),

  /// Otra razón no especificada
  other('other');

  /// Valor que se envía al backend (snake_case)
  final String value;

  const ReportReason(this.value);

  /// Obtiene el texto descriptivo traducido para mostrar al usuario
  ///
  /// Debe llamarse desde la UI que tiene BuildContext.
  String getDisplayName(BuildContext context) {
    switch (this) {
      case ReportReason.spam:
        return context.l10n.gossipReportReasonSpam;
      case ReportReason.harassment:
        return context.l10n.gossipReportReasonHarassment;
      case ReportReason.violence:
        return context.l10n.gossipReportReasonViolence;
      case ReportReason.sexualContent:
        return context.l10n.gossipReportReasonSexualContent;
      case ReportReason.misinformation:
        return context.l10n.gossipReportReasonMisinformation;
      case ReportReason.other:
        return context.l10n.gossipReportReasonOther;
    }
  }

  /// Convierte desde el valor del backend
  static ReportReason fromValue(String value) {
    return ReportReason.values.firstWhere(
      (reason) => reason.value == value,
      orElse: () => ReportReason.other,
    );
  }
}
