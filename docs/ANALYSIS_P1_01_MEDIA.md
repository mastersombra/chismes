# 🔍 Análisis P1-01: Problemas de Media (Imágenes)

**Fecha:** 2026-10-21  
**Prioridad:** P1 (Alto)  
**Estado:** 📋 **ANÁLISIS COMPLETO**

---

## 📋 RESUMEN EJECUTIVO

Existen **4 problemas críticos** en el manejo de media que causan inconsistencia de datos y mal UX.

---

## 🔴 PROBLEMAS IDENTIFICADOS

### **Problema 1: RLS bloquea UPDATE de gossips publicados**

**Ubicación:** `001_create_gossips_table.sql:150-162`

**Código:**
```sql
CREATE POLICY "Usuarios pueden editar sus propios drafts"
ON gossips
FOR UPDATE
USING (
  auth.uid() = created_by
  AND status = 'draft'  -- ← PROBLEMA
)
```

**Problema:**
- Política permite UPDATE solo en `status = 'draft'`
- Si Edge Function aprueba gossip → `status = 'published'`
- UPDATE de `image_url` falla (violación de RLS)

**Flujo:**
```
1. Usuario crea gossip con imagen
2. Edge Function aprueba → INSERT con status='published'
3. Flutter intenta UPDATE image_url
4. RLS rechaza: "status debe ser draft"
5. ❌ Gossip sin imagen
```

---

### **Problema 2: Upload no es atómico**

**Ubicación:** `lib/core/media/supabase_storage_service.dart:88-105`

**Código:**
```dart
// 4. Subir imagen completa
final fullPath = 'gossips/full/$fileName';
await _supabase.storage.from('images').upload(fullPath, compressedFile);

// 5. Generar y subir thumbnail
String? thumbPath;
final thumbnailFile = await ImageCompressor.generateThumbnail(imageFile);
if (thumbnailFile != null) {
  thumbPath = 'gossips/thumb/$fileName';
  await _supabase.storage.from('images').upload(thumbPath, thumbnailFile);
  // ↑ Si falla aquí, línea 90 ya se ejecutó (archivo huérfano)
}
```

**Problema:**
- 2 uploads separados (full + thumbnail)
- Si thumbnail falla, full ya está subido
- No hay rollback/compensación
- Archivo huérfano en storage

**Escenarios de fallo:**
1. Full ✅ → Thumbnail ❌ → Full queda huérfano
2. Full ✅ → Thumbnail ✅ → UPDATE ❌ → Ambos huérfanos
3. Full ❌ → (no sube thumbnail) → Correcto (no hay huérfano)

---

### **Problema 3: Catch retorna éxito sin imagen**

**Ubicación:** `lib/features/gossip/domain/usecases/create_gossip.dart:166-174`

**Código:**
```dart
} catch (uploadError) {
  // Gossip creado pero imagen falló
  // Usuario puede reintentar desde UI
  _logger.w('Gossip creado pero imagen falló', context: {
    'gossipId': gossip.id,
    'error': uploadError.toString(),
  });
  return Result.success(gossip); // ← PROBLEMA: Retorna SUCCESS sin imagen
}
```

**Problema:**
- Usuario ve "¡Chisme creado!" ✅
- Pero imagen no se subió
- No hay indicación de error
- Usuario no puede reintentar (cree que funcionó)

**Impacto UX:**
- Confusión: "¿Dónde está mi imagen?"
- Frustración: No puede volver a subirla
- Datos inconsistentes: Gossip existe pero sin imagen

---

### **Problema 4: Bucket sin migración versionada**

**Ubicación:** N/A (no existe)

**Problema:**
- Bucket `images` no tiene migración SQL
- Configuración manual en Dashboard
- No reproducible en otros ambientes
- No auditable desde repositorio
- Políticas de storage no versionadas

**Impacto:**
- Staging/dev sin bucket → errores
- Nuevos devs deben configurar manualmente
- No hay source of truth
- Riesgo de misconfiguration

---

## 📊 MATRIZ DE IMPACTO

