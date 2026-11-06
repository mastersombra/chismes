import 'package:equatable/equatable.dart';

import 'gossip.dart';

enum ModerationVerdict { publish, review, reject }

enum ModerationReason {
  potentialProfanity,
  potentialPersonalData,
  potentialSpam,
  potentialHarassment,
  credibleThreat,
  potentialHate,
  potentialSexualContent,
  sexualContentInvolvingMinors,
  potentialViolence,
  potentialSelfHarm,
  externalProviderUnavailable,
  communityReports,
}

enum ModerationSource {
  localRules,
  externalProvider,
  communityReports,
  humanReview,
}

class ModerationDecision extends Equatable {
  final ModerationVerdict verdict;
  final List<ModerationReason> reasons;
  final List<ModerationSource> sources;

  ModerationDecision({
    required this.verdict,
    Iterable<ModerationReason> reasons = const [],
    Iterable<ModerationSource> sources = const [],
  }) : reasons = List.unmodifiable(reasons.toSet()),
       sources = List.unmodifiable(sources.toSet());

  GossipStatus get initialGossipStatus {
    switch (verdict) {
      case ModerationVerdict.publish:
        return GossipStatus.published;
      case ModerationVerdict.review:
        return GossipStatus.draft;
      case ModerationVerdict.reject:
        return GossipStatus.draft;
    }
  }

  ModerationStatus get initialModerationStatus {
    switch (verdict) {
      case ModerationVerdict.publish:
        return ModerationStatus.approved;
      case ModerationVerdict.review:
        return ModerationStatus.pending;
      case ModerationVerdict.reject:
        return ModerationStatus.rejected;
    }
  }

  bool get requiresHumanReview => verdict == ModerationVerdict.review;

  bool get isRejected => verdict == ModerationVerdict.reject;

  static ModerationDecision mostRestrictive(
    ModerationDecision first,
    ModerationDecision second,
  ) {
    final verdict = _priority(first.verdict) >= _priority(second.verdict)
        ? first.verdict
        : second.verdict;

    return ModerationDecision(
      verdict: verdict,
      reasons: [...first.reasons, ...second.reasons],
      sources: [...first.sources, ...second.sources],
    );
  }

  static int _priority(ModerationVerdict verdict) {
    switch (verdict) {
      case ModerationVerdict.publish:
        return 0;
      case ModerationVerdict.review:
        return 1;
      case ModerationVerdict.reject:
        return 2;
    }
  }

  @override
  List<Object?> get props => [verdict, reasons, sources];
}
