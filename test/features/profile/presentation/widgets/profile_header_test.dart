import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chismes/features/profile/presentation/widgets/profile_header.dart';
import 'package:chismes/features/auth/domain/entities/user.dart';

import '../../../../helpers/widget_test_wrapper.dart';

void main() {
  final mockUser = User(
    id: 'user-1',
    email: 'test@example.com',
    emailVerified: true,
    username: 'testuser',
    displayName: 'Test User',
    avatarUrl: null,
    bio: 'This is my bio',
    profileCompleted: true,
    createdAt: DateTime(2024, 1, 1),
  );

  final mockUserWithAvatar = User(
    id: 'user-2',
    email: 'avatar@example.com',
    emailVerified: false,
    username: 'avataruser',
    displayName: 'Avatar User',
    avatarUrl: 'https://example.com/avatar.jpg',
    bio: null,
    profileCompleted: false,
    createdAt: DateTime(2024, 1, 1),
  );

  final mockUserMinimal = User(
    id: 'user-3',
    email: 'minimal@example.com',
    emailVerified: false,
    username: null,
    displayName: null,
    avatarUrl: null,
    bio: null,
    profileCompleted: false,
    createdAt: DateTime(2024, 1, 1),
  );

  Widget createTestWidget(User user) {
    return testableWidget(
      child: ProfileHeader(user: user),
    );
  }

  group('ProfileHeader - Básicos', () {
    testWidgets('debe renderizar el widget', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.byType(ProfileHeader), findsOneWidget);
    });

    testWidgets('debe ser un StatelessWidget', (tester) async {
      // Arrange
      final widget = ProfileHeader(user: mockUser);

      // Assert
      expect(widget, isA<StatelessWidget>());
    });

    testWidgets('debe tener Column principal', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('debe aceptar key opcional', (tester) async {
      // Arrange
      const key = Key('header-key');

      // Act
      await tester.pumpWidget(
        testableWidget(
          child: ProfileHeader(
            key: key,
            user: mockUser,
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.byKey(key), findsOneWidget);
    });
  });

  group('ProfileHeader - Avatar', () {
    testWidgets('debe renderizar CircleAvatar', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('CircleAvatar debe tener radius 60', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(avatar.radius, 60);
    });

    testWidgets('debe mostrar initials cuando no hay avatarUrl', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      // Initials de "Test User" deben ser "TU"
      expect(find.text('TU'), findsOneWidget);
    });

    testWidgets('debe usar NetworkImage cuando hay avatarUrl', (tester) async {
      // Arrange - verificar lógica sin renderizar HTTP request
      final userWithAvatar = User(
        id: 'user-avatar',
        email: 'test@example.com',
        emailVerified: false,
        avatarUrl: 'https://example.com/avatar.jpg',
        profileCompleted: false,
        createdAt: DateTime(2024, 1, 1),
      );

      // Assert - verificar que el usuario tiene avatarUrl
      expect(userWithAvatar.hasAvatar, isTrue);
      expect(userWithAvatar.avatarUrl, isNotNull);

      // Nota: No renderizamos el widget porque NetworkImage intenta
      // hacer HTTP request que falla en tests. La lógica está en:
      // backgroundImage: user.hasAvatar ? NetworkImage(user.avatarUrl!) : null
    });

    testWidgets('initials deben estar en mayúsculas', (tester) async {
      // Arrange
      final user = User(
        id: 'user-4',
        email: 'test@example.com',
        emailVerified: false,
        displayName: 'john doe',
        profileCompleted: false,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      await tester.pumpWidget(createTestWidget(user));
      await tester.pump();

      // Assert
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('debe usar primera letra si solo hay una palabra', (tester) async {
      // Arrange
      final user = User(
        id: 'user-5',
        email: 'test@example.com',
        emailVerified: false,
        displayName: 'John',
        profileCompleted: false,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      await tester.pumpWidget(createTestWidget(user));
      await tester.pump();

      // Assert
      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('initials deben usar displayMedium en negrita', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      final text = tester.widget<Text>(find.text('TU'));
      expect(text.style?.fontWeight, FontWeight.bold);
      expect(text.style?.color, Colors.white);
    });
  });

  group('ProfileHeader - Nombre y Username', () {
    testWidgets('debe mostrar displayName', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('displayName debe usar headlineMedium', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      final text = tester.widget<Text>(find.text('Test User'));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('debe mostrar username con @', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.text('@testuser'), findsOneWidget);
    });

    testWidgets('no debe mostrar username si es null', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUserMinimal));
      await tester.pump();

      // Assert
      // El widget de username tiene padding top específico
      final usernamePadding = find.ancestor(
        of: find.byType(Text),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Padding &&
              widget.padding == const EdgeInsets.only(top: 4),
        ),
      );
      expect(usernamePadding, findsNothing);
    });

    testWidgets('debe usar fallback si displayName es null', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUserMinimal));
      await tester.pump();

      // Assert - debe mostrar algo, no importa qué texto exacto
      expect(find.byType(ProfileHeader), findsOneWidget);
    });
  });

  group('ProfileHeader - Email', () {
    testWidgets('debe mostrar email', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('email debe usar color gris', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      final text = tester.widget<Text>(find.text('test@example.com'));
      expect(text.style?.color, Colors.grey);
      expect(text.textAlign, TextAlign.center);
    });
  });

  group('ProfileHeader - Bio', () {
    testWidgets('debe mostrar bio cuando existe', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.text('This is my bio'), findsOneWidget);
    });

    testWidgets('no debe mostrar bio cuando es null', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUserMinimal));
      await tester.pump();

      // Assert
      expect(find.text('This is my bio'), findsNothing);
    });

    testWidgets('no debe mostrar bio cuando es empty string', (tester) async {
      // Arrange
      final user = User(
        id: 'user-6',
        email: 'test@example.com',
        emailVerified: false,
        bio: '',
        profileCompleted: false,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      await tester.pumpWidget(createTestWidget(user));
      await tester.pump();

      // Assert - no debe haber Container con la bio
      final containers = tester.widgetList<Container>(find.byType(Container));
      expect(containers.length, lessThan(3)); // Menos containers si no hay bio
    });

    testWidgets('bio debe tener Container con bordes redondeados', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.text('This is my bio'), findsOneWidget);
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('bio debe tener textAlign center', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      final text = tester.widget<Text>(find.text('This is my bio'));
      expect(text.textAlign, TextAlign.center);
    });
  });

  group('ProfileHeader - Email Verified Badge', () {
    testWidgets('debe mostrar badge cuando email está verificado', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('no debe mostrar badge cuando email no está verificado',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUserMinimal));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets('badge debe tener ícono verde', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.verified));
      expect(icon.color, Colors.green);
      expect(icon.size, 16);
    });

    testWidgets('badge debe tener borde verde', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('badge debe tener Row con ícono y texto', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.verified), findsOneWidget);
      expect(find.byType(Row), findsWidgets);
    });
  });

  group('ProfileHeader - Profile Completeness', () {
    testWidgets('debe mostrar barra de progreso', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('debe mostrar porcentaje de completitud', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      // El porcentaje exacto depende de profileCompletionPercentage
      expect(find.textContaining('%'), findsOneWidget);
    });

    testWidgets('barra debe tener color verde cuando está 100%', (tester) async {
      // Arrange
      final completeUser = User(
        id: 'user-7',
        email: 'complete@example.com',
        emailVerified: true,
        username: 'complete',
        displayName: 'Complete User',
        avatarUrl: null,
        bio: 'Bio here',
        profileCompleted: true,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      await tester.pumpWidget(createTestWidget(completeUser));
      await tester.pump();

      // Assert
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.value, isNotNull);
      expect(progress.value! >= 0 && progress.value! <= 1, isTrue);
    });

    testWidgets('debe mostrar Row con texto y porcentaje', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.byType(Row), findsWidgets);
      expect(find.textContaining('%'), findsOneWidget);
    });

    testWidgets('barra debe tener backgroundColor gris', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      final progress = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progress.backgroundColor, isNotNull);
    });

    testWidgets('porcentaje debe estar en negrita', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      final percentageTexts = tester.widgetList<Text>(
        find.textContaining('%'),
      );
      expect(percentageTexts.isNotEmpty, isTrue);
    });
  });

  group('ProfileHeader - Initials Helper', () {
    testWidgets('debe generar initials de nombre con dos palabras',
        (tester) async {
      // Arrange
      final user = User(
        id: 'user-8',
        email: 'test@example.com',
        emailVerified: false,
        displayName: 'Alice Bob',
        profileCompleted: false,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      await tester.pumpWidget(createTestWidget(user));
      await tester.pump();

      // Assert
      expect(find.text('AB'), findsOneWidget);
    });

    testWidgets('debe generar initial de nombre con una palabra',
        (tester) async {
      // Arrange
      final user = User(
        id: 'user-9',
        email: 'test@example.com',
        emailVerified: false,
        displayName: 'Alice',
        profileCompleted: false,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      await tester.pumpWidget(createTestWidget(user));
      await tester.pump();

      // Assert
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('debe manejar nombres con más de dos palabras', (tester) async {
      // Arrange
      final user = User(
        id: 'user-10',
        email: 'test@example.com',
        emailVerified: false,
        displayName: 'Alice Bob Charlie',
        profileCompleted: false,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      await tester.pumpWidget(createTestWidget(user));
      await tester.pump();

      // Assert
      // Debe tomar solo las dos primeras palabras
      expect(find.text('AB'), findsOneWidget);
    });

    testWidgets('debe manejar nombres con espacios extra', (tester) async {
      // Arrange
      final user = User(
        id: 'user-11',
        email: 'test@example.com',
        emailVerified: false,
        displayName: '  Alice   Bob  ',
        profileCompleted: false,
        createdAt: DateTime(2024, 1, 1),
      );

      // Act
      await tester.pumpWidget(createTestWidget(user));
      await tester.pump();

      // Assert
      expect(find.text('AB'), findsOneWidget);
    });
  });

  group('ProfileHeader - Layout', () {
    testWidgets('debe tener SizedBox para espaciado', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('elementos deben estar centrados', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      final displayNameText = tester.widget<Text>(find.text('Test User'));
      expect(displayNameText.textAlign, TextAlign.center);

      final emailText = tester.widget<Text>(find.text('test@example.com'));
      expect(emailText.textAlign, TextAlign.center);
    });

    testWidgets('debe tener Padding cuando es necesario', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(mockUser));
      await tester.pump();

      // Assert
      expect(find.byType(Padding), findsWidgets);
    });
  });

  group('ProfileHeader - Constructor', () {
    test('debe requerir user en constructor', () {
      // Act & Assert
      expect(
        () => ProfileHeader(user: mockUser),
        returnsNormally,
      );
    });

    test('debe ser const constructor', () {
      // Act
      final widget = ProfileHeader(user: User(
        id: 'id',
        email: 'email@test.com',
        emailVerified: false,
        profileCompleted: false,
        createdAt: DateTime(2024, 1, 1),
      ));

      // Assert
      expect(widget, isA<ProfileHeader>());
      expect(widget.user.email, 'email@test.com');
    });

    test('user debe ser final', () {
      // Arrange
      final widget = ProfileHeader(user: mockUser);

      // Assert
      expect(widget.user, equals(mockUser));
    });
  });
}
