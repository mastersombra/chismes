import '../models/gossip_model.dart';

/// Fuente de datos local para Gossip
/// Implementaciones: SQLite, Hive, SharedPreferences, Mock, etc.
abstract class GossipLocalDataSource {
  /// Obtiene todos los gossips desde el almacenamiento local
  Future<List<GossipModel>> getAll();

  /// Guarda un gossip en el almacenamiento local
  Future<void> save(GossipModel gossip);

  /// Guarda una lista de gossips en el almacenamiento local
  Future<void> saveAll(List<GossipModel> gossips);

  /// Limpia todos los gossips del almacenamiento local
  Future<void> clear();
}
