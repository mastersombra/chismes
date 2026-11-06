# Requerimientos: Idempotencia en Backend para Producción

## Problema Actual

### Duplicados Secuenciales en Cliente
Tras publicar un chisme, el formulario se resetea y el usuario navega a Inicio. Sin embargo, la protección actual solo cubre envíos simultáneos (doble submit rápido), no envíos secuenciales.

**Escenario de riesgo:**
1. Usuario publica chisme A
2. Formulario se limpia
3. Usuario escribe chisme B
4. Si hay un fallo de red, usuario reintentaría
5. Sin idempotencia, podría crear duplicados

### Duplicados por Fallo de Caché Local
En `GossipRepositoryImpl.create`, si la creación remota tiene éxito pero la caché local falla, la operación se considera exitosa. Si el usuario reintentara, podría crear duplicados.

**Código actual:**
```dart
final result = await remoteDataSource.create(input);

// Caché local es no bloqueante
try {
  await localDataSource.save(model);
} catch (e) {
  // Log error pero no fallar la operación
  logger.error('Failed to save to local cache: $e');
}

return result;
```

## Solución: Idempotencia en Backend

### Estrategia de Clave de Idempotencia

Cada petición de creación debe incluir una clave única que identifique la operación. El servidor verifica si ya procesó esa clave antes de crear el chisme.

**Clave de idempotencia recomendada:**
```
idempotency_key = sha256(userId + timestamp + hash(content))
```

**Componentes:**
- `userId`: Identificador único del usuario autenticado
- `timestamp`: Timestamp en milisegundos (para unicidad temporal)
- `hash(content)`: Hash del contenido del chisme (subject + content + media)

### Implementación en Cliente

#### 1. Generar Clave de Idempotencia
```dart
class IdempotencyKeyGenerator {
  String generate({
    required String userId,
    required String subject,
    required String content,
    String? imageUrl,
    String? audioUrl,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final contentHash = _hashContent(subject, content, imageUrl, audioUrl);
    final combined = '$userId:$timestamp:$contentHash';
    return _sha256(combined);
  }

  String _hashContent(String subject, String content, String? imageUrl, String? audioUrl) {
    final buffer = StringBuffer();
    buffer.write(subject);
    buffer.write(content);
    buffer.write(imageUrl ?? '');
    buffer.write(audioUrl ?? '');
    return _sha256(buffer.toString());
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = crypto.sha256.convert(bytes);
    return digest.toString();
  }
}
```

#### 2. Incluir en CreateGossipInput
```dart
class CreateGossipInput {
  final String countryId;
  final String regionId;
  final String cityId;
  final String subject;
  final String content;
  final String? audioUrl;
  final String? imageUrl;
  final PublishAs publishedAs;

  // ⚠️ Clave de idempotencia para prevenir duplicados
  final String idempotencyKey;

  CreateGossipInput({
    required this.countryId,
    required this.regionId,
    required this.cityId,
    required this.subject,
    required this.content,
    this.audioUrl,
    this.imageUrl,
    required this.publishedAs,
    required this.idempotencyKey,
  });
}
```

#### 3. Generar en Controller
```dart
class AddGossipController {
  final IdempotencyKeyGenerator _idempotencyKeyGenerator = IdempotencyKeyGenerator();

  Future<Gossip?> submit() async {
    // ... validación ...

    final idempotencyKey = _idempotencyKeyGenerator.generate(
      userId: _currentUserId, // Debe venir de auth
      subject: _state.subject,
      content: _state.content,
      imageUrl: _state.imageUrl,
      audioUrl: _state.audioUrl,
    );

    final input = CreateGossipInput(
      countryId: _state.selectedCountryId ?? '',
      regionId: _state.selectedRegionId ?? '',
      cityId: _state.selectedCityId ?? '',
      subject: _state.subject.trim(),
      content: _state.content.trim(),
      audioUrl: _state.audioUrl,
      imageUrl: _state.imageUrl,
      publishedAs: _state.publishedAs,
      idempotencyKey: idempotencyKey,
    );

    final result = await createGossip(input);
    // ...
  }
}
```

### Implementación en Backend (Firestore)

#### 1. Colección de Idempotency Keys
```dart
// Colección: idempotency_keys/{key}
{
  "key": "abc123...",
  "userId": "user-1",
  "gossipId": "gossip-1",
  "createdAt": "2024-01-15T10:30:00.000Z",
  "expiresAt": "2024-01-15T11:30:00.000Z", // 1 hora TTL
}
```

