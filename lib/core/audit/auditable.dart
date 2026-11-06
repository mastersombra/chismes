/// Interfaz para entidades que requieren auditoría
/// Las entidades que implementen esta interfaz tendrán
/// automáticamente campos de created_at, created_by, modified_at, modified_by
abstract class Auditable {
  DateTime get createdAt;
  String get createdBy;
  DateTime? get modifiedAt;
  String? get modifiedBy;
}
