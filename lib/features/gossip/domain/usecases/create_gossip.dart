import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/error_codes.dart' as error_codes;
import '../../../../core/logging/logging.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../entities/gossip.dart';
import '../entities/create_gossip_input.dart';
import '../repositories/gossip_repository.dart';
import '../validators/gossip_validator.dart';

/// Use case para crear un nuevo gossip
///
/// **FLUJO SEGURO (Fix P1-01):**
///
/// ```
/// 1. Validar input
/// 2. Si hay imagen:
///    a. Leer imagen como bytes
///    b. Convertir a base64
/// 3. Llamar Edge Function que hace TODO atómicamente:
///    - Upload a cuarentena (privado)
///    - Validar MIME real, dimensiones, tamaño
///    - Moderar contenido
///    - Si aprueba: Mover a público + INSERT gossip
///    - Si rechaza: Eliminar de cuarentena
/// 4. Retornar gossip completo (con imagen incluida)
/// ```
///
/// **VENTAJAS:**
/// - ✅ 100% atómico (todo o nada)
/// - ✅ 0% archivos huérfanos
/// - ✅ Validación MIME real (no confía en cliente)
/// - ✅ Cuarentena privada (archivos no públicos hasta aprobar)
/// - ✅ storage_path como fuente de verdad
/// - ✅ Una sola transacción (no múltiples roundtrips)
///
/// **SEGURIDAD:**
/// - Edge Function usa service_role (bypasa RLS)
/// - Cliente NO puede decidir estados (draft vs published)
/// - Moderación obligatoria antes de publicar
/// - Rate limiting atómico (no race conditions)
/// - Rollback automático en cualquier fallo
///
/// Ver: docs/ANALYSIS_P1_01_MEDIA.md
@injectable
class CreateGossip {
  final GossipRepository repository;
  final AuthRepository _authRepository;
  final AppLogger _logger;

  CreateGossip({
    required this.repository,
    required AuthRepository authRepository,
    required AppLogger logger,
  })  : _authRepository = authRepository,
        _logger = logger;

  /// Crea un gossip con imagen opcional
  ///
  /// **Parámetros:**
  /// - `input`: Datos del gossip
  /// - `imageFile`: Archivo de imagen (opcional)
  ///
  /// **Retorna:**
  /// - `Result<Failure, Gossip>` con el gossip creado
  ///
  /// **Ejemplo:**
  /// ```dart
  /// final result = await createGossip(
  ///   input: CreateGossipInput(...),
  ///   imageFile: selectedImage,
  /// );
  /// ```
  Future<Result<Failure, Gossip>> call({
    required CreateGossipInput input,
    File? imageFile,
  }) async {
    try {
      // 0. Verificar que el usuario tenga email verificado
      final currentUserResult = await _authRepository.getCurrentUser();

      final currentUser = currentUserResult.when(
        onSuccess: (user) => user,
        onFailure: (_) => null,
      );

      if (currentUser == null) {
        _logger.w('⚠️ Usuario no autenticado intentando crear gossip');
        return Result.failure(const Failure(
          code: error_codes.ErrorCode.unauthorized,
          technicalMessage: 'Debes iniciar sesión para publicar chismes',
        ));
      }

      if (!currentUser.emailVerified) {
        _logger.w('⚠️ Usuario sin email verificado intentando crear gossip',
          context: {'userId': currentUser.id});
        return Result.failure(const ValidationFailure(
          code: error_codes.ErrorCode.emailNotVerified,
          technicalMessage: 'Debes verificar tu email para publicar chismes',
        ));
      }

      // 1. Validar input antes de proceder
      final validationError = GossipValidator.validateInput(input);
      if (validationError != null) {
        return Result.failure(validationError);
      }

      // 2. Convertir imagen a base64 (si hay)
      String? imageBase64;
      if (imageFile != null) {
        try {
          _logger.d('Convirtiendo imagen a base64');
          final bytes = await imageFile.readAsBytes();
          imageBase64 = base64Encode(bytes);
          _logger.d('Imagen convertida', context: {
            'size': bytes.length,
            'base64Length': imageBase64.length,
          });
        } catch (e) {
          _logger.e('Error al leer imagen', error: e);
          return Result.failure(const ValidationFailure(
            code: error_codes.ErrorCode.invalidInput,
            technicalMessage: 'Failed to read image file',
          ));
        }
      }

      // 3. Crear gossip (con imagen si hay) vía Edge Function
      // La Edge Function hace TODO atómicamente:
      // - Upload a cuarentena
      // - Validar MIME, dimensiones
      // - Moderar contenido
      // - Si aprueba: Mover a público + INSERT
      // - Si rechaza: Eliminar de cuarentena
      _logger.i('Creando gossip', context: {
        'hasImage': imageFile != null,
        'subject': input.subject,
      });

      final createResult = await repository.createWithImage(
        input,
        imageBase64,
      );

      return createResult.when(
        onSuccess: (gossip) {
          _logger.i('✅ Gossip creado exitosamente', context: {
            'id': gossip.id,
            'status': gossip.status.value,
            'hasImage': gossip.imageUrl != null,
          });
          return Result.success(gossip);
        },
        onFailure: (error) {
          _logger.w('❌ Error al crear gossip', context: {
            'error': error.toString(),
          });
          return Result.failure(error);
        },
      );
    } catch (e, stackTrace) {
      _logger.e('Error en CreateGossip', error: e, stackTrace: stackTrace);
      return Result.failure(Failure(
        code: error_codes.ErrorCode.unknownError,
        technicalMessage: 'Error al crear el chisme: $e',
      ));
    }
  }
}
