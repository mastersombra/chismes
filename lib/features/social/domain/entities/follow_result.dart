/// Resultado de `follow_user`
enum FollowResult {
  /// Ya lo sigo (cuenta pública, o ya lo seguía)
  following,

  /// Se creó una solicitud (cuenta privada): el dueño la acepta o rechaza
  requested,
}
