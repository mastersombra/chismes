import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../domain/entities/account_status.dart';
import '../../domain/entities/moderation_item.dart';
import '../../domain/entities/review_decision.dart';

/// Textos de la UI de moderación para los códigos que manda el servidor
class ModerationLabels {
  ModerationLabels._();

  /// Traduce un código de `moderation_queue.reasons`. Los desconocidos se
  /// muestran tal cual (mejor que ocultarle algo al moderador).
  static String reason(BuildContext context, String code) {
    final l10n = context.l10n;
    if (code.startsWith('term:')) {
      return l10n.moderationReasonTerm(code.substring('term:'.length));
    }
    if (code.startsWith('ai_score:')) {
      return l10n.moderationReasonAiScore(code.substring('ai_score:'.length));
    }
    return switch (code) {
      'moderation_unavailable' => l10n.moderationReasonAiUnavailable,
      'rules_unavailable' => l10n.moderationReasonRulesUnavailable,
      'potential_personal_data' => l10n.moderationReasonPersonalData,
      'potential_spam' => l10n.moderationReasonSpam,
      'credible_threat' => l10n.moderationReasonThreat,
      'audio_not_moderated' => l10n.moderationReasonAudio,
      // Motivos de reporte de usuarios (content_reports.reason)
      'spam' => l10n.gossipReportReasonSpam,
      'harassment' => l10n.gossipReportReasonHarassment,
      'violence' => l10n.gossipReportReasonViolence,
      'sexual_content' => l10n.gossipReportReasonSexualContent,
      'misinformation' => l10n.gossipReportReasonMisinformation,
      'other' => l10n.gossipReportReasonOther,
      _ => code,
    };
  }

  static String source(BuildContext context, ModerationSource source) {
    final l10n = context.l10n;
    return switch (source) {
      ModerationSource.aiReview => l10n.moderationSourceAiReview,
      ModerationSource.aiUnavailable => l10n.moderationSourceAiUnavailable,
      ModerationSource.reports => l10n.moderationSourceReports,
    };
  }

  static String severity(BuildContext context, ModerationSeverity severity) {
    final l10n = context.l10n;
    return switch (severity) {
      ModerationSeverity.low => l10n.moderationSeverityLow,
      ModerationSeverity.medium => l10n.moderationSeverityMedium,
      ModerationSeverity.high => l10n.moderationSeverityHigh,
      ModerationSeverity.critical => l10n.moderationSeverityCritical,
    };
  }

  static String rejectReason(BuildContext context, RejectReason reason) {
    final l10n = context.l10n;
    return switch (reason) {
      RejectReason.harassment => l10n.gossipReportReasonHarassment,
      RejectReason.hate => l10n.moderationRejectReasonHate,
      RejectReason.sexualContent => l10n.gossipReportReasonSexualContent,
      RejectReason.violence => l10n.gossipReportReasonViolence,
      RejectReason.personalData => l10n.moderationRejectReasonPersonalData,
      RejectReason.spam => l10n.gossipReportReasonSpam,
      RejectReason.misinformation => l10n.gossipReportReasonMisinformation,
      RejectReason.other => l10n.gossipReportReasonOther,
    };
  }

  /// `decision_reason` guardado (código de [RejectReason] o texto libre)
  static String decisionReason(BuildContext context, String value) {
    final reason = RejectReason.fromValue(value);
    return reason != null ? rejectReason(context, reason) : value;
  }

  static String sanction(BuildContext context, SanctionKind kind) {
    final l10n = context.l10n;
    return switch (kind) {
      SanctionKind.warning => l10n.accountStatusSanctionWarning,
      SanctionKind.restriction => l10n.accountStatusSanctionRestriction,
      SanctionKind.suspension => l10n.accountStatusSanctionSuspension,
    };
  }

  static String appealStatus(BuildContext context, AppealStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      AppealStatus.pending => l10n.appealStatusPending,
      AppealStatus.accepted => l10n.appealStatusAccepted,
      AppealStatus.rejected => l10n.appealStatusRejected,
    };
  }

  /// Filtro de la pestaña Apelaciones (plural: "Aceptadas")
  static String appealFilter(BuildContext context, AppealStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      AppealStatus.pending => l10n.moderationTabPending,
      AppealStatus.accepted => l10n.appealFilterAccepted,
      AppealStatus.rejected => l10n.appealFilterRejected,
    };
  }

  /// Fecha corta en el idioma de la app
  static String date(BuildContext context, DateTime value) {
    return MaterialLocalizations.of(context).formatShortDate(value.toLocal());
  }

  /// Fecha + hora corta en el idioma de la app
  static String dateTime(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final material = MaterialLocalizations.of(context);
    return '${material.formatShortDate(local)} · '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }
}
