import 'package:injectable/injectable.dart';
import 'id_generator.dart';

/// Implementación de IdGenerator que usa timestamps
/// 
/// ⚠️ ADVERTENCIA: Solo usar para DESARROLLO y MOCKS
/// 
/// NO utilizar en producción con millones de usuarios porque:
/// - Dos clientes pueden generar IDs en momentos extremadamente cercanos (colisiones)
/// - El ID tiene relación con la hora (no es ideal para identificación)
/// 
/// Para producción usar:
/// - PostgreSQL UUID (gen_random_uuid() en Supabase)
/// - Identificador generado por backend
/// - UUID v4 (si se necesita generación en cliente)
@Singleton(as: IdGenerator)
class TimestampIdGenerator implements IdGenerator {
  @override
  String generate() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
