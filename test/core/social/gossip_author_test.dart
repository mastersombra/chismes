import 'package:chismes/core/social/gossip_author.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GossipAuthor.maybe', () {
    test('arma el autor de un chisme con perfil', () {
      final author = GossipAuthor.maybe(
        publishedAs: 'profile',
        createdBy: 'u1',
        username: 'ana',
        displayName: 'Ana',
        avatarUrl: 'https://x/a.jpg',
      );

      expect(
        author,
        const GossipAuthor(
          userId: 'u1',
          username: 'ana',
          displayName: 'Ana',
          avatarUrl: 'https://x/a.jpg',
        ),
      );
    });

    test('chisme anónimo: nunca hay autor aunque lleguen datos', () {
      final author = GossipAuthor.maybe(
        publishedAs: 'anonymous',
        createdBy: 'u1',
        username: 'ana',
        displayName: 'Ana',
        avatarUrl: null,
      );

      expect(author, isNull);
    });

    test('sin created_by (autor oculto por el servidor) no hay autor', () {
      final author = GossipAuthor.maybe(
        publishedAs: 'profile',
        createdBy: null,
        username: 'ana',
        displayName: 'Ana',
        avatarUrl: null,
      );

      expect(author, isNull);
    });

    test('sin @usuario ni nombre no hay nada que mostrar', () {
      final author = GossipAuthor.maybe(
        publishedAs: 'profile',
        createdBy: 'u1',
        username: null,
        displayName: '  ',
        avatarUrl: null,
      );

      expect(author, isNull);
    });

    test('normaliza strings vacíos a null', () {
      final author = GossipAuthor.maybe(
        publishedAs: 'profile',
        createdBy: 'u1',
        username: 'ana',
        displayName: '',
        avatarUrl: '',
      )!;

      expect(author.displayName, isNull);
      expect(author.avatarUrl, isNull);
      expect(author.hasAvatar, isFalse);
    });
  });

  group('etiquetas', () {
    test('displayLabel usa el nombre y si no hay, @usuario', () {
      expect(
        const GossipAuthor(userId: 'u1', username: 'ana', displayName: 'Ana').displayLabel,
        'Ana',
      );
      expect(const GossipAuthor(userId: 'u1', username: 'ana').displayLabel, '@ana');
    });

    test('handle es @usuario o null', () {
      expect(const GossipAuthor(userId: 'u1', username: 'ana').handle, '@ana');
      expect(const GossipAuthor(userId: 'u1', displayName: 'Ana').handle, isNull);
    });
  });
}
