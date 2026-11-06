# 📸 GUÍA DE IMÁGENES Y AUDIO - CHISMES APP

**Última actualización:** 17 de octubre de 2026  
**Backend:** Supabase Storage  
**Estrategia:** Compresión agresiva + CDN incluido

---

## 📐 DECISIÓN ARQUITECTÓNICA: String Simple vs MediaReference

### ✅ DECISIÓN FINAL: OPCIÓN B - String Simple

**Por qué NO usamos MediaReference:**
```dart
// ❌ MediaReference existe pero NO se usa
class MediaReference {
  final String storagePath;
  final String downloadUrl;
  final String mimeType;
  final int size;
  final bool isProcessed;
  final bool isModerated;
  final bool isAvailable;
}
```

**Razones:**
- ❌ Complejidad innecesaria para app de 4 pantallas
- ❌ Metadata (size, mimeType) no se usa en UI
- ❌ Flags de estado (isProcessed, isModerated) son overkill
- ❌ Serialización JSON compleja (nested objects)
- ❌ 4-6 horas de trabajo vs 30 minutos
- ❌ Dificulta testing y debugging

**Lo que SÍ usamos:**
```dart
// ✅ String simple - Perfecto para nuestro caso
class Gossip {
  final String? imageUrl;      // Imagen completa (800x800)
  final String? thumbnailUrl;  // Thumbnail (200x200) - Futuro
  final String? audioUrl;      // Audio (futuro)
}
```

**Ventajas:**
- ✅ Simple de entender
- ✅ Serialización automática (flat JSON)
- ✅ Suficiente para 4-5M usuarios
- ✅ Fácil de cambiar en futuro si es necesario
- ✅ Testing simple
- ✅ 30 minutos de implementación

**Comparación:**

| Aspecto | MediaReference | String Simple ✅ |
|---------|----------------|------------------|
| Complejidad | Alta | Baja |
| Metadata | Sí (size, mimeType) | No (innecesario) |
| Flags de estado | 3 flags | Ninguno |
| Serialización | Nested JSON | Flat JSON |
| Tiempo implementación | 4-6 horas | 30 minutos |
| Suficiente para MVP | Sí (excesivo) | Sí (justo) |

---

## 🎯 ESTRATEGIA GENERAL

### Fase Actual (MVP)
- ✅ **Solo imágenes** (NO audio)
- ✅ **1 imagen por chisme** (máximo)
- ✅ **Compresión automática** en Flutter
- ✅ **Thumbnails** para lista de chismes (futuro)
- ✅ **CDN de Supabase** incluido (gratis)
- ✅ **String simple** (NO MediaReference)

### Futuro (v2.0)
- Audio opcional (cuando haya ingresos)
- Múltiples imágenes por chisme
- Video corto (15 seg máx)
- thumbnailUrl implementado

---

## 💰 COSTOS PROYECTADOS

### Plan Gratuito (0-6 meses)
- **Storage:** 1 GB gratis
- **Transferencia:** 2 GB/mes gratis
- **Usuarios soportados:** ~4,000 activos/mes
- **Costo:** $0/mes

### Plan Pro (6-18 meses)
- **Storage:** 100 GB ($25/mes incluidos)
- **Transferencia:** 200 GB/mes ($25/mes incluidos)
- **Usuarios soportados:** ~50,000 activos/mes
- **Costo:** $25-75/mes

### Escala (18+ meses)
- **Storage adicional:** $0.021/GB
- **Transferencia adicional:** $0.09/GB
- **Usuarios soportados:** 100,000+ activos/mes
- **Costo:** $150-300/mes (pero ya hay ingresos)

---

## 📦 ESPECIFICACIONES TÉCNICAS

### Imágenes de Chismes

| Aspecto | Especificación | Razón |
|---------|----------------|-------|
| **Resolución máxima** | 800×800 px | Perfecto para móviles, rápido de cargar |
| **Formato** | JPEG | Comprime 2-3x más que PNG |
| **Calidad** | 75% | Balance perfecto calidad/tamaño |
| **Tamaño objetivo** | 100-150 KB | Carga rápida en 3G/4G |
| **Tamaño máximo** | 300 KB | Límite de seguridad |
| **Relación aspecto** | Libre (crop automático) | Usuario elige composición |

### Thumbnails (para listas)

| Aspecto | Especificación |
|---------|----------------|
| **Resolución** | 200×200 px |
| **Calidad** | 70% |
| **Tamaño** | ~30 KB |
| **Uso** | Feed de chismes |

---