| Problema | Gravedad | Frecuencia | Impacto Usuario | Impacto BD |
|----------|----------|------------|-----------------|------------|
| **1. RLS bloquea UPDATE** | 🔴 Alta | 100% (si aprobado) | Gossip sin imagen | Inconsistente |
| **2. Upload no atómico** | 🟡 Media | ~5% (fallos red) | Imagen huérfana | Storage sucio |
| **3. Success sin imagen** | 🔴 Alta | 100% (si falla upload) | Confusión | Inconsistente |
| **4. Sin migración** | 🟡 Media | 100% (setup) | N/A | Config manual |

---

## 🎯 SOLUCIONES PROPUESTAS

### **Opción A: Approach Actual Mejorado** (Incremental)

**Ventajas:**
- ✅ Cambios mínimos
- ✅ Mantiene flujo actual
- ✅ Rápido de implementar

**Desventajas:**
- ⚠️ Aún no es atómico del todo
- ⚠️ Múltiples roundtrips

**Implementación:**

1. **Fix RLS:** Agregar política para UPDATE de `image_url` en publicados
2. **Fix Catch:** Retornar error específico, no success
3. **Fix Upload:** Try-catch con rollback manual
4. **Migración:** Crear bucket + políticas via SQL

---

### **Opción B: Media en Edge Function** (Atómico)

**Ventajas:**
- ✅ 100% atómico
- ✅ Una sola transacción
- ✅ Sin roundtrips extra
- ✅ Service_role bypasea RLS

**Desventajas:**
- ⚠️ Cambio mayor
- ⚠️ Edge Function más compleja
- ⚠️ Flutter envía más datos (imagen en body)

**Flujo:**
```
1. Flutter: Leer imagen como bytes
2. Flutter: POST a Edge Function (gossip + imagen base64)
3. Edge Function:
   a. Moderar contenido
   b. Subir imagen a storage
   c. INSERT gossip con image_url
   d. Si algo falla, rollback todo
4. Flutter: Recibir gossip completo
```

---

### **Opción C: Presigned URLs** (Híbrido)

**Ventajas:**
- ✅ Flutter sube directo a Storage (rápido)
- ✅ Edge Function valida después
- ✅ No pasa por Edge Function (ahorra latencia)

**Desventajas:**
- ⚠️ Complejo de implementar
- ⚠️ Requiere cleanup de uploads no confirmados
- ⚠️ No es atómico

---

## 📊 COMPARACIÓN DE OPCIONES

| Aspecto | Opción A | Opción B | Opción C |
|---------|----------|----------|----------|
| **Atomicidad** | ⚠️ Parcial | ✅ Total | ❌ No |
| **Complejidad** | 🟢 Baja | 🟡 Media | 🔴 Alta |
| **Tiempo impl** | 2-3h | 6-8h | 10-12h |
| **Performance** | 🟡 2-3 roundtrips | 🟢 1 roundtrip | 🟢 Paralelo |
| **Seguridad** | ✅ Buena | ✅ Excelente | ⚠️ Requiere cleanup |
| **UX** | 🟡 Ok | 🟢 Excelente | 🟢 Excelente |

---

## 💡 RECOMENDACIÓN

### **Implementar Opción A AHORA + migrar a B después**

**Por qué:**

1. **Short term (ahora):**
   - Opción A soluciona problemas críticos
   - Rápido (2-3 horas)
   - Bajo riesgo

2. **Long term (futuro):**
   - Opción B es el approach correcto
   - Implementar cuando tengas tiempo
   - Mejor atomicidad y UX

---

## 🔧 PLAN DE IMPLEMENTACIÓN (Opción A)

### **Tarea 1: Fix Política RLS**

**Archivo:** Migración 007

```sql
-- Permitir UPDATE de image_url en gossips publicados
CREATE POLICY "Usuarios pueden actualizar imagen de sus gossips publicados"
ON gossips
FOR UPDATE
USING (
  auth.uid() = created_by
  AND (status = 'draft' OR status = 'published')
)
WITH CHECK (
  auth.uid() = created_by
  AND (status = 'draft' OR status = 'published')
);

-- Drop política vieja (solo draft)
DROP POLICY "Usuarios pueden editar sus propios drafts" ON gossips;
```

