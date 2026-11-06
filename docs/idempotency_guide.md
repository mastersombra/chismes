# Guía de Idempotencia para CreateGossip

## ¿Qué es Idempotencia?

**Idempotencia** es la propiedad de una operación que puede ejecutarse múltiples veces sin causar efectos secundarios no deseados.

**Operación IDEMPOTENTE:** Si la ejecutas 1 vez o 100 veces, el resultado final es el mismo.

**Operación NO IDEMPOTENTE:** Cada ejecución causa un efecto diferente.

## Ejemplos Cotidianos

### IDEMPOTENTE
- Leer un libro: Si lees la misma página 10 veces, el contenido no cambia
- Consultar saldo bancario: Si consultas 5 veces, tu saldo no cambia
- Marcar email como leído: Si haces click 10 veces, sigue estando "leído"

### NO IDEMPOTENTE
- Transferir dinero: Si transfieres $100, 10 veces, transfieres $1000 (malo)
- Publicar chisme: Si publicas el mismo chisme 10 veces, se crean 10 chismes duplicados (malo)
- Enviar email: Si envías el mismo email 10 veces, se envían 10 emails (malo)

## En Tu App (Crear Gossip)

### Problema SIN Idempotencia

```dart
// Usuario crea un chisme
final gossip = await createGossip(input);

// Si el usuario hace click 10 veces en "Publicar" rápidamente
// → Se crean 10 chismes duplicados ❌
```

**Escenarios problemáticos:**
1. Usuario hace click doble → crea 2 chismes idénticos
2. Network timeout → usuario piensa que falló, vuelve a intentar → crea duplicado
3. App se cierra inesperadamente → usuario reabre y reenvía → crea duplicado
4. Retry automático → sistema reintenta automáticamente → crea duplicado

### Solución CON Idempotency

```dart
// Usuario crea un chisme con una clave única
final input = CreateGossipInput(
  countryId: 'AR',
  // ... otros campos ...
  idempotencyKey: 'uuid-12345', // Clave única para esta operación
);

// Primer intento
final gossip1 = await createGossip(input); // ✅ Crea el chisme

// Segundo intento (mismo idempotencyKey)
final gossip2 = await createGossip(input); // ✅ Retorna el mismo chisme, NO crea duplicado

// Tercer intento (mismo idempotencyKey)
final gossip3 = await createGossip(input); // ✅ Retorna el mismo chisme, NO crea duplicado
```

## Implementación

### 1. Cliente Genera Clave Única

```dart
// Flutter app genera un UUID para cada intento de creación
final idempotencyKey = Uuid().v4(); // Ej: '550e8400-e29b-41d4-a716-446655440000'

final input = CreateGossipInput(
  countryId: 'AR',
  regionId: 'CBA',
  cityId: 'Cordoba',
  subject: 'Chisme sobre Juan',
  content: 'Juan dijo que...',
  publishedAs: PublishAs.anonymous,
  idempotencyKey: idempotencyKey, // NUEVO CAMPO
);
```

### 2. Backend Verifica si Ya Existe

```javascript
// Cloud Function createGossip
exports.createGossip = functions.https.onCall(async (data, context) => {
  const { idempotencyKey, ...gossipData } = data;

  // Verificar si ya existe un chisme con este idempotencyKey
  const existingDoc = await admin.firestore()
    .collection('gossips')
    .where('idempotencyKey', '==', idempotencyKey)
    .limit(1)
    .get();

  if (!existingDoc.empty) {
    // Ya existe, retornar el chisme existente
    return existingDoc.docs[0].data();
  }

  // No existe, crear nuevo chisme
  const newDoc = await admin.firestore().collection('gossips').add({
    ...gossipData,
    idempotencyKey: idempotencyKey, // Guardar la clave
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return newDoc.data();
});
```

### 3. Resultado

```dart
// Primer intento
final result1 = await createGossip(input);
// Resultado: { id: 'abc123', idempotencyKey: 'uuid-12345', ... } // NUEVO chisme

// Segundo intento (misma clave)
final result2 = await createGossip(input);
// Resultado: { id: 'abc123', idempotencyKey: 'uuid-12345', ... } // MISMO chisme (no duplicado)
```

## Cambios en Tu Código

### CreateGossipInput