## 🔧 COMPRESIÓN AUTOMÁTICA

### ⚠️ IMPORTANTE: El usuario NO necesita bajar la calidad

**Cómo funciona:**
1. Usuario toma foto con cámara (puede ser 4K, 12MP, lo que sea)
2. **Flutter automáticamente comprime** ANTES de subir
3. Usuario nunca ve ni nota la compresión
4. Se sube versión comprimida (100-150 KB)

**Ejemplo:**
```
Foto original: 3024×4032 px, 3.5 MB (calidad máxima del celular)
       ↓ Flutter comprime automáticamente
Foto comprimida: 800×1067 px, 120 KB
       ↓ Se sube a Supabase
Usuario ve: 800×1067 px, 120 KB (se ve perfecta en móvil)
```

**El usuario NO HACE NADA.** La compresión es invisible.

---

## 🌐 CDN DE SUPABASE (Ya incluido - GRATIS)

### ¿Qué es un CDN?

**CDN = Content Delivery Network** (Red de Entrega de Contenido)

En lugar de que TODAS las imágenes se descarguen desde un único servidor en USA, Supabase automáticamente:
1. **Copia tus imágenes** a múltiples servidores alrededor del mundo
2. **Sirve desde el servidor más cercano** al usuario
3. **Cachea (guarda)** imágenes en memoria para entregas ultra-rápidas

**Ejemplo:**
```
Usuario en Medellín solicita imagen:
  ❌ SIN CDN: Descarga desde servidor USA (200ms)
  ✅ CON CDN: Descarga desde servidor Bogotá (20ms) - 10x más rápido

Segunda vez que ve la imagen:
  ✅ CDN ya la tiene en caché: 5ms - instantáneo
```

### Ventajas del CDN de Supabase

| Ventaja | Descripción |
|---------|-------------|
| **Ya incluido** | No pagas extra, viene con Supabase |
| **Global** | Servidores en 35+ países |
| **Caché automático** | Imágenes se guardan automáticamente |
| **HTTPS gratis** | Conexiones seguras incluidas |
| **Sin configuración** | Funciona desde día 1 |

### URLs con CDN

Cuando subes una imagen a Supabase:
```dart
// URL normal (sin CDN)
https://njqamqcsldpmtbiqwbwo.supabase.co/storage/v1/object/public/images/gossips/12345.jpg

// URL con CDN (automático)
https://njqamqcsldpmtbiqwbwo.supabase.co/storage/v1/object/public/images/gossips/12345.jpg
```

**Supabase automáticamente usa su CDN.** No necesitas hacer nada especial.

---

## 🚀 ALTERNATIVA AVANZADA: Cloudflare R2 (Futuro)

### ¿Qué es Cloudflare R2?

Es un servicio de storage **con transferencia gratis** (no pagas por descargas).

### Comparación Supabase vs Cloudflare R2

| Aspecto | Supabase Storage | Cloudflare R2 |
|---------|-----------------|---------------|
| **Storage** | $0.021/GB/mes | $0.015/GB/mes |
| **Transferencia** | $0.09/GB | **$0 (GRATIS)** |
| **CDN** | Incluido | Incluido |
| **Integración** | Nativa con Supabase | Requiere setup aparte |
| **Complejidad** | Muy fácil | Media |
| **Costo total (50K usuarios)** | $25-75/mes | $15-30/mes |

### ¿Cuándo cambiar a Cloudflare R2?

**Solo si:**
- ✅ Tienes más de 100,000 usuarios activos
- ✅ Transferencia > 500 GB/mes
- ✅ Puedes configurar infraestructura aparte

**Para tu caso actual:** **Quédate con Supabase Storage.** Es más simple y el costo es razonable.

---

## 🛠️ IMPLEMENTACIÓN TÉCNICA

### 1. Dependencias

```yaml
# pubspec.yaml
dependencies:
  supabase_flutter: ^2.5.6
  image_picker: ^1.0.7
  flutter_image_compress: ^2.1.0
  cached_network_image: ^3.3.1  # Para caché local
```

### 2. Servicio de Compresión