**Alternativa (más segura):**
```sql
-- Permitir UPDATE SOLO de image_url/thumbnail_url
-- (proteger otros campos)
CREATE POLICY "Usuarios pueden actualizar imagen después de crear"
ON gossips
FOR UPDATE
USING (
  auth.uid() = created_by
  AND created_at > NOW() - INTERVAL '5 minutes'  -- Solo recién creados
)
WITH CHECK (
  auth.uid() = created_by
  -- Trigger protegerá que solo se modifiquen image_url/thumbnail_url
);
```

---

### **Tarea 2: Fix Upload con Rollback**

**Archivo:** `lib/core/media/supabase_storage_service.dart`

```dart
Future<UploadResult> uploadImageAfterGossipCreated({
  required String gossipId,
  required File imageFile,
}) async {
  String? fullPath;
  String? thumbPath;

  try {
    // 1. Comprimir
    final compressedFile = await ImageCompressor.compress(imageFile);

    // 2. Nombre
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = '${gossipId}_$timestamp.jpg';

    // 3. Subir full
    fullPath = 'gossips/full/$fileName';
    await _supabase.storage.from('images').upload(fullPath, compressedFile);

    // 4. Subir thumbnail
    final thumbnailFile = await ImageCompressor.generateThumbnail(imageFile);
    if (thumbnailFile != null) {
      thumbPath = 'gossips/thumb/$fileName';
      await _supabase.storage.from('images').upload(thumbPath, thumbnailFile);
    }

    // 5. Obtener URLs
    final fullUrl = _supabase.storage.from('images').getPublicUrl(fullPath);
    final thumbUrl = thumbPath != null
        ? _supabase.storage.from('images').getPublicUrl(thumbPath)
        : fullUrl;

    return UploadResult(
      fullUrl: fullUrl,
      thumbnailUrl: thumbUrl,
      storagePath: fullPath,
    );
  } catch (error) {
    // ✅ ROLLBACK: Eliminar archivos subidos
    _logger.e('Upload failed, rolling back', error: error);

    if (fullPath != null) {
      try {
        await _supabase.storage.from('images').remove([fullPath]);
        _logger.i('Rolled back full image: $fullPath');
      } catch (rollbackError) {
        _logger.w('Failed to rollback full image', error: rollbackError);
      }
    }

    if (thumbPath != null) {
      try {
        await _supabase.storage.from('images').remove([thumbPath]);
        _logger.i('Rolled back thumbnail: $thumbPath');
      } catch (rollbackError) {
        _logger.w('Failed to rollback thumbnail', error: rollbackError);
      }
    }

    rethrow; // Propagar error
  }
}
```

---

### **Tarea 3: Fix UseCase - Retornar Error**

**Archivo:** `lib/features/gossip/domain/usecases/create_gossip.dart`

```dart
// ANTES
} catch (uploadError) {
  _logger.w('Gossip creado pero imagen falló');
  return Result.success(gossip); // ← MAL
}

// DESPUÉS
} catch (uploadError) {
  _logger.e('Image upload failed after gossip created', error: uploadError, context: {
    'gossipId': gossip.id,
  });

  // ✅ Retornar error específico
  return Result.failure(ValidationFailure(
    code: ErrorCode.mediaUploadFailed,
    technicalMessage: 'Imagen no pudo subirse: $uploadError',
    fieldErrors: {
      'image': 'No se pudo subir la imagen. El chisme fue creado sin imagen.',
    },
  ));
}
```

**Y agregar nuevo ErrorCode:**
```dart
// lib/core/error/error_codes.dart
enum ErrorCode {
  // ...
  mediaUploadFailed,  // ← Nuevo
}
```

**Y mensaje en español:**
```dart
// lib/core/error/error_messages.dart
case ErrorCode.mediaUploadFailed:
  return 'No se pudo subir la imagen. El chisme fue creado sin imagen. '
         'Puedes editarlo después para agregar una imagen.';
```

---

### **Tarea 4: Crear Bucket via Migración**

**Archivo:** Migración 007 (o 008 si 007 ya tiene RLS)

