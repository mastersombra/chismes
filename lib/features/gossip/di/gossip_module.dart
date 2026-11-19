import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Módulo de dependencias para el feature de Gossip
///
/// Este módulo maneja el registro de dependencias que requieren
/// configuración especial o que no pueden ser registradas automáticamente.
///
/// La moderación de contenido NO vive en la app: la hace la Edge Function
/// `moderate-gossip` (reglas + OpenAI). Ver docs/moderation_mvp.md.
@module
abstract class GossipModule {
  /// Cliente de Supabase global
  @lazySingleton
  SupabaseClient get supabaseClient => Supabase.instance.client;
}