```dart
// lib/core/media/image_compressor.dart
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';

class ImageCompressor {
  /// Comprime imagen para chisme
  /// Usuario toma foto normal → Flutter comprime → sube comprimida
  static Future<File?> compressGossipImage(File file) async {
    final filePath = file.absolute.path;
    final outPath = '${filePath.substring(0, filePath.lastIndexOf('.'))}_compressed.jpg';
    
    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outPath,
      quality: 75,              // 75% calidad (perfecto para móvil)
      minWidth: 800,            // Máximo 800px ancho
      minHeight: 800,           // Máximo 800px alto
      format: CompressFormat.jpeg,
    );
    
    return result != null ? File(result.path) : null;
  }
  
  /// Genera thumbnail para lista
  static Future<File?> generateThumbnail(File file) async {
    final filePath = file.absolute.path;
    final outPath = '${filePath.substring(0, filePath.lastIndexOf('.'))}_thumb.jpg';
    
    final result = await FlutterImageCompress.compressAndGetFile(
      filePath,
      outPath,
      quality: 70,
      minWidth: 200,
      minHeight: 200,
      format: CompressFormat.jpeg,
    );
    
    return result != null ? File(result.path) : null;
  }
  
  /// Verifica tamaño final
  static Future<double> getFileSizeInKB(File file) async {
    final int bytes = await file.length();
    return bytes / 1024;
  }
}
```

### 3. Servicio de Upload

```dart
// lib/core/media/supabase_storage_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'image_compressor.dart';

class SupabaseStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Sube imagen comprimida + thumbnail
  Future<UploadResult> uploadGossipImage(File originalFile) async {
    try {
      // 1. Comprimir imagen
      final File? compressedFile = await ImageCompressor.compressGossipImage(originalFile);
      if (compressedFile == null) {
        throw Exception('Error al comprimir imagen');
      }
      
      // 2. Verificar tamaño
      final double sizeKB = await ImageCompressor.getFileSizeInKB(compressedFile);
      if (sizeKB > 300) {
        throw Exception('Imagen muy grande: ${sizeKB.toStringAsFixed(1)} KB. Máximo 300 KB');
      }
      
      print('📸 Tamaño original: ${await ImageCompressor.getFileSizeInKB(originalFile)} KB');
      print('📸 Tamaño comprimido: ${sizeKB.toStringAsFixed(1)} KB');
      
      // 3. Generar thumbnail
      final File? thumbnailFile = await ImageCompressor.generateThumbnail(originalFile);
      
      // 4. Generar nombres únicos
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String userId = _supabase.auth.currentUser?.id ?? 'anonymous';
      final String fileName = '${userId}_$timestamp.jpg';
      
      // 5. Subir imagen completa
      final String fullPath = 'gossips/full/$fileName';
      await _supabase.storage
          .from('images')
          .upload(fullPath, compressedFile);
      
      // 6. Subir thumbnail (si existe)
      String? thumbPath;
      if (thumbnailFile != null) {
        thumbPath = 'gossips/thumb/$fileName';
        await _supabase.storage
            .from('images')
            .upload(thumbPath, thumbnailFile);
      }
      
      // 7. Obtener URLs públicas (con CDN automático)
      final String fullUrl = _supabase.storage
          .from('images')
          .getPublicUrl(fullPath);
      
      final String? thumbUrl = thumbPath != null
          ? _supabase.storage.from('images').getPublicUrl(thumbPath)
          : null;
      
      return UploadResult(
        fullUrl: fullUrl,
        thumbnailUrl: thumbUrl ?? fullUrl,
        sizeKB: sizeKB,
      );
      
    } catch (e) {
      print('❌ Error uploading image: $e');
      rethrow;
    }
  }
  
  /// Elimina imagen (cuando se borra el chisme)
  Future<void> deleteGossipImage(String imageUrl) async {
    try {
      // Extraer path de la URL
      final Uri uri = Uri.parse(imageUrl);
      final String path = uri.pathSegments.last;
      
      // Borrar imagen completa
      await _supabase.storage
          .from('images')
          .remove(['gossips/full/$path']);
      
      // Borrar thumbnail
      await _supabase.storage
          .from('images')
          .remove(['gossips/thumb/$path']);
      
    } catch (e) {
      print('❌ Error deleting image: $e');
    }
  }
}

class UploadResult {
  final String fullUrl;
  final String thumbnailUrl;
  final double sizeKB;
  
  UploadResult({
    required this.fullUrl,
    required this.thumbnailUrl,
    required this.sizeKB,
  });
}
```

### 4. Uso en Controller

