import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../domain/entities/app_notification.dart';

/// Textos de las notificaciones (frase, motivo de rechazo, tiempo relativo)
class NotificationTexts {
  NotificationTexts._();

  /// Largo máximo del asunto del chisme dentro de la frase
  static const maxSubjectLength = 40;

  /// Frase de la notificación en el idioma de la app
  static String sentence(BuildContext context, AppNotification notification) {
    final l10n = context.l10n;
    final name = actorName(context, notification.actor);
    final subject = excerpt(notification.gossip?.subject);
    return switch (notification.type) {
      NotificationType.newFollower => l10n.notificationsNewFollower(name),
      NotificationType.followRequest => l10n.notificationsFollowRequest(name),
      NotificationType.followAccepted => l10n.notificationsFollowAccepted(name),
      NotificationType.gossipApproved => l10n.notificationsGossipApproved(subject),
      NotificationType.gossipRejected => notification.reason == null
          ? l10n.notificationsGossipRejected(subject)
          : l10n.notificationsGossipRejectedWithReason(
              subject,
              reason(context, notification.reason!),
            ),
      NotificationType.appealAccepted => l10n.notificationsAppealAccepted(subject),
      NotificationType.appealRejected => l10n.notificationsAppealRejected(subject),
    };
  }

  /// Nombre visible o @usuario (como las listas sociales)
  static String actorName(BuildContext context, NotificationActor? actor) {
    final name = actor?.name ?? '';
    return name.isEmpty ? context.l10n.socialUnknownUser : name;
  }

  /// Asunto recortado a [maxSubjectLength] (con '…'); vacío → '…'
  static String excerpt(String? subject) {
    final text = (subject ?? '').trim();
    if (text.isEmpty) return '…';
    if (text.length <= maxSubjectLength) return text;
    return '${text.substring(0, maxSubjectLength).trimRight()}…';
  }

  /// Motivo predefinido del rechazo (códigos de `RejectReason` en
  /// moderation). Uno desconocido → texto genérico.
  static String reason(BuildContext context, String code) {
    final l10n = context.l10n;
    return switch (code) {
      'harassment' => l10n.gossipReportReasonHarassment,
      'hate' => l10n.moderationRejectReasonHate,
      'sexual_content' => l10n.gossipReportReasonSexualContent,
      'violence' => l10n.gossipReportReasonViolence,
      'personal_data' => l10n.moderationRejectReasonPersonalData,
      'spam' => l10n.gossipReportReasonSpam,
      'misinformation' => l10n.gossipReportReasonMisinformation,
      'other' => l10n.gossipReportReasonOther,
      _ => l10n.notificationsReasonGeneric,
    };
  }

  /// "ahora", "5 min", "3 h", "2 d"; desde 7 días, la fecha corta
  static String relativeTime(BuildContext context, DateTime createdAt, DateTime now) {
    final l10n = context.l10n;
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return l10n.notificationsTimeNow;
    if (diff.inHours < 1) return l10n.notificationsTimeMinutes(diff.inMinutes);
    if (diff.inDays < 1) return l10n.notificationsTimeHours(diff.inHours);
    if (diff.inDays < 7) return l10n.notificationsTimeDays(diff.inDays);
    return MaterialLocalizations.of(context).formatShortMonthDay(createdAt.toLocal());
  }
}
