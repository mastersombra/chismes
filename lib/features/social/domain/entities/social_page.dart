import 'package:equatable/equatable.dart';

/// Cursor de las listas sociales: (created_at, id) del último elemento
class SocialCursor extends Equatable {
  final DateTime createdAt;
  final String id;

  const SocialCursor({required this.createdAt, required this.id});

  @override
  List<Object?> get props => [createdAt, id];
}

/// Página de una lista paginada por cursor (seguidores, seguidos, chismes
/// de un usuario)
class SocialPage<T> extends Equatable {
  final List<T> items;
  final bool hasMore;

  /// Cursor para pedir la siguiente página (null si no hay más)
  final SocialCursor? nextCursor;

  const SocialPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  const SocialPage.empty()
      : items = const [],
        hasMore = false,
        nextCursor = null;

  @override
  List<Object?> get props => [items, hasMore, nextCursor];
}
