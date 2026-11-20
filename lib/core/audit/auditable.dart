/// Interfaz para entidades que requieren auditoría
/// Las entidades que implementen esta interfaz tendrán
/// automáticamente campos de created_at, created_by, modified_at, modified_by
abstract class Auditable {
  DateTime get createdAt;
  /// `null` si el servidor oculta al autor (p. ej. chisme anónimo ajeno).
  String? get createdBy;
  DateTime? get modifiedAt;
  String? get modifiedBy;
}
