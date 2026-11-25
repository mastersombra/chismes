import '../../domain/entities/social_page.dart';

/// Página paginada por cursor de los RPC sociales:
/// `{data: [...], has_more, next_cursor: {created_at, id} | null}`
///
/// [T] es el modelo de cada item (lo arma [itemFromJson]).
class SocialPageModel<T> {
  final List<T> data;
  final bool hasMore;
  final String? nextCursorCreatedAt;
  final String? nextCursorId;

  const SocialPageModel({
    required this.data,
    required this.hasMore,
    this.nextCursorCreatedAt,
    this.nextCursorId,
  });

  /// [json] null (RPC sin respuesta) → página vacía.
  /// Lanza [FormatException] si el JSON no tiene la forma esperada.
  factory SocialPageModel.fromJson(
    Map<String, dynamic>? json,
    T Function(Map<String, dynamic> item) itemFromJson,
  ) {
    if (json == null) {
      return const SocialPageModel(data: [], hasMore: false);
    }
    try {
      final items = (json['data'] as List<dynamic>? ?? const [])
          .map((item) => itemFromJson(item as Map<String, dynamic>))
          .toList();
      final cursor = json['next_cursor'] as Map<String, dynamic>?;
      return SocialPageModel(
        data: items,
        hasMore: json['has_more'] as bool? ?? false,
        nextCursorCreatedAt: cursor?['created_at'] as String?,
        nextCursorId: cursor?['id'] as String?,
      );
    } on FormatException {
      rethrow;
    } catch (e) {
      throw FormatException('Error deserializando SocialPageModel: $e');
    }
  }

  /// Convierte a entidad con [toEntity] para cada item. Sin cursor válido no
  /// hay más páginas (evita pedir la misma página en bucle).
  SocialPage<E> toEntity<E>(E Function(T item) toEntity) {
    final cursor = nextCursorCreatedAt != null && nextCursorId != null
        ? SocialCursor(
            createdAt: DateTime.parse(nextCursorCreatedAt!),
            id: nextCursorId!,
          )
        : null;
    return SocialPage<E>(
      items: data.map(toEntity).toList(),
      hasMore: hasMore && cursor != null,
      nextCursor: cursor,
    );
  }
}
