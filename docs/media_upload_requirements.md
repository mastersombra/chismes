# Requerimientos: Adjuntar Media (Imagen/Audio)

## Estado Actual
- La sección de media está deshabilitada con un placeholder: "Adjuntar imagen o audio próximamente"
- No existe implementación para selección, upload, progreso, cancelación o reintentos

## Requerimientos de Implementación

### 1. Progreso Real de Upload
Al adjuntar media, el usuario debe ver progreso real del upload, no solo un indicador de carga genérico.

**Estado requerido en AddGossipState:**
```dart
class MediaUploadState {
  final String? imageUrl;
  final String? audioUrl;
  final double imageUploadProgress; // 0.0 a 1.0
  final double audioUploadProgress; // 0.0 a 1.0
  final bool isUploadingImage;
  final bool isUploadingAudio;
  final String? uploadError;
}
```

**UI requerida:**
- Barra de progreso lineal o circular con porcentaje
- Estado de carga: "Subiendo imagen... 45%"
- Estado de completado: checkmark verde
- Estado de error: mensaje específico con botón de reintentar

### 2. Cancelación de Upload
El usuario debe poder cancelar un upload en progreso.

**Implementación requerida:**
```dart
// Use case con CancellationToken
class UploadMedia {
  Future<Result<Failure, String>> call(
    File file,
    MediaType type,
    CancellationToken cancellationToken,
  );
}

// Controller expone método de cancelación
class AddGossipController {
  void cancelImageUpload();
  void cancelAudioUpload();
}
```

**UI requerida:**
- Botón "Cancelar" visible durante upload
- Confirmación: "¿Cancelar subida?"
- Al cancelar, limpiar estado y permitir reintentar

### 3. Reintentar Upload
Si el upload falla (red, servidor, etc.), el usuario debe poder reintentar sin perder el archivo seleccionado.

**Estado requerido:**
```dart
class MediaUploadState {
  final File? pendingImageFile; // Archivo seleccionado pero no subido
  final File? pendingAudioFile;
  final String? uploadError;
}
```

**UI requerida:**
- Mensaje de error específico: "Error de conexión al subir imagen"
- Botón "Reintentar" visible
- Botón "Eliminar" para descartar el archivo

### 4. Eliminar Media
El usuario debe poder eliminar media seleccionada (antes o después del upload).

**Implementación requerida:**
```dart
class AddGossipController {
  void removeImage();
  void removeAudio();
}
```

**UI requerida:**
- Botón "X" o icono de basura en preview
- Confirmación: "¿Eliminar imagen?"
- Si ya subida, opcionalmente eliminar del servidor (Cloud Functions)

## Arquitectura Recomendada

### Use Cases
```dart
// Selección de media
class PickImage {
  Future<Result<Failure, File>> call();
}

class PickAudio {
  Future<Result<Failure, File>> call();
}

// Upload con progreso
class UploadMedia {
  final MediaRepository repository;

  Future<Result<Failure, String>> call(
    File file,
    MediaType type, // image/audio
    Function(double progress)? onProgress,
    CancellationToken? cancellationToken,
  ) async {
    return repository.upload(
      file,
      type,
      onProgress: onProgress,
      cancellationToken: cancellationToken,
    );
  }
}

// Eliminar del servidor
class DeleteMedia {
  Future<Result<Failure, void>> call(String url);
}
```

### Repository
```dart
abstract class MediaRepository {
  Future<Result<Failure, String>> upload(
    File file,
    MediaType type, {
    Function(double progress)? onProgress,
    CancellationToken? cancellationToken,
  });

  Future<Result<Failure, void>> delete(String url);
}
```

### Controller State
```dart
class AddGossipState {
  // Estado de upload de imagen
  final File? selectedImageFile;
  final String? uploadedImageUrl;
  final double imageUploadProgress;
  final bool isUploadingImage;
  final String? imageUploadError;

  // Estado de upload de audio
  final File? selectedAudioFile;
  final String? uploadedAudioUrl;
  final double audioUploadProgress;
  final bool isUploadingAudio;
  final String? audioUploadError;
}
```

### UI Flow
```
1. Usuario toca "Adjuntar imagen"
2. ImagePicker abre → usuario selecciona archivo
3. Preview aparece con botón "Eliminar"
4. Upload comienza automáticamente o al tocar "Subir"
5. Barra de progreso muestra 0% → 100%
6. Si éxito: checkmark verde, URL guardada
7. Si error: mensaje + botón "Reintentar"
8. Usuario puede cancelar durante upload
9. Usuario puede eliminar en cualquier momento
```

## Supabase Implementation

### Storage
```dart
// Supabase Storage
final bytes = await imageFile.readAsBytes();
final filePath = 'gossips/$gossipId/image.jpg';

await supabase.storage
  .from('gossip-media')
  .uploadBinary(
    filePath,
    bytes,
    fileOptions: const FileOptions(
      contentType: 'image/jpeg',
      upsert: false,
    ),
  );

// Obtener URL pública
final url = supabase.storage
  .from('gossip-media')
  .getPublicUrl(filePath);
```

### Storage Policies (RLS)
```sql
-- Solo usuarios autenticados pueden subir
CREATE POLICY "Users can upload media"
  ON storage.objects FOR INSERT
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND bucket_id = 'gossip-media'
    AND (storage.foldername(name))[1] = 'gossips'
    AND octet_length(content) < 10485760 -- 10MB max
  );

-- Todos pueden leer media público
CREATE POLICY "Public media is readable"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'gossip-media');
```

## Prioridades

1. **Alta**: Progreso real de upload (UX crítico)
2. **Alta**: Cancelación de upload (evita esperas innecesarias)
3. **Media**: Reintentar upload (mejora tolerancia a fallos)
4. **Media**: Eliminar media (flexibilidad del usuario)
5. **Baja**: Eliminar del servidor (opcional, puede hacerse en cleanup)

## Tests Requeridos

- Upload exitoso con progreso
- Upload fallido con reintentar
- Cancelación durante upload
- Eliminar media seleccionada
- Eliminar media subida (opcional)
- Límite de tamaño de archivo
- Tipos de archivo válidos