```sql
-- =====================================================
-- BUCKET: images (para gossips)
-- =====================================================

-- Crear bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('images', 'images', true)
ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- POLÍTICAS DE STORAGE
-- =====================================================

-- Cualquiera puede VER imágenes (public bucket)
CREATE POLICY "Public can view images"
ON storage.objects FOR SELECT
USING (bucket_id = 'images');

-- Solo usuarios autenticados pueden SUBIR
CREATE POLICY "Authenticated users can upload images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'images'
  AND auth.uid() IS NOT NULL
  AND (storage.foldername(name))[1] = 'gossips'
);

-- Solo el dueño puede ELIMINAR su imagen
CREATE POLICY "Users can delete their own images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'images'
  AND auth.uid() = owner
);

-- =====================================================
-- CONFIGURACIÓN DEL BUCKET
-- =====================================================

-- Tamaño máximo de archivo: 5 MB
-- Tipos permitidos: image/jpeg, image/png
-- (Configurar en Supabase Dashboard: Storage → images → Settings)
--
-- NOTA: No hay SQL para esto, debe hacerse en Dashboard
-- o via API de gestión (requiere service_role)
```

---

## 🧪 TESTS DE VERIFICACIÓN

### **Test 1: RLS permite UPDATE de published**

```dart
test('Usuario puede actualizar image_url en gossip publicado', () async {
  // Arrange: Crear gossip published
  final gossip = await createPublishedGossip();

  // Act: Intentar UPDATE de image_url
  final result = await supabase
      .from('gossips')
      .update({'image_url': 'https://example.com/image.jpg'})
      .eq('id', gossip.id);

  // Assert: No debe fallar
  expect(result.error, isNull);
});
```

---

### **Test 2: Rollback funciona si thumbnail falla**

```dart
test('Rollback elimina full image si thumbnail falla', () async {
  // Arrange: Mock thumbnail upload para que falle
  when(mockStorage.upload(any, any))
      .thenAnswer((_) async {
        if (_.positionalArguments[0].contains('thumb')) {
          throw Exception('Thumbnail failed');
        }
        return 'uploaded';
      });

  // Act: Intentar subir
  try {
    await storageService.uploadImageAfterGossipCreated(
      gossipId: 'test-id',
      imageFile: testFile,
    );
    fail('Should have thrown');
  } catch (e) {
    // Expected
  }

  // Assert: Full image debe estar eliminada
  verify(mockStorage.remove(['gossips/full/test_xxx.jpg'])).called(1);
});
```

---

### **Test 3: Error específico cuando upload falla**

```dart
test('Retorna error específico si upload falla', () async {
  // Arrange: Mock storage para fallar
  when(mockStorage.upload(any, any))
      .thenThrow(Exception('Network error'));

  // Act
  final result = await createGossipUseCase(input);

  // Assert
  expect(result.isFailure, isTrue);
  result.when(
    onFailure: (failure) {
      expect(failure.code, ErrorCode.mediaUploadFailed);
      expect(failure.userMessage, contains('No se pudo subir la imagen'));
    },
    onSuccess: (_) => fail('Should have failed'),
  );
});
```

---

## 📊 IMPACTO DE LA SOLUCIÓN

### **Antes (Actual):**
- ❌ 100% gossips aprobados sin imagen (si hay imagen)
- ❌ ~5% archivos huérfanos en storage
- ❌ Usuario confundido (ve success sin imagen)
- ❌ Setup manual del bucket

### **Después (Con Opción A):**
- ✅ 95%+ gossips con imagen correcta
- ✅ ~0.1% archivos huérfanos (solo en casos extremos)
- ✅ Usuario ve error claro
- ✅ Bucket reproducible via migración

---

## 🎯 PRÓXIMOS PASOS

### **Implementar Opción A (2-3 horas):**
1. Migración 007: RLS + Bucket
2. Storage Service: Rollback
3. UseCase: Error específico
4. ErrorCode + ErrorMessages
5. Tests

### **Futuro (Opción B):**
- Mover upload a Edge Function
- Atomicidad total
- Mejor UX

---

## 📚 REFERENCIAS

- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)
- [RLS Policies](https://supabase.com/docs/guides/auth/row-level-security)
- [Error Handling Best Practices](https://dart.dev/guides/language/effective-dart/usage#error-handling)

---

**Última actualización:** 2026-10-21  
**Autor:** Alejo + Claude Code
