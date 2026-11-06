import '../entities/create_gossip_input.dart';
import '../entities/gossip.dart';
import '../../../location/domain/entities/country.dart';
import '../../../location/domain/entities/region.dart';
import '../../../location/domain/entities/city.dart';
import '../../../../core/error/error_codes.dart';
import '../../../../core/error/failure.dart';
import '../services/gossip_state_machine.dart';

/// Validador local de reglas de negocio para Gossip
///
///  IMPORTANTE: Este validator solo hace validación local (cliente). 
///
///  ⚠️ SEGURIDAD: El backend debe tener límites independientes de Flutter. 
///
///  Validación en Flutter (UX validation): 
/// - Mejora la experiencia del usuario
/// - Feedback inmediato antes de enviar
/// - Reduce llamadas innecesarias al backend
///
///  Validación en Backend (security validation): 
/// - Previene manipulación maliciosa
/// - Alguien puede llamar directamente al backend y bypassar Flutter
/// - Debe tener límites independientes y más estrictos
///
///  Flujo completo de validación en producción: 
/// ```
/// Flutter (UX validation)
///   ↓
/// Backend (security validation)
///   ↓
/// Business validation
///   ↓
/// Rate limit
///   ↓
/// Moderación
///   ↓
/// Database
/// ```
///
///  Validaciones locales (seguras en cliente): 
/// - Campos requeridos
/// - Longitudes máximas
/// - Formato básico
/// - Consistencia de jerarquía de ubicación
/// - Combinaciones válidas de estado
///
///  Validaciones de backend (NO implementadas aquí): 
/// - subject <= 200 (seguridad)
/// - content <= 1000 (seguridad)
/// - max media size (ej: 5MB imagen, 10MB audio)
/// - max audio duration (ej: 5 minutos)
/// - max requests (rate limit)
/// - max gossips/user/time (ej: 10/hora, 100/día)
class GossipValidator {
  GossipValidator._();

  /// Longitudes máximas permitidas (UX validation)
  ///
  ///  Decisión de diseño: 
  /// - subject: 200 caracteres (título breve)
  /// - content: 1000 caracteres (narrativa moderada)
  ///
  ///  Razonamiento: 
  /// - Suficiente para expresar ideas sin ser excesivo
  /// - Mantiene feed legible y rápido de leer
  /// - Compatible con mobile UX (pantallas pequeñas)
  ///
  ///  ⚠️ Backend debe validar estos límites independientemente 
  static const int maxSubjectLength = 200;
  static const int maxContentLength = 1000;

  /// Valida un CreateGossipInput completo (validación local)
  ///
  ///  Propósito:  Validar todos los campos antes de enviar al backend
  ///  Uso:  Controller llama este método antes de createGossip use case
  ///  Retorna:  Failure si hay errores, null si es válido
  ///
  ///  Validaciones: 
  /// - Subject: requerido, <= 200 caracteres
  /// - Content: requerido, <= 1000 caracteres
  /// - Location: countryId, regionId, cityId requeridos
  ///
  ///  Ejemplo: 
  /// ```dart
  /// final error = GossipValidator.validateInput(input);
  /// if (error != null) {
  ///   // Mostrar error al usuario
  /// }
  /// ```
  static Failure? validateInput(CreateGossipInput input) {
    final subjectError = validateSubject(input.subject);
    if (subjectError != null) return subjectError;

    final contentError = validateContent(input.content);
    if (contentError != null) return contentError;

    final locationError = validateLocation(
      input.countryId,
      input.regionId,
      input.cityId,
    );
    if (locationError != null) return locationError;

    return null;
  }

  /// Valida el subject (sobre quién o dónde es el chisme)
  ///
  ///  Propósito:  Validar que el subject es válido
  ///  Validaciones: 
  /// - No puede estar vacío
  /// - No puede exceder 200 caracteres
  ///
  ///  Uso:  UX validation en formulario
  ///
  ///  Ejemplo: 
  /// ```dart
  /// final error = GossipValidator.validateSubject('');
  /// // Returns ValidationFailure (campo requerido)
  ///
  /// final error2 = GossipValidator.validateSubject('a'  201);
  /// // Returns ValidationFailure (excede longitud)
  /// ```
  static ValidationFailure? validateSubject(String subject) {
    final trimmed = subject.trim();

    if (trimmed.isEmpty) {
      return const ValidationFailure(
        code: ErrorCode.missingRequiredField,
      );
    }

    if (trimmed.length > maxSubjectLength) {
      return const ValidationFailure(
        code: ErrorCode.invalidInput,
      );
    }

    return null;
  }

  /// Valida el contenido del chisme (validación local)
  ///
  ///  Propósito:  Validar que el content es válido
  ///  Validaciones: 
  /// - No puede estar vacío
  /// - No puede exceder 1000 caracteres
  ///
  ///  ⚠️ NOTA: La validación de contenido apropiado debe hacerse en el backend 
  /// - Este método solo valida longitud
  /// - La moderación de contenido (lenguaje ofensivo, etc.) es responsabilidad del backend
  /// - Motor automático revisa contenido en backend antes de publicar
  ///
  ///  Uso:  UX validation en formulario
  static ValidationFailure? validateContent(String content) {
    final trimmed = content.trim();

    if (trimmed.isEmpty) {
      return const ValidationFailure(
        code: ErrorCode.missingRequiredField,
      );
    }

    if (trimmed.length > maxContentLength) {
      return const ValidationFailure(
        code: ErrorCode.invalidInput,
      );
    }

    return null;
  }

