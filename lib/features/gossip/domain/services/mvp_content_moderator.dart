import '../entities/create_gossip_input.dart';
import '../entities/moderation_decision.dart';
import 'content_moderator.dart';

/// Política local mínima para el MVP.
///
/// No pretende comprender contexto ni reemplazar una revisión humana. Las
/// palabras configuradas sólo mandan a revisión; no se bloquean de forma
/// definitiva porque pueden tener usos legítimos según el contexto.
///
/// ⚠️ Esta clase NO usa @Singleton directamente porque tiene un parámetro
/// con valor por defecto que injectable no puede resolver automáticamente.
/// En su lugar, se registra manualmente en GossipModule.
class MvpModerationPolicy {
  final Set<String> reviewTerms;

  const MvpModerationPolicy({
    this.reviewTerms = const {
      'gonorrea',
      'hijueputa',
      'malparido',
      'marica',
      'perra',
      'puta',
    },
  });

  ModerationDecision evaluate(CreateGossipInput input) {
    final rawText = '${input.subject}\n${input.content}';
    final normalizedText = _normalize(rawText);
    final reasons = <ModerationReason>[];

    // Datos de contacto, URLs y secuencias largas de dígitos pueden exponer a
    // una persona o utilizarse para spam. Se retienen para revisión.
    if (_containsPersonalData(rawText)) {
      reasons.add(ModerationReason.potentialPersonalData);
    }

    if (_containsSpam(rawText, normalizedText)) {
      reasons.add(ModerationReason.potentialSpam);
    }

    if (_containsReviewTerm(normalizedText)) {
      reasons.add(ModerationReason.potentialProfanity);
    }

    // Amenazas directas se rechazan antes de que puedan aparecer públicamente.
    if (_containsCredibleThreat(normalizedText)) {
      return ModerationDecision(
        verdict: ModerationVerdict.reject,
        reasons: [...reasons, ModerationReason.credibleThreat],
        sources: const [ModerationSource.localRules],
      );
    }

    if (reasons.isNotEmpty) {
      return ModerationDecision(
        verdict: ModerationVerdict.review,
        reasons: reasons,
        sources: const [ModerationSource.localRules],
      );
    }

    return ModerationDecision(
      verdict: ModerationVerdict.publish,
      sources: const [ModerationSource.localRules],
    );
  }

  bool _containsPersonalData(String text) {
    final hasEmail = RegExp(
      r"\b[\w.!#$%&'*+/=?^`{|}~-]+@[\w](?:[\w-]{0,61}[\w])?(?:\.[\w](?:[\w-]{0,61}[\w])?)+\b",
    ).hasMatch(text);
    final hasPhone = RegExp(
      r'(?<!\d)(?:\+?57[\s.-]?)?3\d{2}[\s.-]?\d{3}[\s.-]?\d{4}(?!\d)',
    ).hasMatch(text);

    return hasEmail || hasPhone;
  }

  bool _containsSpam(String rawText, String normalizedText) {
    final hasUrl = RegExp(
      r'\b(?:https?://|www\.)',
      caseSensitive: false,
    ).hasMatch(rawText);
    final hasLongRepeatedCharacter = RegExp(
      r'([a-z])\1{6,}',
    ).hasMatch(normalizedText);

    return hasUrl || hasLongRepeatedCharacter;
  }

  bool _containsReviewTerm(String normalizedText) {
    return reviewTerms.any((term) {
      final normalizedTerm = _normalize(term);
      return RegExp(
        '(?:^|\\s)${RegExp.escape(normalizedTerm)}(?:\\s|\$)',
      ).hasMatch(normalizedText);
    });
  }

  bool _containsCredibleThreat(String text) {
    return RegExp(
      r'\b(?:te|lo|la|los|las)\s+(?:voy|vamos)\s+a\s+(?:matar|golpear|atacar|violar)\b',
    ).hasMatch(text);
  }

  String _normalize(String value) {
    const accents = 'áéíóúüñ';
    const replacements = 'aeiouun';
    var normalized = value.toLowerCase();

    for (var index = 0; index < accents.length; index++) {
      normalized = normalized.replaceAll(accents[index], replacements[index]);
    }

    return normalized
        .replaceAll('0', 'o')
        .replaceAll('1', 'i')
        .replaceAll('3', 'e')
        .replaceAll('4', 'a')
        .replaceAll('5', 's')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

/// ⚠️ FALLBACK LOCAL - NO USADO EN PRODUCCIÓN
///
/// Este moderador se mantiene SOLO como:
/// 1. Fallback si Edge Function falla (edge case extremo)
/// 2. Tests unitarios
/// 3. Desarrollo local sin backend
///
/// **PRODUCCIÓN USA:** Edge Function `moderate-gossip` con OpenAI Moderation API
/// **NO CONFUNDIR:** Este NO es el moderador activo en producción.
///
/// **Flujo Real de Producción:**
/// ```
/// Cliente → Edge Function moderate-gossip → OpenAI API
///                                         ↓
///                                    Supabase Insert
/// ```
///
/// **Este clase:**
/// - ✅ Registrada en DI para desarrollo/tests
/// - ❌ NO se invoca desde el cliente en producción
/// - ❌ NO tiene acceso a OpenAI (cliente no debe tener API keys)
///
/// Ver implementación activa: `supabase/functions/moderate-gossip/index.ts`
///
/// ⚠️ ELIMINADO DE DI - Este moderador NO se registra ni se usa en producción.
/// Se mantiene solo para referencia y posibles tests futuros.
/// Si deseas eliminarlo completamente, es seguro hacerlo.
// @Singleton(as: ContentModerator) // ← DESACTIVADO: No se usa en producción
class MvpContentModerator implements ContentModerator {
  final MvpModerationPolicy policy;

  const MvpContentModerator({
    required this.policy,
  });

  @override
  Future<ModerationDecision> moderate(CreateGossipInput input) async {
    return policy.evaluate(input);
  }
}
