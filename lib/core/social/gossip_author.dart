import 'package:equatable/equatable.dart';

/// Autor visible de un chisme publicado con perfil.
///
/// Solo existe en chismes `published_as = 'profile'`: el servidor
/// (`public_gossips`, migración 018) manda `author_*` en NULL para los
/// anónimos, incluso los propios. Un chisme anónimo NUNCA debe tener autor.
///
/// Vive en core porque lo comparten Gossip (gossip) y FeedGossip (home).
class GossipAuthor extends Equatable {
  /// ID del usuario (el `created_by` del chisme): abre su perfil
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  const GossipAuthor({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  /// Autor del chisme, o null si no se debe mostrar ninguno.
  ///
  /// null cuando: el chisme no es con perfil, el servidor ocultó el autor
  /// (`createdBy` null) o no hay ni @usuario ni nombre que mostrar.
  static GossipAuthor? maybe({
    required String publishedAs,
    required String? createdBy,
    required String? username,
    required String? displayName,
    required String? avatarUrl,
  }) {
    if (publishedAs != 'profile' || createdBy == null) return null;
    if (_isBlank(username) && _isBlank(displayName)) return null;
    return GossipAuthor(
      userId: createdBy,
      username: _isBlank(username) ? null : username,
      displayName: _isBlank(displayName) ? null : displayName,
      avatarUrl: _isBlank(avatarUrl) ? null : avatarUrl,
    );
  }

  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;

  /// Nombre a mostrar: nombre visible o, si no hay, @usuario
  String get displayLabel => displayName ?? '@$username';

  /// `@usuario` o null si no tiene
  String? get handle => username != null ? '@$username' : null;

  bool get hasAvatar => avatarUrl != null;

  @override
  List<Object?> get props => [userId, username, displayName, avatarUrl];
}