  /// Valida la ubicación completa (campos requeridos)
  ///
  ///  Propósito:  Validar que countryId, regionId y cityId están presentes
  ///  Validaciones: 
  /// - countryId: requerido
  /// - regionId: requerido
  /// - cityId: requerido
  ///
  ///  Razonamiento: 
  /// - Ubicación es crítica para el feed (filtrado por ubicación)
  /// - No permitimos chismes sin ubicación
  ///
  ///  Uso:  UX validation en formulario
  static DataFailure? validateLocation(
    String? countryId,
    String? regionId,
    String? cityId,
  ) {
    if (countryId == null || countryId.isEmpty) {
      return const DataFailure(
        code: ErrorCode.invalidLocation,
      );
    }

    if (regionId == null || regionId.isEmpty) {
      return const DataFailure(
        code: ErrorCode.invalidLocation,
      );
    }

    if (cityId == null || cityId.isEmpty) {
      return const DataFailure(
        code: ErrorCode.invalidLocation,
      );
    }

    return null;
  }

  /// Valida la consistencia de la jerarquía de ubicación
  ///
  ///  Propósito:  Verificar que la región pertenezca al país y que la ciudad pertenezca a la región
  ///
  ///  Validaciones: 
  /// - El país existe en la lista de países
  /// - La región existe y pertenece al país especificado
  /// - La ciudad existe y pertenece a la región especificada
  ///
  ///  ⚠️ NOTA: Esta es una validación local para UX. 
  /// - El backend debe validar la consistencia de forma definitiva
  /// - Previene manipulación maliciosa (alguien podría enviar IDs inconsistentes directamente al backend)
  ///
  ///  Uso:  UX validation cuando usuario selecciona ubicación
  ///
  ///  Ejemplo: 
  /// ```dart
  /// final error = GossipValidator.validateLocationHierarchy(
  ///   countryId: 'AR',
  ///   regionId: 'CBA',
  ///   cityId: 'Cordoba',
  ///   countries: countriesList,
  ///   regions: regionsList,
  ///   cities: citiesList,
  /// );
  /// ```
  static DataFailure? validateLocationHierarchy({
    required String countryId,
    required String regionId,
    required String cityId,
    required List<Country> countries,
    required List<Region> regions,
    required List<City> cities,
  }) {
    // Verificar que el país existe
    final country = countries.where((c) => c.id == countryId).firstOrNull;
    if (country == null) {
      return const DataFailure(
        code: ErrorCode.invalidLocation,
      );
    }

    // Verificar que la región existe y pertenece al país
    final region = regions.where((r) => r.id == regionId).firstOrNull;
    if (region == null || region.countryId != countryId) {
      return const DataFailure(
        code: ErrorCode.invalidLocation,
      );
    }

    // Verificar que la ciudad existe y pertenece a la región
    final city = cities.where((c) => c.id == cityId).firstOrNull;
    if (city == null || city.regionId != regionId) {
      return const DataFailure(
        code: ErrorCode.invalidLocation,
      );
    }

    return null;
  }

  /// Valida la combinación de status y moderationStatus
  ///
  ///  Propósito:  Verificar que la combinación de estados es válida según las reglas de negocio
  ///
  ///  Decisión de diseño: 
  /// - Usa GossipStateMachine para validar combinaciones
  /// - Previene combinaciones ambiguas que rompan el flujo de negocio
  /// - Solo 6 combinaciones son válidas de 16 posibles (4 x 4)
  ///
  ///  Uso: 
  /// - Domain Layer: Validar consistencia de datos
  /// - Backend: Cloud Functions antes de escribir a Firestore
  /// - Tests: Verificar que el modelo de negocio es consistente
  ///
  ///  Combinaciones válidas: 
  /// | GossipStatus | ModerationStatus | Significado |
  /// |--------------|------------------|-------------|
  /// | `draft` | `pending` | Creado, motor revisando |
  /// | `draft` | `rejected` | Motor detectó problema, corregir |
  /// | `published` | `approved` | Publicado y aprobado |
  /// | `hidden` | `flagged` | Reportado, oculto para corrección |
  /// | `hidden` | `rejected` | Rechazado por moderación |
  /// | `deleted` | `cualquiera` | Eliminado (soft delete) |
  ///
  ///  Ejemplo: 
  /// ```dart
  /// final error = GossipValidator.validateStatusCombination(
  ///   gossipStatus: GossipStatus.published,
  ///   moderationStatus: ModerationStatus.approved,
  /// ); // null (válida)
  ///
  /// final error2 = GossipValidator.validateStatusCombination(
  ///   gossipStatus: GossipStatus.published,
  ///   moderationStatus: ModerationStatus.rejected,
  /// ); // ValidationFailure (inválida)
  /// ```
  static ValidationFailure? validateStatusCombination({
    required GossipStatus gossipStatus,
    required ModerationStatus moderationStatus,
  }) {
    if (!GossipStateMachine.isValidCombination(gossipStatus, moderationStatus)) {
      return ValidationFailure(
        code: ErrorCode.invalidInput,
        fieldErrors: {
          'status': 'Invalid combination: $gossipStatus + $moderationStatus',
        },
      );
    }

    return null;
  }
}
