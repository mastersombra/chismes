# Estrategia de Compensación Automática para Media Upload

**Bloqueador:** #6 - Media privado con cleanup

**Estado:** 🟡 70% → 85%

**Problema:** Si falla la creación del gossip después de subir media a quarantine, los archivos quedan huérfanos.

---

## 🎯 ESTRATEGIA ACTUAL

### Flujo Actual (Sin Compensación)
```
1. Cliente sube imagen/audio → image-quarantine/audio-quarantine
2. Cliente llama moderate-gossip con URLs
3. moderate-gossip crea gossip en BD
4. [Futuro] Edge Function mueve de quarantine → público

❌ PROBLEMA: Si falla paso 3 o 4 → archivos quedan en quarantine forever
```

### Cleanup Existente (Parcial)
```sql
-- 007: cleanup_old_quarantine_images()
-- 010: cleanup_old_quarantine_audio()
-- Ejecutan vía pg_cron cada hora
-- Eliminan archivos > 24 horas
```

**Limitación:** 24 horas es mucho tiempo para archivos huérfanos

---

## ✅ ESTRATEGIA MEJORADA

### Opción A: Compensación Inmediata (Recomendada)
```typescript
// moderate-gossip/index.ts

async function createGossipWithCompensation(body, userId) {
  let uploadedFiles = [];
  
  try {
    // 1. Validar que archivos existen en quarantine
    if (body.image_url) {
      const exists = await verifyQuarantineFile(body.image_url);
      if (exists) uploadedFiles.push({type: 'image', url: body.image_url});
    }
    
    if (body.audio_url) {
      const exists = await verifyQuarantineFile(body.audio_url);
      if (exists) uploadedFiles.push({type: 'audio', url: body.audio_url});
    }

    // 2. Crear gossip
    const gossip = await upsertGossip(...);
    
    // 3. Si todo OK, return
    return gossip;
    
  } catch (error) {
    // 4. COMPENSACIÓN: Eliminar archivos subidos
    console.log('🧹 Cleaning up uploaded files due to error');
    
    for (const file of uploadedFiles) {
      try {
        await supabaseAdmin.storage
          .from(file.type === 'image' ? 'image-quarantine' : 'audio-quarantine')
          .remove([extractPath(file.url)]);
        
        console.log(`✅ Cleaned up ${file.type}: ${file.url}`);
      } catch (cleanupError) {
        console.error(`❌ Failed to cleanup ${file.url}:`, cleanupError);
        // Log a error_logs para investigación manual
      }
    }
    
    throw error; // Re-throw para que cliente sepa que falló
  }
}
```

**Ventajas:**
- ✅ Compensación inmediata (no espera 24h)
- ✅ Reduce storage usado innecesariamente
- ✅ Más limpio para usuario (puede reintentar sin duplicados)

**Desventajas:**
- 🟡 Código más complejo
- 🟡 Requiere permisos de service_role

---

### Opción B: Reducir TTL de Cleanup (Alternativa Simple)
```sql
-- Cambiar de 24 horas → 1 hora
CREATE OR REPLACE FUNCTION cleanup_old_quarantine_images()
RETURNS INTEGER AS $$
DECLARE
  deleted_count INTEGER;
BEGIN
  -- OLD: created_at < NOW() - INTERVAL '24 hours'
  -- NEW: created_at < NOW() - INTERVAL '1 hour'
  
  DELETE FROM storage.objects
  WHERE bucket_id = 'image-quarantine'
    AND created_at < NOW() - INTERVAL '1 hour';
  
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;
```

**Ventajas:**
- ✅ Muy simple
- ✅ No requiere cambios en Edge Function

**Desventajas:**
- 🟡 Sigue dejando archivos huérfanos por 1 hora
- 🟡 No diferencia entre:
  - Archivos en proceso de creación
  - Archivos huérfanos por error

---

## 🚀 IMPLEMENTACIÓN RECOMENDADA

### Fase 1: Compensación Inmediata (Esta Sesión)
1. Agregar función `verifyQuarantineFile()` en moderate-gossip
2. Agregar bloque try-catch con cleanup
3. Log de compensaciones en error_logs

### Fase 2: Reducir TTL (Backup)
1. Cambiar cleanup de 24h → 2h
2. Esto cubre casos donde compensación falle

### Fase 3: Monitoring (Post-Beta)
1. Dashboard de archivos en quarantine > 1h
2. Alertas si quarantine crece anormalmente

---

## 📝 CÓDIGO A IMPLEMENTAR

