import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:chismes/core/media/supabase_storage_service.dart';
import 'package:chismes/core/logging/logging.dart';

import '../../helpers/fake_image_compress.dart';

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

  group('SupabaseStorageService - Constructor', () {
    test('debe crear instancia con SupabaseClient', () {
      final mockSupabase = MockSupabaseClient();
      final mockLogger = MockAppLogger();
      final service = SupabaseStorageService(mockSupabase, mockLogger);

      expect(service, isNotNull);
      expect(service, isA<SupabaseStorageService>());
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

  group('SupabaseStorageService - uploadImageAfterGossipCreated', () {
    late MockSupabaseClient mockSupabase;
    late MockSupabaseStorageClient mockStorage;
    late MockStorageFileApi mockFileApi;
    late MockAppLogger mockLogger;
    late SupabaseStorageService service;
    late FakeImageCompress compress;
    late Directory dir;
    late File original;
    // KB que "produce" el plugin para la imagen completa y el thumbnail.
    late int? fullKB;
    late int? thumbKB;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockStorage = MockSupabaseStorageClient();
      mockFileApi = MockStorageFileApi();
      mockLogger = MockAppLogger();
      service = SupabaseStorageService(mockSupabase, mockLogger);
      when(mockSupabase.storage).thenReturn(mockStorage);
      when(mockStorage.from('images')).thenReturn(mockFileApi);
      when(mockFileApi.upload(any, any)).thenAnswer(
          (inv) async => 'images/${inv.positionalArguments[0]}');
      when(mockFileApi.getPublicUrl(any)).thenAnswer(
          (inv) => 'https://cdn.test/${inv.positionalArguments[0]}');

      fullKB = 120;
      thumbKB = 30;
      compress = FakeImageCompress.install();
      addTearDown(compress.uninstall);
      compress.outputBytes = (call) {
        final kb = call.targetPath.endsWith('_thumb.jpg') ? thumbKB : fullKB;
        return kb == null ? null : kb * 1024;
      };
      dir = Directory.systemTemp.createTempSync('storage_service_test');
      addTearDown(() => dir.deleteSync(recursive: true));
      original = File('${dir.path}/foto.jpg')
        ..writeAsBytesSync(List.filled(2048 * 1024, 1));
    });

    Future<UploadResult> upload() => service.uploadImageAfterGossipCreated(
        gossipId: 'gossip-1', imageFile: original);

    List<String> uploadedPaths() => verify(mockFileApi.upload(captureAny, any))
        .captured
        .cast<String>();

    test('sube imagen completa y thumbnail con el mismo nombre y retorna URLs',
        () async {
      final result = await upload();

      final paths = uploadedPaths();
      expect(paths, hasLength(2));
      expect(paths[0], matches(RegExp(r'^gossips/full/gossip-1_\d{13}\.jpg$')));
      expect(paths[1], paths[0].replaceFirst('full/', 'thumb/'));
      expect(result.storagePath, paths[0]);
      expect(result.fullUrl, 'https://cdn.test/${paths[0]}');
      expect(result.thumbnailUrl, 'https://cdn.test/${paths[1]}');
      expect(result.sizeKB, 120);
      verify(mockLogger.d('📸 Imagen comprimida',
              context: {'originalKB': 2048.0, 'compressedKB': 120.0}))
          .called(1);
    });

    test('sube el archivo comprimido, no el original', () async {
      await upload();

      final files =
          verify(mockFileApi.upload(any, captureAny)).captured.cast<File>();
      expect(files.map((f) => f.path), [
        '${dir.path}/foto_compressed.jpg',
        '${dir.path}/foto_thumb.jpg',
      ]);
    });

    test('usa la URL completa como thumbnail si no se pudo generar', () async {
      thumbKB = null;

      final result = await upload();

      final paths = uploadedPaths();
      expect(paths, hasLength(1));
      expect(paths.single, startsWith('gossips/full/'));
      expect(result.thumbnailUrl, result.fullUrl);
    });

    test('acepta exactamente 300 KB', () async {
      fullKB = 300;

      final result = await upload();

      expect(result.sizeKB, 300);
    });

    test('lanza Exception y no sube nada si la compresión falla', () async {
      fullKB = null;

      await expectLater(
        upload(),
        throwsA(isA<Exception>().having(
            (e) => e.toString(), 'message', contains('Error comprimir imagen'))),
      );
      verifyNever(mockFileApi.upload(any, any));
    });

    test('lanza Exception con el tamaño y no sube nada si supera 300 KB',
        () async {
      fullKB = 301;

      await expectLater(
        upload(),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Imagen muy grande: 301.0 KB. Máximo 300 KB'))),
      );
      verifyNever(mockFileApi.upload(any, any));
    });

    test('propaga el error si falla la subida de la imagen completa', () async {
      when(mockFileApi.upload(any, any))
          .thenThrow(const StorageException('quota exceeded'));

      await expectLater(upload(), throwsA(isA<StorageException>()));
      verifyNever(mockFileApi.getPublicUrl(any));
    });
  });
}