```dart
// lib/features/gossip/presentation/controllers/add_gossip_controller.dart
import 'package:image_picker/image_picker.dart';

class AddGossipController extends ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  
  /// Usuario toma foto con cámara
  Future<void> pickImageFromCamera() async {
    await _pickImage(ImageSource.camera);
  }
  
  /// Usuario selecciona de galería
  Future<void> pickImageFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      _updateState(_state.copyWith(isUploadingImage: true));
      
      // 1. Usuario selecciona/toma imagen
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,  // Limitar antes de comprimir
        maxHeight: 1920,
        imageQuality: 85, // Primera compresión ligera
      );
      
      if (image == null) {
        _updateState(_state.copyWith(isUploadingImage: false));
        return;
      }
      
      // 2. Comprimir y subir (automático)
      final File imageFile = File(image.path);
      final UploadResult result = await _storageService.uploadGossipImage(imageFile);
      
      print('✅ Imagen subida: ${result.sizeKB.toStringAsFixed(1)} KB');
      
      // 3. Actualizar estado con URLs
      _updateState(_state.copyWith(
        imageUrl: result.fullUrl,
        thumbnailUrl: result.thumbnailUrl,
        isUploadingImage: false,
      ));
      
    } catch (e) {
      print('❌ Error: $e');
      _updateState(_state.copyWith(
        isUploadingImage: false,
        failure: ValidationFailure(
          code: ErrorCode.invalidInput,
          message: 'Error al subir imagen. Intenta de nuevo.',
        ),
      ));
    }
  }
  
  /// Remover imagen
  void removeImage() {
    if (_state.imageUrl != null) {
      // Opcional: borrar de Supabase
      _storageService.deleteGossipImage(_state.imageUrl!);
    }
    
    _updateState(_state.copyWith(
      imageUrl: null,
      thumbnailUrl: null,
    ));
  }
}
```

### 5. UI para Seleccionar Imagen

```dart
// lib/features/gossip/presentation/widgets/image_picker_widget.dart
class ImagePickerWidget extends StatelessWidget {
  final String? imageUrl;
  final bool isUploading;
  final VoidCallback onPickFromCamera;
  final VoidCallback onPickFromGallery;
  final VoidCallback? onRemove;
  
  const ImagePickerWidget({
    super.key,
    this.imageUrl,
    required this.isUploading,
    required this.onPickFromCamera,
    required this.onPickFromGallery,
    this.onRemove,
  });
  
  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      // Mostrar imagen seleccionada
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          
          // Botón para remover
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: onRemove,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
              ),
            ),
          ),
        ],
      );
    }
    
    if (isUploading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    // Botones para seleccionar
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Agrega una foto (opcional)',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón cámara
              OutlinedButton.icon(
                onPressed: onPickFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Cámara'),
              ),
              
              const SizedBox(width: 16),
              
              // Botón galería
              OutlinedButton.icon(
                onPressed: onPickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galería'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 6. Mostrar Imágenes con Caché

```dart
// En la lista de chismes - usa thumbnail
CachedNetworkImage(
  imageUrl: gossip.thumbnailUrl,  // ← Thumbnail (30 KB)
  placeholder: (context, url) => Container(
    color: Colors.grey[200],
    child: const Icon(Icons.image),
  ),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  width: 80,
  height: 80,
  fit: BoxFit.cover,
  // ✅ Caché local - no descarga de nuevo
  maxWidthDiskCache: 200,
  maxHeightDiskCache: 200,
)

// En detalle del chisme - usa imagen completa
CachedNetworkImage(
  imageUrl: gossip.imageUrl,  // ← Imagen completa (150 KB)
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  width: double.infinity,
  fit: BoxFit.cover,
  // ✅ Caché local
  maxWidthDiskCache: 800,
  maxHeightDiskCache: 800,
)
```

---

## 🔐 CONFIGURACIÓN SUPABASE

### 1. Crear Bucket

En Supabase Dashboard → Storage → New bucket:
```
Nombre: images
Público: Sí (para que cualquiera pueda ver)
```

### 2. Políticas de Seguridad

```sql
-- Política: Usuarios autenticados pueden subir
CREATE POLICY "Usuarios autenticados pueden subir imágenes"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'images'
  AND (storage.foldername(name))[1] = 'gossips'
);

-- Política: Cualquiera puede ver imágenes públicas
CREATE POLICY "Imágenes públicas son visibles"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'images');

-- Política: Solo el dueño puede borrar
CREATE POLICY "Solo el dueño puede borrar"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'images'
  AND owner = auth.uid()
);
```

### 3. Límite de Tamaño

En Supabase Dashboard → Storage → Settings:
```
Max file size: 500 KB
```

### 4. Limpiar Imágenes Huérfanas (Opcional)

```sql
-- Function para borrar imágenes de chismes eliminados
CREATE OR REPLACE FUNCTION cleanup_orphaned_images()
RETURNS void AS $$
BEGIN
  DELETE FROM storage.objects
  WHERE bucket_id = 'images'
    AND created_at < NOW() - INTERVAL '30 days'
    AND name LIKE 'gossips/%'
    AND name NOT IN (
      SELECT image_url FROM gossips WHERE deleted_at IS NULL
      UNION
      SELECT thumbnail_url FROM gossips WHERE deleted_at IS NULL
    );
