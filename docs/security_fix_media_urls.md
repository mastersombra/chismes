# Security Fix: Media URLs - Audio Cuarentena

**Fecha:** 2026-10-22  
**Issue:** Vulnerabilidad P0 - Cliente puede pasar URLs arbitrarias de audio  
**Status:** ✅ RESUELTO

---

## 📋 Problema Original

### Vulnerabilidad Identificada

La Edge Function `moderate-gossip` aceptaba `audio_url` arbitraria del cliente:

```typescript
// ❌ VULNERABLE
interface CreateGossipRequest {
  audio_url?: string | null  // Cliente puede pasar cualquier URL
}
```

**Riesgo:**
- Cliente malicioso puede pasar `https://evil-tracker.com/audio.mp3`
- Trackea IP/dispositivo de todos los usuarios que escuchan el audio
- Puede servir contenido malicioso
- No hay validación de origen/dominio

**Impacto:**
- Privacidad comprometida (tracking externo)
- Posible distribución de malware
- Sin control sobre contenido antes de moderación

---

## ✅ Solución Implementada

### Arquitectura de Cuarentena para Audio

Implementamos el **mismo patrón de seguridad que imagen**, con buckets de cuarentena:

```
Cliente → audio_base64 → Cuarentena (privado) → Validación → Moderación → Público
```

### Cambios Realizados

#### 1. **Migración 010: Buckets de Audio** (`010_secure_audio_quarantine.sql`)

**Buckets creados:**
- `audio-quarantine` (privado): Uploads iniciales, validación
- `audio` (público): Solo archivos aprobados

**Columnas agregadas:**
- `audio_storage_path` en tabla `gossips` (fuente de verdad)

**Funciones de cleanup:**
- `cleanup_audio_quarantine_files()`: Limpia cuarentena >24h
- `cleanup_orphaned_audio()`: Limpia audios huérfanos >7 días

**RPC actualizado:**
- `create_gossip_draft()` ahora acepta `audio_storage_path`

#### 2. **Migración 011: Actualizar upsert_gossip_idempotent** (`011_add_audio_storage_path_to_upsert.sql`)

- Agregado parámetro `p_audio_storage_path` al RPC
- Mantiene compatibilidad con código existente

#### 3. **Edge Function: Validación y Upload** (`moderate-gossip/`)

**validation.ts:**
```typescript
// ✅ SEGURO: Solo base64
interface CreateGossipRequest {
  audio_base64?: string | null  // Cliente NUNCA pasa URL directa
}

function validateAudioBase64(value: any): ValidationError | null {
  // Valida base64, límite 15 MB
}
```

**index.ts:**
```typescript
// Constantes de validación
const AUDIO_VALIDATION = {
  MAX_SIZE_BYTES: 10 * 1024 * 1024, // 10 MB
  ALLOWED_MIME_TYPES: ['audio/mpeg', 'audio/mp3', 'audio/mp4', 'audio/m4a', 'audio/x-m4a', 'audio/wav'],
}

// Detectar MIME real (magic bytes)
function detectAudioMimeType(data: Uint8Array): string {
  // MP3: FF FB o FF F3 o ID3v2: 49 44 33
  // M4A/MP4: ftyp box
  // WAV: RIFF ... WAVE
}
```

**Funciones de upload:**
- `uploadAudioToQuarantine()`: Sube a bucket privado, valida MIME real
- `moveAudioToPublicBucket()`: Mueve a público después de aprobar moderación
- `deleteAudioFromQuarantine()`: Cleanup
- `deleteAudioFromPublicBucket()`: Rollback

**Flujo integrado:**
```typescript
// 1. Upload imagen a cuarentena
if (body.image_base64) { ... }

// 2. Upload audio a cuarentena
if (body.audio_base64) { ... }

// 3. Moderar contenido
const moderationResult = await moderateContent(...)

// 4. Si rechazado: Limpiar TODO (imagen + audio)
if (moderationResult.verdict === 'reject') {
  if (quarantinePath) await deleteFromQuarantine(...)
  if (audioQuarantinePath) await deleteAudioFromQuarantine(...)
}

// 5. Si aprobado: Mover TODO a público
if (moderationResult.verdict === 'publish') {
  if (quarantinePath) publicImageResult = await moveToPublicBucket(...)
  if (audioQuarantinePath) publicAudioResult = await moveAudioToPublicBucket(...)
}

// 6. INSERT gossip con storage_path (fuente de verdad)
await supabaseAdmin.rpc('upsert_gossip_idempotent', {
  p_audio_url: publicAudioResult?.audioUrl || null,
  p_audio_storage_path: publicAudioResult?.storagePath || null,
  ...
})
```

---

## 🔒 Garantías de Seguridad

