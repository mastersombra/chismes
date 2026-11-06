import 'auditable.dart';
import '../auth/auth_repository.dart';

/// Servicio para manejar auditoría de entidades
/// Agrega automáticamente timestamps y usuario al crear o actualizar
///
/// ⚠️ ADVERTENCIA DE SEGURIDAD ⚠️
/// 
/// Esta implementación es para DESARROLLO/MOCKS solamente.
/// 
/// En PRODUCCIÓN, los campos de auditoría deben ser manejados por el SERVIDOR:
/// 
/// - createdBy: Debe ser el UID del usuario autenticado (del servidor, no del cliente)
/// - createdAt: Debe ser un server timestamp (del servidor, no del cliente)
/// - modifiedBy: Debe ser el UID del usuario autenticado (del servidor)
/// - modifiedAt: Debe ser un server timestamp (del servidor)
/// 
/// Por qué:
/// - Un cliente malintencionado puede modificar DateTime.now() a cualquier valor
/// - Un cliente puede falsificar el currentUser
/// - El servidor es la única fuente de verdad para auditoría de seguridad
///
/// Ejemplo con Supabase:
/// - createdBy = auth.uid() (validado en RLS policies)
/// - createdAt = NOW() (server timestamp en PostgreSQL)
/// - modifiedBy = auth.uid() (validado en RLS policies)
/// - modifiedAt = NOW() (server timestamp en PostgreSQL)
class AuditService {
  final AuthRepository authRepository;

  AuditService({required this.authRepository});

  /// Obtiene el ID del usuario actual
  /// 
  /// ⚠️ IMPORTANTE: createdBy debe ser el UID real del usuario, nunca "anonymous".
  /// Si no hay usuario autenticado, esto debería fallar o no permitir la operación.
  /// 
  /// - createdBy = UID del usuario (para moderación, reportes, abuso)
  /// - publishedAs = anonymous (para ocultar identidad públicamente)
  String get _currentUserId {
    final userId = authRepository.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Usuario no autenticado. createdBy requiere un UID real.');
    }
    return userId;
  }

  /// Prepara una entidad para ser creada (implementación para desarrollo)
  /// Agrega created_at y created_by automáticamente
  /// 
  /// ⚠️ En producción, estos campos deben ser establecidos por el servidor
  Map<String, dynamic> prepareForCreate(Map<String, dynamic> data) {
    final now = DateTime.now().toIso8601String();
    
    return {
      ...data,
      'createdAt': now,
      'createdBy': _currentUserId,
      'modifiedAt': null,
      'modifiedBy': null,
    };
  }

  /// Prepara una entidad para ser actualizada (implementación para desarrollo)
  /// Agrega modified_at y modified_by automáticamente
  /// 
  /// ⚠️ En producción, estos campos deben ser establecidos por el servidor
  Map<String, dynamic> prepareForUpdate(Map<String, dynamic> data) {
    final now = DateTime.now().toIso8601String();
    
    return {
      ...data,
      'modifiedAt': now,
      'modifiedBy': _currentUserId,
    };
  }

  /// Valida si una entidad tiene campos de auditoría válidos
  bool isValidAudit(Auditable entity) {
    if (entity.createdBy.isEmpty) return false;
    
    // Si tiene modified_at, debe tener modified_by
    if (entity.modifiedAt != null && entity.modifiedBy == null) {
      return false;
    }
    
    // Si tiene modified_by, debe tener modified_at
    if (entity.modifiedBy != null && entity.modifiedAt == null) {
      return false;
    }
    
    return true;
  }

  /// Obtiene información de auditoría para logging
  String getAuditInfo(Auditable entity) {
    return 'Created by ${entity.createdBy} at ${entity.createdAt.toIso8601String()}'
        '${entity.modifiedBy != null ? ", modified by ${entity.modifiedBy} at ${entity.modifiedAt?.toIso8601String()}" : ""}';
  }
}
