# Common Workflows - Chismes App

> **Workflows y comandos comunes.** Guía paso a paso para tareas frecuentes.

**Última actualización:** 2026-10-20

---

## 📋 Índice

1. [Agregar un Nuevo Feature](#agregar-un-nuevo-feature)
2. [Agregar Migración de Base de Datos](#agregar-migración-de-base-de-datos)
3. [Agregar Logging](#agregar-logging)
4. [Testing Workflow](#testing-workflow)
5. [Deployment](#deployment)
6. [Comandos Útiles](#comandos-útiles)

---

## Agregar un Nuevo Feature

### Paso 1: Crear Estructura de Directorios

```bash
# Ejemplo: Feature "comments"
mkdir -p lib/features/comments/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{controllers,screens,widgets}}

# Estructura resultante:
lib/features/comments/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── controllers/
    ├── screens/
    └── widgets/
```

### Paso 2: Crear Tests Paralelos

```bash
mkdir -p test/features/comments/{data/{datasources,models,repositories},domain/{entities,usecases},presentation/controllers}
```

### Paso 3: Domain Layer (Primero)

```dart
// 1. Entity
// lib/features/comments/domain/entities/comment.dart
import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String gossipId;
  final String userId;
  final String text;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.gossipId,
    required this.userId,
    required this.text,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, gossipId, userId, text, createdAt];
}

// 2. Repository Interface
// lib/features/comments/domain/repositories/comment_repository.dart
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/comment.dart';

abstract class CommentRepository {
  Future<Result<Failure, List<Comment>>> getComments(String gossipId);
  Future<Result<Failure, Comment>> create(String gossipId, String text);
  Future<Result<Failure, void>> delete(String commentId);
}

// 3. Use Case
// lib/features/comments/domain/usecases/create_comment.dart
import 'package:injectable/injectable.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../entities/comment.dart';
import '../repositories/comment_repository.dart';

@injectable
class CreateComment {
  final CommentRepository _repository;

  CreateComment(this._repository);

  Future<Result<Failure, Comment>> call(String gossipId, String text) {
    return _repository.create(gossipId, text);
  }
}
```

### Paso 4: Data Layer

```dart
// 1. Model (DTO)
// lib/features/comments/data/models/comment_model.dart
import '../../domain/entities/comment.dart';

class CommentModel {
  final String id;
  final String gossip_id;  // snake_case (DB)
  final String user_id;
  final String text;
  final String created_at;  // ISO8601 string (DB)

  CommentModel({
    required this.id,
    required this.gossip_id,
    required this.user_id,
    required this.text,
    required this.created_at,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] as String,
      gossip_id: json['gossip_id'] as String,
      user_id: json['user_id'] as String,
      text: json['text'] as String,
      created_at: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gossip_id': gossip_id,
      'user_id': user_id,
      'text': text,
      'created_at': created_at,
    };
  }

  Comment toEntity() {
    return Comment(
      id: id,
      gossipId: gossip_id,
      userId: user_id,
      text: text,
      createdAt: DateTime.parse(created_at),
    );
  }
}

// 2. Data Source Interface
// lib/features/comments/data/datasources/comment_remote_data_source.dart
import '../models/comment_model.dart';

abstract class CommentRemoteDataSource {
  Future<List<CommentModel>> getComments(String gossipId);
  Future<CommentModel> create(String gossipId, String text);
  Future<void> delete(String commentId);
}

// 3. Data Source Implementation
// lib/features/comments/data/datasources/supabase_comment_remote_data_source.dart
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/logging/app_logger.dart';
import 'comment_remote_data_source.dart';
import '../models/comment_model.dart';

@Singleton(as: CommentRemoteDataSource)
class SupabaseCommentRemoteDataSource implements CommentRemoteDataSource {
  final SupabaseClient _client;
  final AppLogger _logger;

  SupabaseCommentRemoteDataSource(this._client, this._logger);

  @override
  Future<List<CommentModel>> getComments(String gossipId) async {
    try {
      final response = await _client
          .from('comments')
          .select()
          .eq('gossip_id', gossipId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CommentModel.fromJson(json))
          .toList();
    } catch (error) {
      _logger.e('Failed to fetch comments', error: error);
      rethrow;
    }
  }

  @override
  Future<CommentModel> create(String gossipId, String text) async {
    try {
      final response = await _client
          .from('comments')
          .insert({
            'gossip_id': gossipId,
            'text': text,
          })
          .select()
          .single();

      return CommentModel.fromJson(response);
    } catch (error) {
      _logger.e('Failed to create comment', error: error);
      rethrow;
    }
  }

  @override
  Future<void> delete(String commentId) async {
    try {
      await _client.from('comments').delete().eq('id', commentId);
    } catch (error) {
      _logger.e('Failed to delete comment', error: error);
      rethrow;
    }
  }
}

// 4. Repository Implementation
// lib/features/comments/data/repositories/comment_repository_impl.dart
import 'package:injectable/injectable.dart';
import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/comment_remote_data_source.dart';

@Singleton(as: CommentRepository)
class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource _remoteDataSource;
  final AppLogger _logger;

  CommentRepositoryImpl(this._remoteDataSource, this._logger);

  @override
  Future<Result<Failure, List<Comment>>> getComments(String gossipId) async {
    try {
      final models = await _remoteDataSource.getComments(gossipId);
      final entities = models.map((m) => m.toEntity()).toList();
      return Result.success(entities);
    } catch (error, stackTrace) {
      _logger.e('Repository: get comments failed', 
        error: error, 
        stackTrace: stackTrace,
      );
      return Result.failure(ErrorHandler.handleError(error));
    }
  }

  @override
  Future<Result<Failure, Comment>> create(String gossipId, String text) async {
    try {
      final model = await _remoteDataSource.create(gossipId, text);
      return Result.success(model.toEntity());
    } catch (error, stackTrace) {
      _logger.e('Repository: create comment failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Result.failure(ErrorHandler.handleError(error));
    }
  }

  @override
  Future<Result<Failure, void>> delete(String commentId) async {
    try {
      await _remoteDataSource.delete(commentId);
      return Result.success(null);
    } catch (error, stackTrace) {
      _logger.e('Repository: delete comment failed',
        error: error,
        stackTrace: stackTrace,
      );
      return Result.failure(ErrorHandler.handleError(error));
    }
  }
}
```

### Paso 5: Presentation Layer

```dart
// 1. State
// lib/features/comments/presentation/states/comments_state.dart
import 'package:equatable/equatable.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/comment.dart';

class CommentsState extends Equatable {
  final bool isLoading;
  final List<Comment> comments;
  final Failure? failure;

  const CommentsState({
    this.isLoading = false,
    this.comments = const [],
    this.failure,
  });

  factory CommentsState.initial() => const CommentsState();

  CommentsState copyWith({
    bool? isLoading,
    List<Comment>? comments,
    Failure? failure,
  }) {
    return CommentsState(
      isLoading: isLoading ?? this.isLoading,
      comments: comments ?? this.comments,
      failure: failure ?? this.failure,
    );
  }

  @override
  List<Object?> get props => [isLoading, comments, failure];
}

// 2. Controller
// lib/features/comments/presentation/controllers/comments_controller.dart
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/logging/app_logger.dart';
import '../../domain/usecases/create_comment.dart';
import '../states/comments_state.dart';

@injectable
class CommentsController extends ChangeNotifier {
  final CreateComment _createComment;
  final AppLogger _logger;

  CommentsController(this._createComment, this._logger);

  CommentsState _state = CommentsState.initial();
  CommentsState get state => _state;

  void _setState(CommentsState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> createComment(String gossipId, String text) async {
    _setState(state.copyWith(isLoading: true, failure: null));

    final result = await _createComment(gossipId, text);

    result.fold(
      onFailure: (failure) {
        _setState(state.copyWith(isLoading: false, failure: failure));
        _logger.e('Create comment failed', context: {'message': failure.message});
      },
      onSuccess: (comment) {
        final updatedComments = [comment, ...state.comments];
        _setState(state.copyWith(
          isLoading: false,
          comments: updatedComments,
        ));
        _logger.i('Comment created', context: {'id': comment.id});
      },
    );
  }
}
```

### Paso 6: Regenerar DI

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Paso 7: Escribir Tests

```bash
# Ver TESTING.md para ejemplos
flutter test test/features/comments/
```

---

## Agregar Migración de Base de Datos

### Paso 1: Crear Archivo de Migración

```bash
# Número secuencial siguiente
# Estructura: {number}_{descriptive_name}.sql

# Ejemplo:
touch supabase/migrations/005_create_comments_table.sql
```

### Paso 2: Escribir SQL

```sql
-- 005_create_comments_table.sql

-- Descripción: Tabla de comentarios en chismes
-- Autor: Alejo
-- Fecha: 2026-10-20

-- Tabla principal
CREATE TABLE IF NOT EXISTS comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  gossip_id UUID NOT NULL REFERENCES gossips(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  text TEXT NOT NULL CHECK (char_length(text) <= 500),
  
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  modified_at TIMESTAMPTZ,
  
  CONSTRAINT fk_gossip FOREIGN KEY (gossip_id) REFERENCES gossips(id),
  CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_comments_gossip_id ON comments(gossip_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at DESC);

-- Trigger para modified_at
CREATE TRIGGER update_comments_modified_at
  BEFORE UPDATE ON comments
  FOR EACH ROW
  EXECUTE FUNCTION update_modified_at_column();

-- RLS
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Políticas RLS
CREATE POLICY "Anyone can read comments"
  ON comments FOR SELECT
  USING (true);

CREATE POLICY "Authenticated users can create comments"
  ON comments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments"
  ON comments FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
  ON comments FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Comentarios (documentación)
COMMENT ON TABLE comments IS 'Comentarios en chismes';
COMMENT ON COLUMN comments.gossip_id IS 'ID del chisme comentado';
COMMENT ON COLUMN comments.text IS 'Contenido del comentario (max 500 chars)';
```

### Paso 3: Aplicar Migración

```bash
# Reset DB (desarrollo - aplica TODAS las migraciones + seed)
supabase db reset --linked

# O aplicar solo nueva migración (producción)
supabase db push

# Verificar estado
supabase db status
```

### Paso 4: Verificar en Supabase Dashboard

1. Abrir Supabase Dashboard
2. Ir a "Table Editor"
3. Verificar que tabla `comments` existe
4. Verificar RLS policies en "Authentication" → "Policies"

### Naming Pattern

```
{number}_{action}_{what}.sql

Ejemplos:
005_create_comments_table.sql
006_add_user_avatar_column.sql
007_add_gossips_search_index.sql
008_alter_comments_add_likes.sql
```

---

## Agregar Logging

### En Servicios/Repositorios

```dart
import 'package:injectable/injectable.dart';
import '../../core/logging/app_logger.dart';

@injectable
class MyService {
  final AppLogger _logger;
  
  MyService(this._logger);
  
  Future<void> doSomething() async {
    _logger.i('Starting operation', context: {'operation': 'doSomething'});
    
    try {
      // Logic
      _logger.d('Debug detail', context: {'detail': 'value'});
      
      _logger.i('Operation completed successfully');
    } catch (error, stackTrace) {
      _logger.e('Operation failed',
        error: error,
        stackTrace: stackTrace,
        context: {
          'operation': 'doSomething',
          'errorType': error.runtimeType.toString(),
        },
      );
      rethrow;
    }
  }
}
```

### En Controllers

```dart
@injectable
class MyController extends ChangeNotifier {
  final AppLogger _logger;
  
  MyController(this._logger);
  
  Future<void> performAction() async {
    _logger.i('User action started', context: {'action': 'performAction'});
    
    final result = await _useCase();
    
    result.fold(
      onFailure: (failure) {
        _logger.e('Action failed',
          context: {
            'action': 'performAction',
            'failureType': failure.runtimeType.toString(),
            'message': failure.message,
          },
        );
      },
      onSuccess: (data) {
        _logger.i('Action completed', context: {'resultId': data.id});
      },
    );
  }
}
```

### Establecer userId

```dart
// Después de login
final logger = getIt<AppLogger>();
logger.setUserId(user.id);

// Después de logout
logger.setUserId(null);
```

---

## Testing Workflow

### TDD (Test-Driven Development)

```bash
# 1. Escribir test (falla)
# test/features/comments/domain/usecases/create_comment_test.dart

# 2. Ejecutar test (debe fallar)
flutter test test/features/comments/domain/usecases/create_comment_test.dart

# 3. Escribir código mínimo para pasar test
# lib/features/comments/domain/usecases/create_comment.dart

# 4. Ejecutar test (debe pasar)
flutter test test/features/comments/domain/usecases/create_comment_test.dart

# 5. Refactorizar
# Mejorar código manteniendo tests pasando

# 6. Repetir
```

### Coverage Workflow

```bash
# 1. Ejecutar tests con coverage
flutter test --coverage

# 2. Generar HTML
genhtml coverage/lcov.info -o coverage/html

# 3. Abrir reporte
open coverage/html/index.html

# 4. Identificar gaps (<75%)
# Ver archivos con bajo coverage en reporte HTML

# 5. Agregar tests para gaps críticos

# 6. Repetir hasta >75%
```

---

## Deployment

### Pre-Deploy Checklist

```bash
# 1. Tests
flutter test
# Todos deben pasar

# 2. Analyze
flutter analyze
# 0 issues

# 3. Format
dart format .

# 4. Coverage
flutter test --coverage
lcov --list coverage/lcov.info
# Verificar >75%

# 5. Build
flutter build apk --release  # Android
flutter build ios --release  # iOS

# 6. Migraciones
supabase db push  # Producción
```

### Android Release

```bash
# Build APK
flutter build apk --release

# Build App Bundle (Google Play)
flutter build appbundle --release

# Output:
# build/app/outputs/flutter-apk/app-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

### iOS Release

```bash
# Build
flutter build ios --release

# Abrir Xcode
open ios/Runner.xcworkspace

# En Xcode:
# 1. Product → Archive
# 2. Upload to App Store Connect
```

---

## Comandos Útiles

### Development

```bash
# Run app
flutter run

# Run con device específico
flutter run -d <device-id>

# Hot reload: r (en terminal)
# Hot restart: R

# Run con logs verbose
flutter run -v

# Clean
flutter clean
flutter pub get

# Outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade
```

### Code Generation

```bash
# DI (Injectable)
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (regenera automáticamente)
flutter pub run build_runner watch --delete-conflicting-outputs

# Clean y regenerar
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testing

```bash
# Todos
flutter test

# Feature específico
flutter test test/features/comments/

# Archivo específico
flutter test test/features/comments/data/repositories/comment_repository_impl_test.dart

# Por nombre
flutter test --name "debe crear comentario"

# Verbose
flutter test --verbose

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Supabase

```bash
# Login
supabase login

# Link proyecto
supabase link --project-ref <project-ref>

# Estado
supabase db status

# Reset DB (desarrollo)
supabase db reset --linked

# Nueva migración
supabase migration new descriptive_name

# Aplicar migraciones (producción)
supabase db push

# Ver logs
supabase functions logs <function-name>

# Deploy function
supabase functions deploy <function-name>
```

### Análisis

```bash
# Format
dart format .

# Analyze
flutter analyze

# Fix automático
dart fix --apply

# Metrics (opcional)
dart run dart_code_metrics:metrics analyze lib
```

### Git

```bash
# Commit
git add .
git commit -m "feat: descripción"

# Push
git push origin main

# Nueva rama
git checkout -b feature/comments

# Merge
git checkout main
git merge feature/comments

# Ver cambios
git diff
git status
```

### Otros

```bash
# Ver devices
flutter devices

# Doctor (verificar setup)
flutter doctor

# Ver logs
flutter logs

# Screenshot
flutter screenshot

# Version
flutter --version

# Upgrade Flutter
flutter upgrade
```

---

## 📚 Referencias

- **Flutter CLI:** https://docs.flutter.dev/reference/flutter-cli
- **Supabase CLI:** https://supabase.com/docs/reference/cli
- **Git Commands:** https://git-scm.com/docs

---

**Última actualización:** 2026-10-20  
**Mantenedor:** Alejo