### ✅ Lo que AHORA es seguro:

1. **Cliente NO puede pasar URLs arbitrarias**
   - Solo acepta `audio_base64` (contenido controlado)
   - URLs se generan en servidor después de aprobar

2. **Validación MIME real (magic bytes)**
   - No confía en extensión del cliente
   - Detecta formato real del archivo

3. **Audio privado hasta aprobar moderación**
   - Bucket `audio-quarantine` es privado
   - Solo service_role puede acceder

4. **Rollback completo en errores**
   - Si falla moderación: Elimina de cuarentena
   - Si falla upload a público: Elimina TODO

5. **storage_path como fuente de verdad**
   - URLs públicas pueden regenerarse
   - Path canónico persiste en DB

---

## 📊 Flujo de Seguridad Completo

```
┌─────────────┐
│   Cliente   │
└──────┬──────┘
       │ audio_base64
       ↓
┌──────────────────────┐
│ Edge Function        │
│ - Valida base64      │
│ - Decodifica         │
│ - Valida MIME real   │
│ - Valida tamaño      │
└──────┬───────────────┘
       │
       ↓
┌──────────────────────┐
│ audio-quarantine     │  ← Privado (solo service_role)
│ (bucket privado)     │
└──────┬───────────────┘
       │
       ↓
┌──────────────────────┐
│ Moderación           │
│ - Reglas locales     │
│ - OpenAI API         │
└──────┬───────────────┘
       │
       ├── ❌ Rechazado → Eliminar de cuarentena
       │
       ↓ ✅ Aprobado
┌──────────────────────┐
│ audio (bucket público)│
│ - Mover de cuarentena│
│ - Generar URL pública│
│ - Eliminar cuarentena│
└──────┬───────────────┘
       │
       ↓
┌──────────────────────┐
│ INSERT gossip        │
│ - audio_url (URL)    │
│ - audio_storage_path │
└──────────────────────┘
```

---

## 🧪 Testing

### Verificar buckets creados:

```sql
SELECT id, name, public
FROM storage.buckets
WHERE id IN ('audio-quarantine', 'audio');
```

**Resultado esperado:**
```
audio-quarantine | false
audio            | true
```

### Verificar columna agregada:

```sql
\d gossips
```

**Debe incluir:**
```
audio_storage_path | text | 
```

### Verificar funciones:

```sql
SELECT proname FROM pg_proc
WHERE proname IN (
  'cleanup_audio_quarantine_files',
  'cleanup_orphaned_audio',
  'upsert_gossip_idempotent'
);
```

---

## 📦 Archivos Modificados

### Migraciones:
- `010_secure_audio_quarantine.sql` (nuevo)
- `011_add_audio_storage_path_to_upsert.sql` (nuevo)

### Edge Function:
- `validation.ts` (modificado)
  - Cambió `audio_url` → `audio_base64`
  - Agregó `validateAudioBase64()`
- `index.ts` (modificado)
  - Agregó constantes `AUDIO_VALIDATION`
  - Agregó `detectAudioMimeType()`
  - Agregó funciones de upload/move/delete de audio
  - Integró flujo completo con rollbacks

---

## 🚀 Próximos Pasos

### Opcional (mejoras futuras):

1. **Moderación de audio (contenido)**
   - Transcripción con Whisper API
   - Moderación de texto transcrito

2. **Validación de duración**
   - Limitar audio a X minutos

3. **Compresión automática**
   - Reducir bitrate si es muy alto

4. **Thumbnails/waveform**
   - Generar visualización del audio

---

## 📚 Referencias

- **Migración 007:** `007_secure_media_quarantine.sql` (patrón imagen)
- **ADR-003:** Decisión de usar String simple para URLs (no MediaReference)
- **Supabase Storage:** https://supabase.com/docs/guides/storage
- **Magic Bytes:** https://en.wikipedia.org/wiki/List_of_file_signatures

---

## ✅ Checklist de Implementación

- [x] Crear buckets `audio-quarantine` (privado) y `audio` (público)
- [x] Agregar columna `audio_storage_path` a tabla gossips
- [x] Crear funciones de cleanup
- [x] Actualizar RPCs (create_gossip_draft, upsert_gossip_idempotent)
- [x] Cambiar `audio_url` → `audio_base64` en validation
- [x] Agregar validación de audio base64
- [x] Implementar detectAudioMimeType()
- [x] Implementar uploadAudioToQuarantine()
- [x] Implementar moveAudioToPublicBucket()
- [x] Implementar funciones de cleanup/rollback
- [x] Integrar flujo en handler principal
- [x] Agregar rollbacks en todos los puntos de error
- [x] Aplicar migraciones a Supabase remoto
- [x] Documentar cambios

---

**FIN DEL DOCUMENTO**
