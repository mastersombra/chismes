import 'package:equatable/equatable.dart';

import 'moderation_item.dart';

/// Motivos predefinidos al rechazar (se guardan como código en
/// `moderation_queue.decision_reason`; base de las sanciones futuras)
enum RejectReason {
  harassment('harassment'),
  hate('hate'),
  sexualContent('sexual_content'),
  violence('violence'),
  personalData('personal_data'),
  spam('spam'),
  misinformation('misinformation'),
  other('other');

  const RejectReason(this.value);

  final String value;

  static RejectReason? fromValue(String? value) {
    for (final reason in values) {
      if (reason.value == value) return reason;
    }
    return null;
  }
}

/// Decisión de un moderador sobre una entrada de la cola
class ReviewDecision extends Equatable {
  final String queueId;
  final bool approve;

  /// Obligatoria al rechazar; no aplica al aprobar
  final ModerationSeverity? severity;
  final RejectReason? reason;
  final String? note;

  const ReviewDecision.approve({required this.queueId, this.note})
      : approve = true,
        severity = null,
        reason = null;

  const ReviewDecision.reject({
    required this.queueId,
    required ModerationSeverity this.severity,
    this.reason,
    this.note,
  }) : approve = false;

  @override
  List<Object?> get props => [queueId, approve, severity, reason, note];
}
