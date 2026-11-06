import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/services/mvp_content_moderator.dart';

/// Módulo de dependencias para el feature de Gossip
///
/// Este módulo maneja el registro de dependencias que requieren
/// configuración especial o que no pueden ser registradas automáticamente.
@module
abstract class GossipModule {
  /// Registra MvpModerationPolicy con su configuración por defecto
  ///
  /// Se usa @singleton para que solo exista una instancia durante
  /// toda la vida de la aplicación.
  @singleton
  MvpModerationPolicy get moderationPolicy => const MvpModerationPolicy();

  /// Cliente de Supabase global
  @lazySingleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}