END;
$$ LANGUAGE plpgsql;

-- Ejecutar manualmente o con cron job
```

---

## 📊 MONITOREO DE COSTOS

### Dashboard de Supabase

En Supabase Dashboard → Settings → Billing puedes ver:
- Storage usado (GB)
- Transferencia usada (GB/mes)
- Proyección de costos
- Alertas cuando te acercas al límite

### Alertas Recomendadas

Configurar en Dashboard → Settings → Billing → Alerts:
```
Alerta 1: Storage > 800 MB (80% del free tier)
Alerta 2: Transferencia > 1.6 GB (80% del free tier)
Alerta 3: Upgrade automático a Pro si excedes límites
```

---

## 🎬 AUDIO (Futuro - v2.0)

### Cuándo Implementar Audio

**SOLO cuando:**
- ✅ Tienes más de 10,000 usuarios activos
- ✅ Tienes ingresos (ads, suscripciones)
- ✅ Usuarios explícitamente lo piden
- ✅ Tienes presupuesto ($50-100/mes extra)

### Especificaciones Audio

| Aspecto | Especificación |
|---------|----------------|
| **Duración máxima** | 30 segundos |
| **Formato** | MP3 (más comprimido) |
| **Bitrate** | 64 kbps (suficiente para voz) |
| **Tamaño objetivo** | ~240 KB (30 seg @ 64kbps) |
| **Codec** | AAC o Opus |

### Costo Estimado Audio

```
500,000 chismes/mes × 5% con audio = 25,000 audios
25,000 audios × 240 KB = 6 GB storage
25,000 audios × 240 KB × 5 plays = 30 GB transfer

Costo adicional: ~$20-30/mes
```

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

### Fase 1: Setup Básico
- [ ] Crear bucket `images` en Supabase
- [ ] Configurar políticas de seguridad
- [ ] Agregar dependencias en pubspec.yaml
- [ ] Crear ImageCompressor service
- [ ] Crear SupabaseStorageService

### Fase 2: UI
- [ ] Agregar botones cámara/galería en AddGossipScreen
- [ ] Mostrar preview de imagen seleccionada
- [ ] Agregar botón para remover imagen
- [ ] Mostrar loading mientras sube

### Fase 3: Optimización
- [ ] Implementar thumbnails
- [ ] Usar CachedNetworkImage en lista
- [ ] Agregar manejo de errores
- [ ] Testing con imágenes grandes/pequeñas

### Fase 4: Monitoreo
- [ ] Configurar alertas de billing en Supabase
- [ ] Monitorear storage usado
- [ ] Monitorear transferencia mensual
- [ ] Revisar costos cada mes

---

## 📚 RECURSOS

### Documentación
- [Supabase Storage Docs](https://supabase.com/docs/guides/storage)
- [flutter_image_compress](https://pub.dev/packages/flutter_image_compress)
- [cached_network_image](https://pub.dev/packages/cached_network_image)
- [image_picker](https://pub.dev/packages/image_picker)

### Calculadoras de Costo
- [Supabase Pricing](https://supabase.com/pricing)
- [Cloudflare R2 Pricing](https://www.cloudflare.com/products/r2/)

---

## 🎯 RESUMEN EJECUTIVO

### Lo Más Importante

1. **Usuario NO hace nada especial** - toma foto normal, Flutter comprime automáticamente
2. **CDN ya incluido** - Supabase lo hace automáticamente, no pagas extra
3. **Primeros 6-12 meses GRATIS** - hasta ~4,000 usuarios activos
4. **Compresión 800×800 @ 75%** - se ve perfecta en móvil, solo 100-150 KB
5. **NO implementes audio ahora** - espera a tener ingresos

### Próximos Pasos

1. Implementar ImageCompressor service
2. Crear bucket en Supabase
3. Agregar botones de cámara/galería en UI
4. Testing con diferentes tipos de imágenes
5. Monitorear costos mensualmente

---

**Fecha de creación:** 17 de octubre de 2026  
**Autor:** Basado en análisis técnico y proyecciones de costos reales  
**Versión:** 1.0
