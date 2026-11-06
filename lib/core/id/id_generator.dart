/// Generador de IDs abstracto
/// Define el contrato para cualquier implementación de generación de IDs
/// 
/// Implementaciones:
/// - TimestampIdGenerator (mock/desarrollo)
/// - UuidGenerator (UUID v4)
/// - SupabaseIdGenerator (usando PostgreSQL UUID)
/// - CustomIdGenerator (otras implementaciones)
abstract class IdGenerator {
  /// Genera un nuevo ID único
  String generate();
}