#### 2. Cloud Function para Crear Gossip
```dart
exports.createGossip = functions.https.onCall(async (data, context) => {
  // 1. Verificar autenticación
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { idempotencyKey, ...gossipData } = data;

  // 2. Verificar clave de idempotencia
  const idempotencyRef = admin.firestore()
    .collection('idempotency_keys')
    .doc(idempotencyKey);

  const idempotencyDoc = await idempotencyRef.get();

  if (idempotencyDoc.exists) {
    // Ya procesado, retornar el chisme existente
    const existingData = idempotencyDoc.data();
    const gossipRef = admin.firestore()
      .collection('gossips')
      .doc(existingData.gossipId);

    const gossipDoc = await gossipRef.get();

    return {
      success: true,
      gossip: gossipDoc.data(),
      idempotent: true,
    };
  }

  // 3. Crear chisme
  const gossipRef = admin.firestore()
    .collection('gossips')
    .doc();

  const gossipData = {
    id: gossipRef.id,
    userId,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    status: 'pending_moderation',
    moderationStatus: 'pending',
    reportedCount: 0,
    visibility: 'public',
    ...gossipData,
  };

  await gossipRef.set(gossipData);

  // 4. Guardar clave de idempotencia
  await idempotencyRef.set({
    key: idempotencyKey,
    userId,
    gossipId: gossipRef.id,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    expiresAt: new Date(Date.now() + 3600000), // 1 hora
  });

  return {
    success: true,
    gossip: gossipData,
    idempotent: false,
  };
});
```

#### 3. TTL para Claves Expiradas
```dart
// Cloud Function para limpiar claves expiradas
exports.cleanupIdempotencyKeys = functions.pubsub
  .schedule('every 1 hour')
  .onRun(async (context) => {
    const now = new Date();
    const expiredKeys = await admin.firestore()
      .collection('idempotency_keys')
      .where('expiresAt', '<', now)
      .get();

    const batch = admin.firestore().batch();
    expiredKeys.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Cleaned up ${expiredKeys.size} expired idempotency keys`);
  });
```

### Supabase RLS Policies

```sql
-- Tabla idempotency_keys: Solo servidor puede escribir
ALTER TABLE idempotency_keys ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Solo Edge Functions pueden escribir"
  ON idempotency_keys
  FOR ALL
  USING (false);

-- Tabla gossips: Usuarios pueden leer sus propios chismes
ALTER TABLE gossips ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios pueden leer sus chismes"
  ON gossips FOR SELECT
  USING (auth.uid() = created_by);

-- La creación es manejada por Edge Functions con service_role key
```

### Estrategias de Reintento

#### 1. Reintento Automático con Mismo Key
```dart
class GossipRepositoryImpl {
  Future<Result<Failure, Gossip>> create(CreateGossipInput input) async {
    const maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final result = await remoteDataSource.create(input);

        // Si el servidor retorna idempotent: true, es un reintento exitoso
        if (result.isIdempotent) {
          logger.info('Request was idempotent, returning existing gossip');
        }

        return result;
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          return Result.failure(ServerFailure(code: ErrorCode.networkError));
        }
        await Future.delayed(Duration(seconds: attempt * 2)); // Exponential backoff
      }
    }

    return Result.failure(ServerFailure(code: ErrorCode.networkError));
  }
}
```

#### 2. Reintento Manual por Usuario
Si el usuario reintentó manualmente tras un error, la misma clave de idempotencia prevendrá duplicados.

### Ventajas de Idempotencia

1. **Previene duplicados**: Mismo contenido + mismo usuario = solo un chisme
2. **Permite reintentos seguros**: Usuario puede reintentar sin crear duplicados
3. **Tolerancia a fallos de red**: Reintentos automáticos no crean duplicados
4. **Auditoría**: Claves de idempotencia registran operaciones
5. **TTL**: Claves expiran para no crecer indefinidamente

### Consideraciones de Seguridad

1. **No confiar solo en cliente**: El servidor debe validar la clave
2. **No exponer clave de idempotencia**: No es secreto, pero no debe ser manipulable
3. **TTL razonable**: 1 hora es suficiente para reintentos, no más
4. **Rate limiting**: Combinar con límites de tasa para prevenir abuso

### Tests Requeridos

- Generación de clave de idempotencia única
- Reintento con misma clave retorna chisme existente
- Reintento con clave diferente crea nuevo chisme
- Clave expirada permite nueva creación
- TTL de claves funciona correctamente
- Cloud Function valida autenticación
- Cloud Function deriva campos correctamente

### Prioridades

1. **Alta**: Implementar generación de clave en cliente
2. **Alta**: Implementar Cloud Function con idempotencia
3. **Media**: Implementar limpieza de claves expiradas
4. **Media**: Implementar reintento automático con exponential backoff
5. **Baja**: Implementar TTL en Firestore (requiere extension)

### Alternativa: Deduplicación por Contenido

Si no se desea usar claves de idempotencia, el servidor puede deduplicar por contenido:

```dart
// Cloud Function con deduplicación por hash
const contentHash = sha256(subject + content + imageUrl + audioUrl);

const existingGossip = await admin.firestore()
  .collection('gossips')
  .where('userId', '==', userId)
  .where('contentHash', '==', contentHash)
  .where('createdAt', '>', new Date(Date.now() - 3600000)) // Última hora
  .get();

if (!existingGossip.empty) {
  return {
    success: true,
    gossip: existingGossip.docs[0].data(),
    duplicate: true,
  };
}
```

**Desventaja:** No permite reintentos con contenido modificado (correcciones).
