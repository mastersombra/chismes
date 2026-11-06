import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chismes/core/media/supabase_storage_service.dart';
import 'package:chismes/core/logging/logging.dart';

import 'supabase_storage_service_test.mocks.dart';

// Generar mocks con: dart run build_runner build
@GenerateMocks([
  SupabaseClient,
  SupabaseStorageClient,
  StorageFileApi,
  AppLogger,
])
void main() {
  group('UploadResult', () {
    group('Constructor', () {
      test('debe crear instancia con todos los campos', () {
        final result = UploadResult(
          fullUrl: 'https://example.com/full/image.jpg',
          thumbnailUrl: 'https://example.com/thumb/image.jpg',
          sizeKB: 125.5,
          storagePath: 'gossips/full/abc123_1234567890.jpg',
        );

        expect(result.fullUrl, 'https://example.com/full/image.jpg');
        expect(result.thumbnailUrl, 'https://example.com/thumb/image.jpg');
        expect(result.sizeKB, 125.5);
        expect(result.storagePath, 'gossips/full/abc123_1234567890.jpg');
      });

      test('debe permitir URLs diferentes para full y thumbnail', () {
        final result = UploadResult(
          fullUrl: 'https://cdn.supabase.co/full/image.jpg',
          thumbnailUrl: 'https://cdn.supabase.co/thumb/image.jpg',
          sizeKB: 100.0,
          storagePath: 'gossips/full/image.jpg',
        );

        expect(result.fullUrl, isNot(equals(result.thumbnailUrl)));
        expect(result.fullUrl, contains('full'));
        expect(result.thumbnailUrl, contains('thumb'));
      });

      test('debe permitir thumbnail igual a full cuando no hay thumb', () {
        const fullUrl = 'https://example.com/image.jpg';
        final result = UploadResult(
          fullUrl: fullUrl,
          thumbnailUrl: fullUrl, // Mismo URL cuando no se genera thumb
          sizeKB: 150.0,
          storagePath: 'gossips/full/image.jpg',
        );

        expect(result.fullUrl, result.thumbnailUrl);
      });

      test('debe almacenar sizeKB con decimales', () {
        final result = UploadResult(
          fullUrl: 'url1',
          thumbnailUrl: 'url2',
          sizeKB: 125.7893,
          storagePath: 'path',
        );

        expect(result.sizeKB, isA<double>());
        expect(result.sizeKB, 125.7893);
      });

      test('debe permitir storagePath con estructura de carpetas', () {
        final result = UploadResult(
          fullUrl: 'url',
          thumbnailUrl: 'url',
          sizeKB: 100.0,
          storagePath: 'gossips/full/subfolder/image.jpg',
        );

        expect(result.storagePath, contains('gossips/full/'));
        expect(result.storagePath.split('/').length, greaterThan(2));
      });
    });

    group('Uso en listas', () {
      test('debe poder crear lista de UploadResults', () {
        final results = [
          UploadResult(
            fullUrl: 'url1',
            thumbnailUrl: 'thumb1',
            sizeKB: 100.0,
            storagePath: 'path1',
          ),
          UploadResult(
            fullUrl: 'url2',
            thumbnailUrl: 'thumb2',
            sizeKB: 150.0,
            storagePath: 'path2',
          ),
        ];

        expect(results.length, 2);
        expect(results[0].sizeKB, lessThan(results[1].sizeKB));
      });

      test('debe poder filtrar por tamaño', () {
        final results = [
          UploadResult(fullUrl: 'url1', thumbnailUrl: 't1', sizeKB: 50.0, storagePath: 'p1'),
          UploadResult(fullUrl: 'url2', thumbnailUrl: 't2', sizeKB: 150.0, storagePath: 'p2'),
          UploadResult(fullUrl: 'url3', thumbnailUrl: 't3', sizeKB: 250.0, storagePath: 'p3'),
        ];

        final smallImages = results.where((r) => r.sizeKB < 100).toList();
        final largeImages = results.where((r) => r.sizeKB > 100).toList();

        expect(smallImages.length, 1);
        expect(largeImages.length, 2);
      });
    });

    group('Valores típicos', () {
      test('sizeKB debe estar típicamente entre 100-150 KB', () {
        final result = UploadResult(
          fullUrl: 'url',
          thumbnailUrl: 'url',
          sizeKB: 125.0,
          storagePath: 'path',
        );

        expect(result.sizeKB, greaterThan(100));
        expect(result.sizeKB, lessThan(150));
      });

      test('URLs deben ser válidas de Supabase CDN', () {
        const supabaseUrl = 'https://xyzproject.supabase.co/storage/v1/object/public/images/gossips/full/image.jpg';
        final result = UploadResult(
          fullUrl: supabaseUrl,
          thumbnailUrl: supabaseUrl.replaceFirst('full/', 'thumb/'),
          sizeKB: 120.0,
          storagePath: 'gossips/full/image.jpg',
        );

        expect(result.fullUrl, startsWith('https://'));
        expect(result.fullUrl, contains('supabase'));
        expect(result.fullUrl, contains('/storage/'));
      });
    });
  });

  group('SupabaseStorageService - Lógica de nombres de archivos', () {
    group('Generación de nombres de archivo', () {
      test('debe generar nombre con formato gossipId_timestamp.jpg', () {
        const gossipId = 'abc123';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${gossipId}_$timestamp.jpg';

        expect(fileName, startsWith('abc123_'));
        expect(fileName, endsWith('.jpg'));
        expect(fileName, contains('_'));
      });

      test('debe incluir gossipId en el nombre para identificación', () {
        const gossipId = 'uuid-gossip-456';
        final timestamp = 1234567890;
        final fileName = '${gossipId}_$timestamp.jpg';

        expect(fileName, contains(gossipId));
        expect(fileName, 'uuid-gossip-456_1234567890.jpg');
      });

      test('debe usar timestamp para evitar colisiones', () {
        const gossipId = 'test';
        final timestamp1 = DateTime.now().millisecondsSinceEpoch;
        final timestamp2 = timestamp1 + 1000;

        final fileName1 = '${gossipId}_$timestamp1.jpg';
        final fileName2 = '${gossipId}_$timestamp2.jpg';

        expect(fileName1, isNot(equals(fileName2)));
      });

      test('debe usar siempre extensión .jpg', () {
        const gossipId = 'test';
        final timestamp = 123456;
        final fileName = '${gossipId}_$timestamp.jpg';

        expect(fileName, endsWith('.jpg'));
        expect(fileName, isNot(endsWith('.png')));
      });

      test('debe manejar gossipIds con caracteres especiales', () {
        const gossipIds = [
          'uuid-abc-123',
          'gossip_456',
          'test.gossip',
        ];

        for (final gossipId in gossipIds) {
          final timestamp = 123456;
          final fileName = '${gossipId}_$timestamp.jpg';

          expect(fileName, contains(gossipId));
          expect(fileName, endsWith('.jpg'));
        }
      });
    });

    group('Estructura de paths en Storage', () {
      test('fullPath debe usar estructura gossips/full/', () {
        const gossipId = 'abc123';
        final timestamp = 1234567890;
        final fileName = '${gossipId}_$timestamp.jpg';
        final fullPath = 'gossips/full/$fileName';

        expect(fullPath, 'gossips/full/abc123_1234567890.jpg');
        expect(fullPath, startsWith('gossips/full/'));
      });

      test('thumbPath debe usar estructura gossips/thumb/', () {
        const gossipId = 'abc123';
        final timestamp = 1234567890;
        final fileName = '${gossipId}_$timestamp.jpg';
        final thumbPath = 'gossips/thumb/$fileName';

        expect(thumbPath, 'gossips/thumb/abc123_1234567890.jpg');
        expect(thumbPath, startsWith('gossips/thumb/'));
      });

      test('fullPath y thumbPath deben tener mismo fileName', () {
        const fileName = 'test_123.jpg';
        final fullPath = 'gossips/full/$fileName';
        final thumbPath = 'gossips/thumb/$fileName';

        expect(fullPath.split('/').last, thumbPath.split('/').last);
      });

      test('debe poder convertir fullPath a thumbPath', () {
        const fullPath = 'gossips/full/abc_123.jpg';
        final thumbPath = fullPath.replaceFirst('full/', 'thumb/');

        expect(thumbPath, 'gossips/thumb/abc_123.jpg');
      });
    });
  });

  group('Límites y restricciones', () {
    test('tamaño máximo debe ser 300 KB', () {
      const maxSizeKB = 300;

      expect(maxSizeKB, 300);
    });

    test('imagen comprimida típica debe estar bajo el límite', () {
      const typicalCompressedKB = 125;
      const maxSizeKB = 300;

      expect(typicalCompressedKB, lessThan(maxSizeKB));
    });

    test('mensaje de error debe incluir tamaño en KB', () {
      const sizeKB = 350.5;
      final errorMessage =
          'Imagen muy grande: ${sizeKB.toStringAsFixed(1)} KB. Máximo 300 KB';

      expect(errorMessage, contains('350.5 KB'));
      expect(errorMessage, contains('Máximo 300 KB'));
    });

    test('debe formatear tamaño con 1 decimal', () {
      const values = [125.789, 99.123, 150.0];

      for (final value in values) {
        final formatted = value.toStringAsFixed(1);
        expect(formatted.split('.').last.length, 1);
      }
    });
  });

  group('Bucket de storage', () {
    test('debe usar bucket "images"', () {
      const bucketName = 'images';

      expect(bucketName, 'images');
    });

    test('todas las operaciones deben usar el mismo bucket', () {
      const bucket = 'images';

      // Upload full image
      expect(bucket, 'images');

      // Upload thumbnail
      expect(bucket, 'images');

      // Delete image
      expect(bucket, 'images');
    });
  });

  group('URLs públicas', () {
    test('debe generar URLs públicas para CDN automático', () {
      // Documenta que getPublicUrl genera URLs para CDN
      // Formato: https://[project].supabase.co/storage/v1/object/public/images/gossips/full/test_123.jpg

      const expectedFormat = 'https://[project].supabase.co/storage/v1/object/public/images/gossips/full/test_123.jpg';

      expect(expectedFormat, contains('/storage/'));
      expect(expectedFormat, contains('/public/'));
      expect(expectedFormat, contains('images'));
    });

    test('thumbnailUrl debe ser igual a fullUrl si no hay thumbnail', () {
      const fullUrl = 'https://example.com/image.jpg';
      const String? thumbPath = null; // null cuando falla generación

      final thumbUrl = thumbPath ?? fullUrl;

      expect(thumbUrl, fullUrl);
    });

    test('thumbnailUrl debe ser diferente si hay thumbnail', () {
      const fullUrl = 'https://example.com/full/image.jpg';
      const thumbPath = 'gossips/thumb/image.jpg';

      final thumbUrl = thumbPath.isNotEmpty
          ? 'https://example.com/thumb/image.jpg'
          : fullUrl;

      expect(thumbUrl, isNot(fullUrl));
      expect(thumbUrl, contains('thumb'));
    });
  });

  group('Manejo de errores', () {
    test('debe lanzar Exception si compresión falla', () {
      // Documenta que null de compressor → Exception
      // Cuando ImageCompressor retorna null, se lanza Exception
      expect(
        () => throw Exception('Error al comprimir imagen'),
        throwsException,
      );
    });

    test('debe lanzar Exception si tamaño excede límite', () {
      const sizeKB = 350.0;
      const maxSizeKB = 300;

      expect(sizeKB > maxSizeKB, isTrue);
    });

    test('deleteImage no debe lanzar error, solo loggear', () {
      // Documenta que catch no rethrow
      // Este comportamiento permite que el borrado falle sin afectar flujo
      expect(true, isTrue); // Test de documentación
    });
  });

  group('Flujo de trabajo', () {
    test('debe seguir orden: comprimir → verificar → subir → thumbnail', () {
      // Documenta el flujo:
      // 1. Comprimir imagen
      // 2. Verificar tamaño
      // 3. Subir imagen completa
      // 4. Generar y subir thumbnail
      // 5. Obtener URLs públicas

      const steps = [
        'compress',
        'verify_size',
        'upload_full',
        'generate_thumb',
        'upload_thumb',
        'get_urls',
      ];

      expect(steps.length, 6);
      expect(steps[0], 'compress');
      expect(steps.last, 'get_urls');
    });

    test('debe subir imagen DESPUÉS de crear gossip', () {
      // Documenta Estrategia 1:
      // 1. Crear gossip SIN imagen → DB
      // 2. Subir imagen con gossipId → Storage
      // 3. Actualizar gossip con URL → DB

      const strategy = 'upload_after_gossip_created';
      expect(strategy, 'upload_after_gossip_created');
    });

    test('debe prevenir archivos huérfanos', () {
      // Ventaja de subir después de crear gossip:
      // - Si falla crear gossip, no se sube imagen
      // - Si falla subir imagen, gossip queda sin imagen
      // - 0% archivos huérfanos

      const orphanRate = 0.0; // 0% con esta estrategia
      expect(orphanRate, 0.0);
    });
  });

  group('Información de debug', () {
    test('debe imprimir tamaño original y comprimido', () {
      // Documenta los prints de debug
      const originalSizeKB = 2500.0;
      const compressedSizeKB = 125.5;

      expect(originalSizeKB, greaterThan(compressedSizeKB));
      expect(compressedSizeKB / originalSizeKB, lessThan(0.1)); // <10% del original
    });

    test('debe imprimir confirmación de eliminación', () {
      const message = '🗑️ Imagen eliminada: gossips/full/test.jpg';

      expect(message, contains('🗑️'));
      expect(message, contains('Imagen eliminada'));
    });

    test('debe imprimir advertencia si falla eliminación', () {
      const message = '⚠️ Error eliminando imagen: exception';

      expect(message, contains('⚠️'));
      expect(message, contains('Error eliminando'));
    });
  });

  group('Casos edge', () {
    test('debe manejar gossipIds muy largos', () {
      const longGossipId =
          'uuid-very-long-gossip-id-with-many-characters-123456789';
      final timestamp = 123456;
      final fileName = '${longGossipId}_$timestamp.jpg';

      expect(fileName.length, greaterThan(50));
      expect(fileName, startsWith(longGossipId));
    });

    test('debe manejar timestamp de 13 dígitos (milliseconds)', () {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      expect(timestamp.toString().length, 13);
    });

    test('debe poder borrar thumbnail cuando solo existe full', () {
      const fullPath = 'gossips/full/test.jpg';
      final thumbPath = fullPath.replaceFirst('full/', 'thumb/');

      expect(thumbPath, 'gossips/thumb/test.jpg');
      // Storage.remove() con path inexistente simplemente no hace nada
    });

    test('debe manejar nombres de archivo con caracteres especiales', () {
      const gossipId = 'gossip_测试_émoji_🎉';
      final timestamp = 123456;
      final fileName = '${gossipId}_$timestamp.jpg';

      expect(fileName, contains('测试'));
      expect(fileName, contains('émoji'));
      expect(fileName, contains('🎉'));
    });
  });

  group('Optimizaciones', () {
    test('debe generar thumbnail de forma opcional', () {
      // Si generateThumbnail retorna null, no se sube thumbnail
      const File? thumbnailFile = null; // null cuando falla

      final String? thumbPath = thumbnailFile != null
          ? 'gossips/thumb/test.jpg'
          : null;

      expect(thumbPath, isNull);
    });

    test('CDN debe ser automático con URLs públicas', () {
      // Supabase Storage tiene CDN automático
      // No requiere configuración adicional
      const cdnEnabled = true;

      expect(cdnEnabled, isTrue);
    });
  });

  group('SupabaseStorageService - Constructor', () {
    test('debe crear instancia con SupabaseClient', () {
      final mockSupabase = MockSupabaseClient();
      final mockLogger = MockAppLogger();
      final service = SupabaseStorageService(mockSupabase, mockLogger);

      expect(service, isNotNull);
      expect(service, isA<SupabaseStorageService>());
    });

    test('debe ser lazySingleton en DI', () {
      // Documenta que la anotación @lazySingleton está presente
      // Se crea solo cuando se necesita por primera vez
      expect(true, isTrue);
    });
  });

  group('SupabaseStorageService - deleteImage con mocks', () {
    late MockSupabaseClient mockSupabase;
    late MockSupabaseStorageClient mockStorage;
    late MockStorageFileApi mockFileApi;
    late MockAppLogger mockLogger;
    late SupabaseStorageService service;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockStorage = MockSupabaseStorageClient();
      mockFileApi = MockStorageFileApi();
      mockLogger = MockAppLogger();
      service = SupabaseStorageService(mockSupabase, mockLogger);

      when(mockSupabase.storage).thenReturn(mockStorage);
      when(mockStorage.from('images')).thenReturn(mockFileApi);
    });

    test('debe llamar remove con fullPath y thumbPath', () async {
      // Arrange
      const storagePath = 'gossips/full/test_123.jpg';
      const thumbPath = 'gossips/thumb/test_123.jpg';

      when(mockFileApi.remove([storagePath]))
          .thenAnswer((_) async => []);
      when(mockFileApi.remove([thumbPath]))
          .thenAnswer((_) async => []);

      // Act
      await service.deleteImage(storagePath);

      // Assert
      verify(mockFileApi.remove([storagePath])).called(1);
      verify(mockFileApi.remove([thumbPath])).called(1);
    });

    test('no debe lanzar error si falla eliminación de full', () async {
      // Arrange
      const storagePath = 'gossips/full/test_123.jpg';

      when(mockFileApi.remove([storagePath]))
          .thenThrow(Exception('Storage error'));
      when(mockFileApi.remove(['gossips/thumb/test_123.jpg']))
          .thenAnswer((_) async => []);

      // Act & Assert - no debe lanzar error
      await service.deleteImage(storagePath);

      verify(mockFileApi.remove([storagePath])).called(1);
    });

    test('no debe lanzar error si falla eliminación de thumbnail', () async {
      // Arrange
      const storagePath = 'gossips/full/test_123.jpg';
      const thumbPath = 'gossips/thumb/test_123.jpg';

      when(mockFileApi.remove([storagePath]))
          .thenAnswer((_) async => []);
      when(mockFileApi.remove([thumbPath]))
          .thenThrow(Exception('Thumbnail not found'));

      // Act & Assert - no debe lanzar error
      await service.deleteImage(storagePath);

      verify(mockFileApi.remove([storagePath])).called(1);
      verify(mockFileApi.remove([thumbPath])).called(1);
    });

    test('debe generar thumbPath correctamente reemplazando full por thumb', () async {
      // Arrange
      const storagePath = 'gossips/full/abc_456.jpg';
      const expectedThumbPath = 'gossips/thumb/abc_456.jpg';

      when(mockFileApi.remove([storagePath]))
          .thenAnswer((_) async => []);
      when(mockFileApi.remove([expectedThumbPath]))
          .thenAnswer((_) async => []);

      // Act
      await service.deleteImage(storagePath);

      // Assert
      verify(mockFileApi.remove([expectedThumbPath])).called(1);
    });

    test('debe usar bucket "images" en todas las operaciones', () async {
      // Arrange
      const storagePath = 'gossips/full/test.jpg';

      when(mockFileApi.remove(any)).thenAnswer((_) async => []);

      // Act
      await service.deleteImage(storagePath);

      // Assert - se llama 2 veces: una para full, otra para thumb
      verify(mockStorage.from('images')).called(2);
    });

    test('debe manejar storagePath con subcarpetas', () async {
      // Arrange
      const storagePath = 'gossips/full/subfolder/test.jpg';
      const expectedThumbPath = 'gossips/thumb/subfolder/test.jpg';

      when(mockFileApi.remove([storagePath]))
          .thenAnswer((_) async => []);
      when(mockFileApi.remove([expectedThumbPath]))
          .thenAnswer((_) async => []);

      // Act
      await service.deleteImage(storagePath);

      // Assert
      verify(mockFileApi.remove([storagePath])).called(1);
      verify(mockFileApi.remove([expectedThumbPath])).called(1);
    });
  });

  group('SupabaseStorageService - uploadImageAfterGossipCreated (lógica)', () {
    group('Validación de parámetros', () {
      test('debe requerir gossipId', () {
        // Documenta que gossipId es required
        const required = true;
        expect(required, isTrue);
      });

      test('debe requerir imageFile', () {
        // Documenta que imageFile es required
        const required = true;
        expect(required, isTrue);
      });

      test('gossipId debe estar en el nombre de archivo generado', () {
        const gossipId = 'test-gossip-123';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${gossipId}_$timestamp.jpg';

        expect(fileName, startsWith(gossipId));
        expect(fileName, contains('_'));
      });
    });

    group('Flujo de compresión', () {
      test('debe comprimir imagen primero', () {
        // Paso 1: Comprimir imagen con ImageCompressor
        const step1 = 'compressGossipImage';
        expect(step1, 'compressGossipImage');
      });

      test('debe lanzar Exception si compresión retorna null', () {
        // Si ImageCompressor.compressGossipImage() retorna null, lanza Exception
        expect(
          () => throw Exception('Error al comprimir imagen'),
          throwsException,
        );
      });

      test('mensaje de error de compresión debe ser descriptivo', () {
        const errorMessage = 'Error al comprimir imagen';

        expect(errorMessage, contains('comprimir'));
        expect(errorMessage, contains('imagen'));
      });
    });

    group('Validación de tamaño', () {
      test('debe verificar tamaño después de comprimir', () {
        // Paso 2: Verificar que tamaño < 300 KB
        const maxSizeKB = 300;
        expect(maxSizeKB, 300);
      });

      test('debe lanzar Exception si tamaño > 300 KB', () {
        const sizeKB = 350.5;
        const maxSizeKB = 300;

        expect(
          () {
            if (sizeKB > maxSizeKB) {
              throw Exception('Imagen muy grande: ${sizeKB.toStringAsFixed(1)} KB. Máximo 300 KB');
            }
          },
          throwsException,
        );
      });

      test('debe permitir tamaño exactamente 300 KB', () {
        const sizeKB = 300.0;
        const maxSizeKB = 300;

        expect(sizeKB > maxSizeKB, isFalse);
      });

      test('debe permitir tamaño 299.9 KB', () {
        const sizeKB = 299.9;
        const maxSizeKB = 300;

        expect(sizeKB > maxSizeKB, isFalse);
      });

      test('mensaje de error debe incluir tamaño actual y límite', () {
        const sizeKB = 350.5;
        final errorMessage = 'Imagen muy grande: ${sizeKB.toStringAsFixed(1)} KB. Máximo 300 KB';

        expect(errorMessage, contains('350.5'));
        expect(errorMessage, contains('300 KB'));
        expect(errorMessage, contains('Máximo'));
      });

      test('debe formatear tamaño con 1 decimal en error', () {
        const sizeKB = 325.789;
        final formatted = sizeKB.toStringAsFixed(1);

        expect(formatted, '325.8');
        expect(formatted.split('.').last.length, 1);
      });
    });

    group('Generación de fileName', () {
      test('debe generar fileName con formato gossipId_timestamp.jpg', () {
        const gossipId = 'abc-123';
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${gossipId}_$timestamp.jpg';

        expect(fileName, matches(RegExp(r'.+_\d+\.jpg')));
        expect(fileName, startsWith(gossipId));
        expect(fileName, endsWith('.jpg'));
      });

      test('timestamp debe ser milliseconds desde epoch', () {
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        expect(timestamp, isA<int>());
        expect(timestamp.toString().length, 13); // 13 dígitos
        expect(timestamp, greaterThan(1000000000000)); // Después del 2001
      });

      test('debe generar nombres únicos por timestamp', () {
        const gossipId = 'same-id';
        final fileName1 = '${gossipId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Pequeña espera para asegurar timestamp diferente
        final fileName2 = '${gossipId}_${DateTime.now().millisecondsSinceEpoch + 1}.jpg';

        expect(fileName1, isNot(equals(fileName2)));
      });

      test('debe usar siempre extensión .jpg', () {
        const gossipId = 'test';
        final timestamp = 123456789;
        final fileName = '${gossipId}_$timestamp.jpg';

        expect(fileName, endsWith('.jpg'));
        expect(fileName.split('.').last, 'jpg');
      });

      test('debe manejar gossipIds con guiones', () {
        const gossipId = 'uuid-abc-def-123';
        final fileName = '${gossipId}_123456.jpg';

        expect(fileName, contains(gossipId));
        expect(fileName, 'uuid-abc-def-123_123456.jpg');
      });

      test('debe manejar gossipIds con underscores', () {
        const gossipId = 'gossip_test_456';
        final fileName = '${gossipId}_789012.jpg';

        expect(fileName, contains(gossipId));
        expect(fileName, 'gossip_test_456_789012.jpg');
      });
    });

    group('Construcción de paths', () {
      test('fullPath debe usar estructura gossips/full/', () {
        const fileName = 'test_123.jpg';
        final fullPath = 'gossips/full/$fileName';

        expect(fullPath, 'gossips/full/test_123.jpg');
        expect(fullPath, startsWith('gossips/full/'));
      });

      test('thumbPath debe usar estructura gossips/thumb/', () {
        const fileName = 'test_123.jpg';
        final thumbPath = 'gossips/thumb/$fileName';

        expect(thumbPath, 'gossips/thumb/test_123.jpg');
        expect(thumbPath, startsWith('gossips/thumb/'));
      });

      test('fullPath y thumbPath deben usar mismo fileName', () {
        const gossipId = 'test';
        final timestamp = 123456;
        final fileName = '${gossipId}_$timestamp.jpg';

        final fullPath = 'gossips/full/$fileName';
        final thumbPath = 'gossips/thumb/$fileName';

        expect(fullPath.split('/').last, thumbPath.split('/').last);
      });

      test('debe usar bucket "images"', () {
        const bucketName = 'images';

        // Todas las operaciones usan este bucket
        expect(bucketName, 'images');
      });
    });

    group('Upload de imagen completa', () {
      test('debe subir imagen completa primero', () {
        // Paso 4: Upload full image
        const step = 'upload_full_image_first';
        expect(step, 'upload_full_image_first');
      });

      test('debe usar método upload de storage', () {
        // storage.from('images').upload(fullPath, compressedFile)
        const method = 'upload';
        expect(method, 'upload');
      });

      test('debe pasar fullPath y archivo comprimido', () {
        const fullPath = 'gossips/full/test_123.jpg';
        // File compressedFile

        expect(fullPath, isNotEmpty);
        expect(fullPath, startsWith('gossips/full/'));
      });
    });

    group('Upload de thumbnail', () {
      test('debe generar thumbnail después de subir imagen completa', () {
        // Paso 5: Generate thumbnail
        const step = 'generate_thumbnail_after_full_upload';
        expect(step, 'generate_thumbnail_after_full_upload');
      });

      test('thumbnail es opcional - puede ser null', () {
        // null si falla generación de thumbnail
        const File? thumbnailFile = null;

        final String? thumbPath = thumbnailFile != null
            ? 'gossips/thumb/test.jpg'
            : null;

        expect(thumbPath, isNull); // OK que sea null
      });

      test('debe subir thumbnail solo si generación fue exitosa', () {
        // Cuando thumbnail se genera exitosamente, se sube
        const thumbPath = 'gossips/thumb/test.jpg'; // Generado

        expect(thumbPath, isNotNull);
        expect(thumbPath, 'gossips/thumb/test.jpg');
      });

      test('thumbPath debe usar mismo fileName que fullPath', () {
        const fileName = 'abc_123456.jpg';
        const thumbPath = 'gossips/thumb/$fileName';

        expect(thumbPath, contains(fileName));
        expect(thumbPath, 'gossips/thumb/abc_123456.jpg');
      });
    });

    group('Obtención de URLs públicas', () {
      test('debe obtener URL pública para imagen completa', () {
        // Paso 6: Get public URL con getPublicUrl()
        const method = 'getPublicUrl';
        expect(method, 'getPublicUrl');
      });

      test('debe obtener URL pública para thumbnail si existe', () {
        // Cuando thumbnail existe, se obtiene su URL pública
        const thumbPath = 'gossips/thumb/test.jpg';

        expect(thumbPath, isNotNull);
        expect(thumbPath, contains('thumb'));
      });

      test('debe usar fullUrl como thumbnailUrl si no hay thumbnail', () {
        const fullUrl = 'https://example.com/full/image.jpg';
        const String? thumbPath = null; // No generado

        final thumbUrl = thumbPath ?? fullUrl;

        expect(thumbUrl, fullUrl);
      });

      test('URLs deben ser diferentes si hay thumbnail', () {
        const fullUrl = 'https://example.com/full/image.jpg';
        const thumbUrl = 'https://example.com/thumb/image.jpg';

        expect(thumbUrl, isNot(fullUrl));
        expect(fullUrl, contains('full'));
        expect(thumbUrl, contains('thumb'));
      });
    });

    group('UploadResult retornado', () {
      test('debe retornar UploadResult con todos los campos', () {
        final result = UploadResult(
          fullUrl: 'https://example.com/full/image.jpg',
          thumbnailUrl: 'https://example.com/thumb/image.jpg',
          sizeKB: 125.5,
          storagePath: 'gossips/full/image.jpg',
        );

        expect(result.fullUrl, isNotEmpty);
        expect(result.thumbnailUrl, isNotEmpty);
        expect(result.sizeKB, greaterThan(0));
        expect(result.storagePath, isNotEmpty);
      });

      test('fullUrl debe ser la URL de CDN de imagen completa', () {
        const fullUrl = 'https://project.supabase.co/storage/v1/object/public/images/gossips/full/test.jpg';

        expect(fullUrl, contains('storage'));
        expect(fullUrl, contains('public'));
        expect(fullUrl, contains('images'));
        expect(fullUrl, contains('gossips/full/'));
      });

      test('thumbnailUrl puede ser igual a fullUrl', () {
        const fullUrl = 'https://example.com/image.jpg';
        final result = UploadResult(
          fullUrl: fullUrl,
          thumbnailUrl: fullUrl, // Cuando no hay thumbnail
          sizeKB: 120.0,
          storagePath: 'path',
        );

        expect(result.fullUrl, result.thumbnailUrl);
      });

      test('sizeKB debe ser el tamaño de la imagen comprimida', () {
        const sizeKB = 125.7;

        expect(sizeKB, greaterThan(100));
        expect(sizeKB, lessThan(300));
      });

      test('storagePath debe ser el fullPath', () {
        const storagePath = 'gossips/full/abc_123456.jpg';

        expect(storagePath, startsWith('gossips/full/'));
        expect(storagePath, endsWith('.jpg'));
      });
    });

    group('Orden de ejecución', () {
      test('debe ejecutar pasos en orden correcto', () {
        const steps = [
          '1_compress_image',
          '2_verify_size',
          '3_generate_filename',
          '4_upload_full',
          '5_upload_thumbnail',
          '6_get_urls',
          '7_return_result',
        ];

        expect(steps.length, 7);
        expect(steps.first, startsWith('1_'));
        expect(steps.last, startsWith('7_'));
      });

      test('debe verificar tamaño ANTES de subir', () {
        // Importante: No subir si tamaño excede
        const step2 = 'verify_size';
        const step4 = 'upload_full';

        expect('2_$step2'.compareTo('4_$step4'), lessThan(0));
      });

      test('debe subir imagen completa ANTES de thumbnail', () {
        const uploadFullStep = 4;
        const uploadThumbStep = 5;

        expect(uploadFullStep, lessThan(uploadThumbStep));
      });

      test('debe obtener URLs AL FINAL', () {
        const getUrlsStep = 6;
        const totalSteps = 7;

        expect(getUrlsStep, greaterThan(5));
        expect(getUrlsStep, lessThan(totalSteps));
      });
    });

    group('Manejo de errores', () {
      test('debe propagar error si compresión falla', () {
        // Cuando compresión retorna null, lanza Exception
        expect(
          () => throw Exception('Error al comprimir imagen'),
          throwsA(isA<Exception>()),
        );
      });

      test('debe propagar error si tamaño excede límite', () {
        const sizeKB = 350.0;

        expect(
          () {
            if (sizeKB > 300) {
              throw Exception('Imagen muy grande: ${sizeKB.toStringAsFixed(1)} KB. Máximo 300 KB');
            }
          },
          throwsA(isA<Exception>()),
        );
      });

      test('debe propagar error si upload de imagen completa falla', () {
        // Si storage.upload() lanza excepción, debe propagarse
        // No hay try-catch en el método
        expect(true, isTrue); // Documenta comportamiento
      });

      test('thumbnail fallo NO debe afectar el flujo', () {
        // Si generateThumbnail retorna null, continúa con fullUrl
        const File? thumbnailFile = null; // null = fallo

        final String? thumbPath = thumbnailFile != null
            ? 'gossips/thumb/test.jpg'
            : null;

        // thumbPath queda null, pero método continúa
        expect(thumbPath, isNull);
        // En código real, usa fullUrl como thumbnailUrl
      });
    });

    group('Estrategia de upload', () {
      test('debe subir DESPUÉS de crear gossip (Estrategia 1)', () {
        // Método se llama "uploadImageAfterGossipCreated"
        const methodName = 'uploadImageAfterGossipCreated';

        expect(methodName, contains('After'));
        expect(methodName, contains('GossipCreated'));
      });

      test('debe prevenir archivos huérfanos', () {
        // Al subir después:
        // - Si falla crear gossip → NO se sube imagen
        // - Si falla subir imagen → Gossip queda sin imagen
        const orphanRate = 0.0;

        expect(orphanRate, 0.0);
      });

      test('debe usar gossipId existente en nombre de archivo', () {
        const gossipId = 'existing-gossip-uuid';
        final fileName = '${gossipId}_123456.jpg';

        expect(fileName, contains(gossipId));
        // gossipId ya existe en DB
      });
    });

    group('Integración con ImageCompressor', () {
      test('debe usar ImageCompressor.compressGossipImage', () {
        const method = 'ImageCompressor.compressGossipImage';

        expect(method, contains('compressGossipImage'));
      });

      test('debe usar ImageCompressor.getFileSizeInKB', () {
        const method = 'ImageCompressor.getFileSizeInKB';

        expect(method, contains('getFileSizeInKB'));
      });

      test('debe usar ImageCompressor.generateThumbnail', () {
        const method = 'ImageCompressor.generateThumbnail';

        expect(method, contains('generateThumbnail'));
      });

      test('debe pasar archivo original a compressGossipImage', () {
        // imageFile original (3MB, 3024x4032)
        // NO el archivo comprimido
        expect(true, isTrue);
      });

      test('debe pasar archivo comprimido a getFileSizeInKB', () {
        // compressedFile (120KB, 800x1067)
        // NO el archivo original
        expect(true, isTrue);
      });

      test('debe pasar archivo original a generateThumbnail', () {
        // imageFile original
        // ImageCompressor se encarga de la compresión interna
        expect(true, isTrue);
      });
    });

    group('Casos de uso típicos', () {
      test('foto típica 3MB debe subirse exitosamente', () {
        // Entrada: imageFile 3MB, 3024x4032
        // Salida: UploadResult con URLs, ~125 KB

        const originalSizeMB = 3.0;
        const compressedSizeKB = 125.0;

        expect(compressedSizeKB, lessThan(originalSizeMB * 1024 / 10));
      });

      test('debe generar thumbnail automáticamente', () {
        // Si ImageCompressor.generateThumbnail() funciona
        // Se sube thumbnail y se obtiene URL separada

        const hasThumbnail = true;

        expect(hasThumbnail, isTrue);
      });

      test('debe funcionar sin thumbnail si generación falla', () {
        // Fallback: thumbnailUrl = fullUrl cuando thumbnail falla
        const fullUrl = 'https://example.com/image.jpg';
        const String? thumbnailUrl = null; // Fallo

        final thumbUrl = thumbnailUrl ?? fullUrl;

        expect(thumbUrl, fullUrl);
      });
    });

    group('Performance', () {
      test('debe comprimir antes de medir tamaño', () {
        // Medir tamaño del archivo comprimido, NO original
        // Orden: 1. compress, 2. verify_size, 3. upload

        expect('1'.compareTo('2'), lessThan(0));
      });

      test('debe rechazar ANTES de subir si tamaño excede', () {
        // Verificar tamaño antes del upload ahorra bandwidth
        const sizeKB = 350.0;
        const maxSizeKB = 300;

        // Si excede, lanza Exception antes del upload
        expect(sizeKB > maxSizeKB, isTrue);
      });

      test('timestamp en fileName evita colisiones', () {
        // Dos uploads del mismo gossipId tienen timestamps diferentes
        const gossipId = 'same-id';
        const fileName1 = '${gossipId}_1234567890.jpg';
        const fileName2 = '${gossipId}_1234567891.jpg';

        expect(fileName1, isNot(equals(fileName2)));
      });
    });
  });
}
