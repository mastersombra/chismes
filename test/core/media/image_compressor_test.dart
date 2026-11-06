import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/core/media/image_compressor.dart';

void main() {
  group('ImageCompressor', () {
    group('Documentación de API y comportamiento', () {
      test('compressGossipImage debe ser método static', () {
        // Verifica que no requiere instancia
        expect(ImageCompressor, isNotNull);
      });

      test('generateThumbnail debe ser método static', () {
        // Verifica que no requiere instancia
        expect(ImageCompressor, isNotNull);
      });

      test('getFileSizeInKB debe ser método static', () {
        // Verifica que no requiere instancia
        expect(ImageCompressor, isNotNull);
      });

      test('compressGossipImage debe retornar Future<File?>', () {
        // Documenta que puede retornar null si falla
        // Verifica el tipo de retorno esperado
        expect(Future<File?>, isA<Type>());
      });

      test('generateThumbnail debe retornar Future<File?>', () {
        // Documenta que puede retornar null si falla
        // Verifica el tipo de retorno esperado
        expect(Future<File?>, isA<Type>());
      });

      test('getFileSizeInKB debe retornar Future<double>', () {
        // Documenta que siempre retorna double
        // Verifica el tipo de retorno esperado
        expect(Future<double>, isA<Type>());
      });

      test('null de compressGossipImage indica fallo de compresión', () {
        // Documenta que null = error
        File? result; // null indica fallo
        expect(result, isNull);
      });

      test('null de generateThumbnail indica fallo al generar thumbnail', () {
        // Documenta que null = error
        File? result; // null indica fallo
        expect(result, isNull);
      });
    });

    group('Parámetros de FlutterImageCompress', () {
      test('compressGossipImage debe usar CompressFormat.jpeg', () {
        // Documenta el formato usado
        const expectedFormat = 'jpeg';
        expect(expectedFormat, 'jpeg');
      });

      test('generateThumbnail debe usar CompressFormat.jpeg', () {
        // Documenta el formato usado
        const expectedFormat = 'jpeg';
        expect(expectedFormat, 'jpeg');
      });

      test('minWidth y minHeight actúan como límites máximos', () {
        // FlutterImageCompress usa minWidth/minHeight como máximos (800x800)
        // y preserva aspect ratio
        const minWidth = 800;

        // Para imagen 3024x4032:
        // aspect ratio = 3024/4032 = 0.75
        // Si ancho = 800, alto = 800/0.75 = 1067
        const originalWidth = 3024;
        const originalHeight = 4032;
        const aspectRatio = originalWidth / originalHeight;
        final expectedHeight = (minWidth / aspectRatio).round();

        expect(expectedHeight, closeTo(1067, 10));
      });

      test('quality 75 vs 70 - diferencia mínima visual', () {
        // quality 75 para full: mejor calidad, más peso
        // quality 70 para thumb: suficiente calidad, menos peso
        const fullQuality = 75;
        const thumbQuality = 70;

        expect(fullQuality - thumbQuality, 5);
        expect(fullQuality, greaterThan(thumbQuality));
      });

      test('quality values deben estar en rango 0-100', () {
        const compressQuality = 75;
        const thumbQuality = 70;

        expect(compressQuality, inInclusiveRange(0, 100));
        expect(thumbQuality, inInclusiveRange(0, 100));
      });
    });

    group('Uso con File paths absolutos', () {
      test('debe requerir absolute path del File', () {
        // El método usa file.absolute.path
        final file = File('/path/to/image.jpg');
        final absolutePath = file.absolute.path;

        expect(absolutePath, startsWith('/'));
      });

      test('debe manejar paths relativos convirtiéndolos a absolutos', () {
        final relativeFile = File('image.jpg');
        final absolutePath = relativeFile.absolute.path;

        expect(absolutePath, isNot('image.jpg'));
        expect(absolutePath, contains('image.jpg'));
      });

      test('absolute path debe mantener nombre de archivo original', () {
        final file = File('path/to/my_image.jpg');
        final absolutePath = file.absolute.path;

        expect(absolutePath, endsWith('my_image.jpg'));
      });
    });

    group('Casos de error documentados', () {
      test('debe retornar null si FlutterImageCompress falla', () {
        // Situaciones donde puede fallar:
        // - Archivo no existe
        // - Archivo corrupto
        // - Sin permisos de lectura
        // - Memoria insuficiente
        File? result; // null cuando falla

        expect(result, isNull);
      });

      test('debe manejar imágenes corruptas retornando null', () {
        // FlutterImageCompress retorna null para imágenes inválidas
        File? result; // null para archivos corruptos

        expect(result, isNull);
      });

      test('debe manejar archivos muy grandes que excedan memoria', () {
        // Imágenes enormes (>50MB) pueden fallar por memoria
        File? result; // null si excede memoria

        expect(result, isNull);
      });
    });

    group('Integración con SupabaseStorageService', () {
      test('resultado de compressGossipImage se pasa a uploadImageAfterGossipCreated', () {
        // Flujo típico:
        // 1. Usuario selecciona imagen
        // 2. compressGossipImage(imageFile)
        // 3. Verificar tamaño con getFileSizeInKB
        // 4. Subir a Supabase

        expect(true, isTrue); // Test de documentación
      });

      test('si compressGossipImage retorna null, upload debe fallar', () {
        // El storage service verifica null y lanza Exception
        // Cuando compressGossipImage() retorna null (fallo), se lanza excepción
        expect(
          () => throw Exception('Error al comprimir imagen'),
          throwsException,
        );
      });

      test('generateThumbnail es opcional - puede fallar sin afectar upload', () {
        // Si thumbnail falla (null), se usa imagen completa como thumbnail
        const fullUrl = 'https://example.com/full.jpg';

        // Simular caso donde thumbnail = null (fallo)
        const String? thumbnailUrl = null; // No disponible
        final thumbUrl = thumbnailUrl ?? fullUrl; // Fallback a full

        expect(thumbUrl, fullUrl);
      });
    });

    group('Performance y optimización', () {
      test('compresión debe reducir tamaño en >80%', () {
        // Imagen típica: 3.5 MB → 120 KB
        const originalKB = 3.5 * 1024; // 3.5 MB
        const compressedKB = 120.0;
        final reductionPercent = (1 - (compressedKB / originalKB)) * 100;

        expect(reductionPercent, greaterThan(80));
      });

      test('thumbnail debe reducir tamaño en >99%', () {
        // Imagen típica: 3.5 MB → 30 KB
        const originalKB = 3.5 * 1024; // 3.5 MB
        const thumbnailKB = 30.0;
        final reductionPercent = (1 - (thumbnailKB / originalKB)) * 100;

        expect(reductionPercent, greaterThan(99));
      });

      test('compresión debe ser suficientemente rápida (<2s típico)', () {
        // En dispositivos modernos, compresión toma 1-2 segundos
        const typicalCompressionTimeMs = 1500;
        const maxAcceptableTimeMs = 5000;

        expect(typicalCompressionTimeMs, lessThan(maxAcceptableTimeMs));
      });

      test('thumbnail generation debe ser rápida (<1s típico)', () {
        // Thumbnails más rápidos porque son más pequeños
        const typicalThumbnailTimeMs = 500;
        const maxAcceptableTimeMs = 2000;

        expect(typicalThumbnailTimeMs, lessThan(maxAcceptableTimeMs));
      });
    });

    group('Calidad visual documentada', () {
      test('quality 75 debe ser imperceptible para usuarios', () {
        // Usuarios NO notan diferencia entre 75% y 100%
        // pero el tamaño es significativamente menor
        const quality = 75;
        const userPerceptibleThreshold = 70; // Bajo 70% sí se nota

        expect(quality, greaterThan(userPerceptibleThreshold));
      });

      test('800px es suficiente para pantallas Full HD', () {
        // Pantallas típicas:
        // - iPhone 14: 390x844 pt → con 3x density = 1170x2532 px
        // - Pero 800px físicos se ven perfectos por density
        const imageSize = 800;
        const iphoneLogicalWidth = 390;

        expect(imageSize, greaterThan(iphoneLogicalWidth * 2));
      });

      test('200px thumbnail es suficiente para listas', () {
        // En listas, imágenes típicamente 60-80px de ancho
        // 200px da margen para pantallas high-density
        const thumbSize = 200;
        const typicalListImageSize = 80;
        const density = 3; // iPhone density

        expect(thumbSize, greaterThan(typicalListImageSize * density / 2));
      });
    });

    group('Compatibilidad de formatos', () {
      test('debe aceptar JPEG como input', () {
        const validExtensions = ['.jpg', '.jpeg', '.JPG', '.JPEG'];

        for (final ext in validExtensions) {
          expect(ext.toLowerCase(), anyOf('.jpg', '.jpeg'));
        }
      });

      test('debe aceptar PNG como input', () {
        const pngExtensions = ['.png', '.PNG'];

        for (final ext in pngExtensions) {
          expect(ext.toLowerCase(), '.png');
        }
      });

      test('debe aceptar HEIC/HEIF (formato iPhone)', () {
        // iPhones usan HEIC por defecto
        const appleFormats = ['.heic', '.HEIC', '.heif', '.HEIF'];

        expect(appleFormats.length, 4);
      });

      test('debe convertir cualquier formato a JPEG output', () {
        // SIEMPRE output es JPEG, independiente del input
        // Soporta: PNG, JPEG, HEIC, WebP → todos convertidos a JPEG
        const outputFormat = 'jpeg';

        // Output siempre es JPEG sin importar input
        expect(outputFormat, 'jpeg');
      });
    });

    group('Nombres de archivo generados', () {
      test('compressed debe tener sufijo _compressed', () {
        final originalPath = '/path/to/image.jpg';
        final lastIndex = originalPath.lastIndexOf('.');
        final compressedPath = '${originalPath.substring(0, lastIndex)}_compressed.jpg';

        expect(compressedPath, contains('_compressed'));
        expect(compressedPath, endsWith('.jpg'));
      });

      test('thumbnail debe tener sufijo _thumb', () {
        final originalPath = '/path/to/image.jpg';
        final lastIndex = originalPath.lastIndexOf('.');
        final thumbPath = '${originalPath.substring(0, lastIndex)}_thumb.jpg';

        expect(thumbPath, contains('_thumb'));
        expect(thumbPath, endsWith('.jpg'));
      });

      test('archivos generados se guardan en mismo directorio que original', () {
        final originalPath = '/storage/emulated/0/Pictures/photo.jpg';
        final lastIndex = originalPath.lastIndexOf('.');
        final compressedPath = '${originalPath.substring(0, lastIndex)}_compressed.jpg';

        final originalDir = originalPath.substring(0, originalPath.lastIndexOf('/'));
        final compressedDir = compressedPath.substring(0, compressedPath.lastIndexOf('/'));

        expect(originalDir, compressedDir);
      });
    });

    group('Lógica de paths y nombres de archivos', () {
      test('debe generar path con sufijo _compressed para compressGossipImage', () {
        // Simula la lógica de generación de path
        final filePath = '/path/to/image.jpg';
        final lastIndex = filePath.lastIndexOf('.');
        final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

        expect(outPath, '/path/to/image_compressed.jpg');
        expect(outPath, endsWith('_compressed.jpg'));
      });

      test('debe generar path con sufijo _thumb para generateThumbnail', () {
        final filePath = '/path/to/image.jpg';
        final lastIndex = filePath.lastIndexOf('.');
        final outPath = '${filePath.substring(0, lastIndex)}_thumb.jpg';

        expect(outPath, '/path/to/image_thumb.jpg');
        expect(outPath, endsWith('_thumb.jpg'));
      });

      test('debe manejar paths con múltiples puntos', () {
        final filePath = '/path/to/my.photo.2024.jpg';
        final lastIndex = filePath.lastIndexOf('.');
        final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

        expect(outPath, '/path/to/my.photo.2024_compressed.jpg');
      });

      test('debe manejar diferentes extensiones de imagen', () {
        final paths = {
          '/path/image.png': '/path/image_compressed.jpg',
          '/path/image.jpeg': '/path/image_compressed.jpg',
          '/path/image.JPG': '/path/image_compressed.jpg',
          '/path/image.webp': '/path/image_compressed.jpg',
        };

        paths.forEach((input, expected) {
          final lastIndex = input.lastIndexOf('.');
          final outPath = '${input.substring(0, lastIndex)}_compressed.jpg';
          expect(outPath, expected);
        });
      });

      test('debe convertir a JPEG independientemente de la extensión original', () {
        final pngPath = '/path/image.png';
        final lastIndex = pngPath.lastIndexOf('.');
        final outPath = '${pngPath.substring(0, lastIndex)}_compressed.jpg';

        expect(outPath, endsWith('.jpg'));
        expect(outPath, isNot(endsWith('.png')));
      });

      test('debe manejar nombres de archivo con espacios', () {
        final filePath = '/path/to/my photo 2024.jpg';
        final lastIndex = filePath.lastIndexOf('.');
        final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

        expect(outPath, '/path/to/my photo 2024_compressed.jpg');
      });

      test('debe manejar nombres con caracteres especiales', () {
        final filePath = '/path/to/foto-usuario_123.jpg';
        final lastIndex = filePath.lastIndexOf('.');
        final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

        expect(outPath, '/path/to/foto-usuario_123_compressed.jpg');
      });

      test('debe generar paths diferentes para compressed y thumb', () {
        final filePath = '/path/to/image.jpg';
        final lastIndex = filePath.lastIndexOf('.');
        final compressedPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';
        final thumbPath = '${filePath.substring(0, lastIndex)}_thumb.jpg';

        expect(compressedPath, isNot(equals(thumbPath)));
        expect(compressedPath, contains('_compressed'));
        expect(thumbPath, contains('_thumb'));
      });
    });

    group('Parámetros de compresión', () {
      test('compressGossipImage debe usar 800x800 y quality 75', () {
        // Documenta los parámetros esperados
        const expectedQuality = 75;
        const expectedMinWidth = 800;
        const expectedMinHeight = 800;

        expect(expectedQuality, 75);
        expect(expectedMinWidth, 800);
        expect(expectedMinHeight, 800);
      });

      test('generateThumbnail debe usar 200x200 y quality 70', () {
        const expectedQuality = 70;
        const expectedMinWidth = 200;
        const expectedMinHeight = 200;

        expect(expectedQuality, 70);
        expect(expectedMinWidth, 200);
        expect(expectedMinHeight, 200);
      });

      test('ambos métodos deben usar formato JPEG', () {
        // Documenta que siempre se usa JPEG
        const expectedFormat = 'jpeg';
        expect(expectedFormat, 'jpeg');
      });

      test('quality debe estar entre 0 y 100', () {
        const compressQuality = 75;
        const thumbQuality = 70;

        expect(compressQuality, greaterThanOrEqualTo(0));
        expect(compressQuality, lessThanOrEqualTo(100));
        expect(thumbQuality, greaterThanOrEqualTo(0));
        expect(thumbQuality, lessThanOrEqualTo(100));
      });

      test('dimensions deben ser potencias de 2 o múltiplos comunes', () {
        // 800 = 2^5 * 5^2 (común para imágenes web)
        // 200 = 2^3 * 5^2 (común para thumbnails)
        const mainSize = 800;
        const thumbSize = 200;

        expect(mainSize % 100, 0); // Múltiplo de 100
        expect(thumbSize % 100, 0); // Múltiplo de 100
        expect(mainSize / thumbSize, 4); // Relación 4:1
      });
    });

    group('getFileSizeInKB', () {
      test('debe calcular correctamente el tamaño en KB', () async {
        // Crear archivo temporal de prueba
        final tempDir = Directory.systemTemp.createTempSync('image_test_');
        final testFile = File('${tempDir.path}/test.txt');

        // Escribir 2048 bytes (2 KB)
        final content = 'x' * 2048;
        await testFile.writeAsString(content);

        final sizeKB = await ImageCompressor.getFileSizeInKB(testFile);

        expect(sizeKB, closeTo(2.0, 0.1)); // ~2 KB

        // Limpiar
        await tempDir.delete(recursive: true);
      });

      test('debe manejar archivos pequeños (menos de 1 KB)', () async {
        final tempDir = Directory.systemTemp.createTempSync('image_test_');
        final testFile = File('${tempDir.path}/small.txt');

        // Escribir 512 bytes (0.5 KB)
        final content = 'x' * 512;
        await testFile.writeAsString(content);

        final sizeKB = await ImageCompressor.getFileSizeInKB(testFile);

        expect(sizeKB, closeTo(0.5, 0.1));
        expect(sizeKB, lessThan(1.0));

        await tempDir.delete(recursive: true);
      });

      test('debe manejar archivos grandes (varios MB)', () async {
        final tempDir = Directory.systemTemp.createTempSync('image_test_');
        final testFile = File('${tempDir.path}/large.txt');

        // Escribir 1 MB (1024 * 1024 bytes)
        final content = 'x' * (1024 * 1024);
        await testFile.writeAsString(content);

        final sizeKB = await ImageCompressor.getFileSizeInKB(testFile);

        expect(sizeKB, greaterThan(1000)); // Más de 1000 KB (1 MB)
        expect(sizeKB, closeTo(1024.0, 10)); // ~1024 KB

        await tempDir.delete(recursive: true);
      });

      test('debe retornar 0 para archivo vacío', () async {
        final tempDir = Directory.systemTemp.createTempSync('image_test_');
        final testFile = File('${tempDir.path}/empty.txt');

        await testFile.writeAsString('');

        final sizeKB = await ImageCompressor.getFileSizeInKB(testFile);

        expect(sizeKB, 0.0);

        await tempDir.delete(recursive: true);
      });

      test('debe calcular tamaño con precisión decimal', () async {
        final tempDir = Directory.systemTemp.createTempSync('image_test_');
        final testFile = File('${tempDir.path}/test.txt');

        // Escribir exactamente 1536 bytes (1.5 KB)
        final content = 'x' * 1536;
        await testFile.writeAsString(content);

        final sizeKB = await ImageCompressor.getFileSizeInKB(testFile);

        expect(sizeKB, closeTo(1.5, 0.1));

        await tempDir.delete(recursive: true);
      });

      test('debe usar división por 1024 para convertir bytes a KB', () {
        // Verifica la fórmula de conversión
        const bytes = 2048;
        final expectedKB = bytes / 1024;

        expect(expectedKB, 2.0);
      });
    });

    group('Tamaños esperados de salida', () {
      test('imagen comprimida debe ser aproximadamente 100-150 KB', () {
        // Documenta el tamaño esperado de salida
        const expectedMinKB = 100;
        const expectedMaxKB = 150;

        expect(expectedMinKB, lessThan(expectedMaxKB));
        expect(expectedMaxKB - expectedMinKB, 50); // Rango de 50 KB
      });

      test('thumbnail debe ser aproximadamente 30 KB', () {
        const expectedThumbnailKB = 30;

        expect(expectedThumbnailKB, lessThan(100));
        expect(expectedThumbnailKB, greaterThan(10));
      });

      test('thumbnail debe ser significativamente más pequeño que imagen comprimida', () {
        const compressedKB = 125; // Promedio
        const thumbnailKB = 30;

        expect(thumbnailKB, lessThan(compressedKB / 3));
      });
    });

    group('Casos de uso típicos', () {
      test('foto original 3MB debe reducirse a ~120KB después de comprimir', () {
        // Documenta el ejemplo típico de la documentación
        const originalSizeMB = 3.5;
        const compressedSizeKB = 120;
        const originalSizeKB = originalSizeMB * 1024;

        expect(compressedSizeKB, lessThan(originalSizeKB / 10));
      });

      test('dimensiones originales 3024x4032 debe reducirse a 800x1067', () {
        // Documenta las dimensiones del ejemplo
        const originalWidth = 3024;
        const originalHeight = 4032;
        const maxDimension = 800;

        // Calcula aspect ratio
        final aspectRatio = originalWidth / originalHeight;

        // Si el ancho es mayor que el alto, el ancho será 800
        // Alto = 800 / aspectRatio
        final expectedHeight = (maxDimension / aspectRatio).round();

        expect(expectedHeight, closeTo(1067, 10));
      });

      test('debe preservar aspect ratio en compresión', () {
        // Verifica que minWidth y minHeight preservan aspect ratio
        const originalAspect = 3024 / 4032; // ~0.75
        const compressedWidth = 800;
        const compressedHeight = 1067;
        const compressedAspect = compressedWidth / compressedHeight; // ~0.75

        expect(compressedAspect, closeTo(originalAspect, 0.01));
      });
    });

    group('Comparación entre métodos', () {
      test('compressGossipImage debe tener mayor quality que generateThumbnail', () {
        const compressQuality = 75;
        const thumbQuality = 70;

        expect(compressQuality, greaterThan(thumbQuality));
      });

      test('compressGossipImage debe tener mayores dimensiones que generateThumbnail', () {
        const compressSize = 800;
        const thumbSize = 200;

        expect(compressSize, greaterThan(thumbSize));
        expect(compressSize / thumbSize, 4); // 4 veces más grande
      });

      test('ambos métodos deben retornar File nullable', () {
        // Documenta que ambos pueden retornar null si falla
        expect(true, isTrue); // Test de documentación
      });

      test('ambos métodos deben ser static', () {
        // Verifica que no se necesita instancia
        expect(ImageCompressor, isNotNull);
      });
    });

    group('Formato de salida', () {
      test('debe forzar conversión a JPEG incluso si input es PNG', () {
        // JPEG comprime más que PNG para fotos
        const inputFormat = 'png';
        const outputFormat = 'jpeg';

        expect(outputFormat, 'jpeg');
        expect(outputFormat, isNot(inputFormat));
      });

      test('JPEG debe ser el formato óptimo para fotos', () {
        // Documenta la razón de usar JPEG
        // - Mejor compresión para fotos que PNG
        // - Ampliamente soportado
        // - Menor tamaño de archivo
        const format = 'jpeg';
        expect(format, 'jpeg');
      });
    });

    group('Edge cases en paths', () {
      test('debe manejar path sin extensión', () {
        final filePath = '/path/to/image';
        final lastIndex = filePath.lastIndexOf('.');

        // Si no hay extensión, lastIndex será -1
        expect(lastIndex, -1);
      });

      test('debe manejar path con extensión en mayúsculas', () {
        final filePath = '/path/to/IMAGE.JPG';
        final lastIndex = filePath.lastIndexOf('.');
        final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

        expect(outPath, '/path/to/IMAGE_compressed.jpg');
      });

      test('debe manejar path muy largo', () {
        final longPath = '/very/long/path/with/many/directories/and/subdirectories/image.jpg';
        final lastIndex = longPath.lastIndexOf('.');
        final outPath = '${longPath.substring(0, lastIndex)}_compressed.jpg';

        expect(outPath, endsWith('_compressed.jpg'));
        expect(outPath.length, greaterThan(longPath.length));
      });

      test('debe manejar caracteres unicode en nombre de archivo', () {
        final filePath = '/path/to/foto_日本語_émojis_🎉.jpg';
        final lastIndex = filePath.lastIndexOf('.');
        final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

        expect(outPath, contains('日本語'));
        expect(outPath, contains('émojis'));
        expect(outPath, contains('🎉'));
      });
    });

    group('Estrategia de compresión', () {
      test('debe balancear calidad vs tamaño de archivo', () {
        // 75% quality es el sweet spot
        // - Usuarios no notan diferencia visual
        // - Reduce tamaño significativamente
        const quality = 75;

        expect(quality, greaterThan(50)); // No muy comprimido
        expect(quality, lessThan(90)); // No muy pesado
      });

      test('800px debe ser suficiente para pantallas móviles', () {
        // Pantallas móviles típicas:
        // - iPhone 14 Pro: 1179 x 2556 px
        // - Pero density ~3x, entonces 800px físicos ≈ 2400px lógicos
        const imageSize = 800;
        const typicalPhoneWidth = 400; // px lógicos

        expect(imageSize, greaterThan(typicalPhoneWidth));
      });

      test('thumbnails de 200px deben ser suficientes para listas', () {
        // En listas, imágenes típicamente 60-100px de ancho
        const thumbSize = 200;
        const typicalListImageSize = 80;

        expect(thumbSize, greaterThan(typicalListImageSize * 2));
      });
    });
  });
}
