/// Datos sociales del usuario que necesitan otros features (p. ej. el tab
/// Siguiendo del Home, para saber si sigue a alguien).
///
/// La implementa el feature social con `get_user_profile`
/// (`@Singleton(as: ProfileService)`), así home no depende de social.
abstract class ProfileService {
  /// Cuántos usuarios sigue [userId].
  ///
  /// Lanza el [Failure] si el servidor no respondió: quien llama decide
  /// (el tab Siguiendo muestra el estado de error con reintentar).
  Future<int> getFollowingCount(String userId);
}
