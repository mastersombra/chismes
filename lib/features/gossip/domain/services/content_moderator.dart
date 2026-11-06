import '../entities/create_gossip_input.dart';
import '../entities/moderation_decision.dart';

/// Puerto de moderación del dominio.
///
/// En producción su implementación vive en el backend o en una Cloud Function;
/// jamás en Flutter, pues la clave del proveedor no puede distribuirse dentro de
/// la aplicación. El mock actual lo implementa localmente sólo para simular el
/// comportamiento de ese servidor durante el desarrollo.
abstract class ContentModerator {
  Future<ModerationDecision> moderate(CreateGossipInput input);
}

/// Adaptador para un proveedor de IA, como OpenAI Moderation o Google Cloud.
///
/// El adaptador de infraestructura traduce las categorías y puntajes del
/// proveedor a [ModerationDecision]. Así el dominio no depende de SDKs, claves
/// ni formatos HTTP de ningún proveedor.
abstract class ExternalContentModerator {
  Future<ModerationDecision> moderateText(String text);
}