### 1. Función Helper: Verificar Archivo en Quarantine
```typescript
async function verifyQuarantineFile(
  url: string,
  supabase: SupabaseClient
): Promise<boolean> {
  try {
    const path = extractPathFromUrl(url);
    const bucket = url.includes('image-quarantine') 
      ? 'image-quarantine' 
      : 'audio-quarantine';
    
    const { data, error } = await supabase.storage
      .from(bucket)
      .list(dirname(path), {
        search: basename(path),
      });
    
    if (error) return false;
    
    return data && data.length > 0;
  } catch (err) {
    console.error('Error verifying quarantine file:', err);
    return false;
  }
}

function extractPathFromUrl(url: string): string {
  // https://xxx.supabase.co/storage/v1/object/public/bucket/path/file.jpg
  // → path/file.jpg
  const parts = url.split('/storage/v1/object/');
  if (parts.length < 2) return '';
  
  const pathPart = parts[1].split('/').slice(2).join('/'); // Skip bucket name
  return pathPart;
}

function dirname(path: string): string {
  const parts = path.split('/');
  return parts.slice(0, -1).join('/');
}

function basename(path: string): string {
  const parts = path.split('/');
  return parts[parts.length - 1];
}
```

### 2. Función de Compensación
```typescript
async function cleanupQuarantineFiles(
  files: Array<{type: 'image' | 'audio', url: string}>,
  supabase: SupabaseClient
): Promise<void> {
  for (const file of files) {
    try {
      const path = extractPathFromUrl(file.url);
      const bucket = file.type === 'image' 
        ? 'image-quarantine' 
        : 'audio-quarantine';
      
      const { error } = await supabase.storage
        .from(bucket)
        .remove([path]);
      
      if (error) {
        console.error(`❌ Failed to cleanup ${file.url}:`, error);
      } else {
        console.log(`✅ Cleaned up ${file.type}: ${path}`);
      }
    } catch (err) {
      console.error(`❌ Exception cleaning ${file.url}:`, err);
    }
  }
}
```

### 3. Integración en moderate-gossip
```typescript
// En el main handler, después de validaciones

const uploadedFiles: Array<{type: 'image' | 'audio', url: string}> = [];

try {
  // Track uploaded files
  if (body.image_url) {
    const exists = await verifyQuarantineFile(body.image_url, supabaseAdmin);
    if (exists) {
      uploadedFiles.push({type: 'image', url: body.image_url});
    }
  }

  if (body.audio_url) {
    const exists = await verifyQuarantineFile(body.audio_url, supabaseAdmin);
    if (exists) {
      uploadedFiles.push({type: 'audio', url: body.audio_url});
    }
  }

  // Crear gossip (código existente)
  const upsertResult = await supabaseAdmin.rpc('upsert_gossip_idempotent', ...);
  
  // Success
  return new Response(...);
  
} catch (error) {
  // COMPENSACIÓN AUTOMÁTICA
  if (uploadedFiles.length > 0) {
    console.log('🧹 Compensating: cleaning up uploaded files');
    await cleanupQuarantineFiles(uploadedFiles, supabaseAdmin);
  }
  
  // Re-throw
  throw error;
}
```

---

## 📊 IMPACTO

### Sin Compensación
- ❌ Archivos huérfanos en quarantine
- ❌ Storage crece innecesariamente
- ❌ Cleanup manual necesario
- ❌ Usuario confundido (archivo subido pero gossip no existe)

### Con Compensación
- ✅ Cleanup inmediato
- ✅ Storage limpio
- ✅ Usuario puede reintentar sin duplicados
- ✅ Mejor UX (consistencia)

### Reducción de Storage
```
Sin compensación:
- ~100 errores/día × 150KB/archivo = 15MB/día huérfanos
- En 1 mes = 450MB basura

Con compensación:
- ~0MB huérfanos (cleanup inmediato)
- Solo archivos de errores de cleanup (~5%)
```

---

## ✅ ESTADO ACTUAL

**Implementado:**
- ✅ Cleanup automático cada hora (24h TTL)
- ✅ Funciones SQL para cleanup

**Pendiente:**
- 🟡 Compensación inmediata en moderate-gossip
- 🟡 Reducir TTL a 2h (backup)
- 🟡 Monitoring de quarantine

**Prioridad:** 🟡 Media (puede hacerse post-beta)

**Tiempo estimado:** 2-3 horas

---

## 🎯 DECISIÓN

**Recomendación:** Implementar Opción A (Compensación Inmediata) + Opción B (Reducir TTL a 2h)

**Razón:** 
- Mejor UX (cleanup inmediato)
- Backup con TTL reducido
- No es bloqueador crítico para beta (cleanup de 24h funciona, solo no es óptimo)

**Para Beta:** 
- Reducir TTL a 2h (quick win, SQL simple)
- Compensación inmediata puede ser post-beta

---

**Última actualización:** 2026-10-22  
**Bloqueador:** #6  
**Estado:** 70% → 80% (con esta estrategia documentada)