```dart
class CreateGossipInput extends Equatable {
  final String countryId;
  final String regionId;
  final String cityId;
  final String subject;
  final String content;
  final String? audioUrl;
  final String? imageUrl;
  final PublishAs publishedAs;
  final String idempotencyKey; // NUEVO CAMPO

  const CreateGossipInput({
    required this.countryId,
    required this.regionId,
    required this.cityId,
    required this.subject,
    required this.content,
    this.audioUrl,
    this.imageUrl,
    required this.publishedAs,
    required this.idempotencyKey, // NUEVO CAMPO
  });

  @override
  List<Object?> get props => [
    countryId,
    regionId,
    cityId,
    subject,
    content,
    audioUrl,
    imageUrl,
    publishedAs,
    idempotencyKey, // NUEVO CAMPO
  ];
}
```

### AddGossipController

```dart
class AddGossipController extends ChangeNotifier {
  Future<Gossip?> submit() async {
    // Generar idempotencyKey
    final idempotencyKey = _generateIdempotencyKey();

    final input = CreateGossipInput(
      countryId: _state.selectedCountryId!,
      regionId: _state.selectedRegionId!,
      cityId: _state.selectedCityId!,
      subject: _state.subject,
      content: _state.content,
      audioUrl: _state.audioUrl,
      imageUrl: _state.imageUrl,
      publishedAs: _state.publishedAs,
      idempotencyKey: idempotencyKey, // NUEVO
    );

    final result = await createGossip(input);
    // ...
  }

  String _generateIdempotencyKey() {
    // Generar UUID único
    // Usa: uuid package de Dart
    return Uuid().v4();
  }
}
```

### pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  uuid: ^4.0.0  # NUEVO
```

## Buenas Prácticas

### 1. UUID vs Timestamp

```dart
// ✅ BUENO: UUID (único globalmente)
final idempotencyKey = Uuid().v4(); // '550e8400-e29b-41d4-a716-446655440000'

// ❌ MALO: Timestamp (puede colisionar)
final idempotencyKey = DateTime.now().toIso8601String(); // '2026-09-28T10:30:00.000Z'
// Si el usuario hace click rápido, mismo timestamp → colisión
```

### 2. Duración de la Clave

```javascript
// Firestore: Agregar TTL a la clave
// Después de 24 horas, la clave expira
// Esto permite reintentos antiguos después de un tiempo
const idempotencyKeyExpiry = 24 * 60 * 60 * 1000; // 24 horas en ms
```

### 3. Índice en Firestore

```javascript
// Crear índice en idempotencyKey para búsquedas rápidas
// gossips collection → idempotencyKey (ascending)
```

## ¿Cuándo Es Necesario?

### SI Necesitas Idempotency:
- ✅ Operaciones de CREACIÓN (POST)
- ✅ Operaciones que modifican estado (PUT, PATCH)
- ✅ Operaciones que tienen efectos secundarios (enviar email, cobrar dinero)
- ✅ Operaciones costosas (procesar imágenes, videos)

### NO Necesitas Idempotency:
- ❌ Operaciones de LECTURA (GET) - ya son idempotentes por naturaleza
- ❌ Operaciones que solo retornan datos sin efectos secundarios

## En Tu Caso Específico

**Crear Gossip:** SÍ necesita idempotency
- Es una operación de CREACIÓN
- Tiene efectos secundarios (publicar en feed)
- Puede causar duplicados si se reintentar

**Leer Gossips:** NO necesita idempotency
- Es una operación de LECTURA
- No tiene efectos secundarios
- Ya es idempotente por naturaleza

## Resumen

**Idempotency = "Puedo ejecutar esto muchas veces sin problemas"**

En tu app:
- **Sin idempotency:** Usuario hace click 10 veces → 10 chismes duplicados ❌
- **Con idempotency:** Usuario hace click 10 veces → 1 chisme creado ✅

## Estado Actual

- ✅ Campo `idempotencyKey` agregado en `CreateGossipInput`
- ✅ Generación de UUID implementada en `AddGossipController`
- ✅ Paquete `uuid` agregado en `pubspec.yaml`
- ✅ Tests actualizados para incluir `idempotencyKey`
- ⏳ Pendiente: Implementación en backend (Cloud Function) cuando se integre Firestore
- ⏳ Pendiente: Índice en Firestore para búsquedas rápidas
