# Moderación del MVP

Esta aplicación usa una moderación híbrida. Las reglas locales detectan señales
simples y baratas; un proveedor externo agrega clasificación contextual; las
denuncias de la comunidad y un administrador resuelven los casos dudosos.

## Estados persistidos

No se agregan enums duplicados: los existentes expresan el flujo completo.

| Situación | `GossipStatus` | `ModerationStatus` | `visibility` |
| --- | --- | --- | --- |
| Contenido limpio, aprobado automáticamente | `published` | `approved` | `public` |
| Contenido dudoso o proveedor no disponible | `under_review` | `pending` | `private` |
| Denunciado mientras se investiga | `hidden` | `flagged` | `private` |
| Rechazado por reglas o administrador | `hidden` | `rejected` | `private` |
| Eliminado definitivamente | `deleted` | `rejected` | `private` |

`draft` es sólo estado local de formulario y no se persiste. Un rechazo de
creación tampoco genera un Gossip público: el backend debe guardar, si hace
falta, un evento de auditoría separado.

Inicio y Buscar sólo pueden mostrar `published + approved + public`.

## Decisiones del MVP

| Señal | Resultado |
| --- | --- |
| Texto limpio | Publicar automáticamente |
| Término ambiguo, teléfono, correo, URL o spam | Enviar a revisión |
| Amenaza directa | Rechazar |
| Error de proveedor externo | Enviar a revisión (fail closed) |
| Denuncias confiables suficientes | Ocultar y marcar como `flagged` |

La lista local no es una lista de censura. Por ejemplo, `gonorrea` se retiene
para revisión porque puede ser un insulto o un término médico; nunca basta una
palabra para concluir el contexto.

## Límite de confianza

La app Flutter sólo envía `CreateGossipInput`. Un endpoint autenticado del
backend debe ejecutar reglas, rate limiting y el proveedor de IA, y asignar
`status`, `moderationStatus`, `visibility`, auditoría e identidad del autor.
No se debe entregar `OPENAI_API_KEY` ni credenciales de Google Cloud en la app.

`MockGossipRemoteDataSource` ejecuta `MvpContentModerator` únicamente para
simular ese backend durante el desarrollo.

## Adaptador para OpenAI

Implementar el adaptador de servidor de `ExternalContentModerator` con una
petición `POST /v1/moderations`, modelo `omni-moderation-latest`, y el texto
unido de asunto y contenido. El modelo devuelve categorías, puntajes y
`flagged`; el adaptador debe mapearlos a `ModerationDecision`:

| Categoría o señal | Decisión recomendada |
| --- | --- |
| `sexual/minors`, amenaza o violencia grave | Rechazar y activar protocolo de seguridad |
| `harassment`, `hate`, `sexual`, `violence`, `self-harm` o `flagged` | Enviar a revisión |
| Sin categorías señaladas | Publicar, salvo una regla local más restrictiva |

La API no sustituye la política de privacidad, la detección de datos personales
ni la revisión humana. El modelo admite texto e imagen, no audio. Antes de
enviar contenido sensible a cualquier proveedor, aplica las políticas y el
protocolo legal correspondiente.

Documentación oficial: [OpenAI Moderation](https://developers.openai.com/api/reference/resources/moderations),
[omni-moderation-latest](https://developers.openai.com/api/docs/models/omni-moderation-latest).

## Alternativa Google Cloud

Google Cloud Natural Language ofrece moderación de texto con una franja gratuita
mensual. Mantén la misma interfaz `ExternalContentModerator`, de modo que el
proveedor puede cambiar sin tocar el dominio ni la UI. Verifica el precio y los
límites antes de activarlo: [precios actuales](https://cloud.google.com/products/natural-language/pricing).

## Cola administrativa futura

El backend debe conservar un registro de moderación con: `gossipId`, `authorId`,
proveedor/modelo, decisión, motivos, puntajes, fecha, denuncias, `reviewerId` y
decisión humana. El panel sólo necesita listar `pending` y `flagged`, y ofrecer
aprobar, rechazar, ocultar, restaurar o suspender al autor.
