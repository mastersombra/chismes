/// Result type para manejar errores de forma funcional
/// Implementado con sealed class para seguridad en tiempo de compilación
///
/// **ARQUITECTURA: Sealed Class (Dart 3.0+)**
///
/// Ventajas sobre la implementación anterior con invariantes:
/// 1. ✅ Imposible crear estados inválidos (no hay null/null o ambos con valor)
/// 2. ✅ Pattern matching exhaustivo verificado por el compilador
/// 3. ✅ Más idiomático en Dart 3.0+
/// 4. ✅ Type safety sin casts
///
/// Uso básico:
/// ```dart
/// Result<Failure, User> result = repository.getUser();
///
/// // Opción 1: Pattern matching (recomendado en Dart 3.0+)
/// switch (result) {
///   case Success(value: final user):
///     print(user.name);
///   case ResultFailure(error: final err):
///     print(err.message);
/// }
///
/// // Opción 2: Método .when() (compatible con código existente)
/// result.when(
///   onSuccess: (user) => print(user.name),
///   onFailure: (error) => print(error.message),
/// );
/// ```
sealed class Result<L, R> {
  const Result();

  /// Factory constructor: Crea un resultado exitoso
  factory Result.success(R value) => Success(value);

  /// Factory constructor: Crea un resultado fallido
  factory Result.failure(L error) => ResultFailure(error);
}

/// Resultado exitoso
final class Success<L, R> extends Result<L, R> {
  final R value;
  const Success(this.value);

  @override
  String toString() => 'Result.success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<L, R> &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Resultado fallido
///
/// Nota: Nombrada `ResultFailure` en lugar de solo `Failure` para evitar
/// conflicto con la clase `Failure` de `core/error/failure.dart`
final class ResultFailure<L, R> extends Result<L, R> {
  final L error;
  const ResultFailure(this.error);

  @override
  String toString() => 'Result.failure($error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultFailure<L, R> &&
          runtimeType == other.runtimeType &&
          error == other.error;

  @override
  int get hashCode => error.hashCode;
}

/// Extension methods para mantener compatibilidad con API anterior
extension ResultExt<L, R> on Result<L, R> {
  /// Ejecuta una función basada en el resultado
  ///
  /// Pattern matching con callbacks para mantener compatibilidad
  /// con código existente que usaba .when()
  T when<T>({
    required T Function(R success) onSuccess,
    required T Function(L failure) onFailure,
  }) {
    return switch (this) {
      Success(value: final v) => onSuccess(v),
      ResultFailure(error: final e) => onFailure(e),
    };
  }

  /// Ejecuta una función solo si es exitoso
  Result<L, R> onSuccess(Function(R success) callback) {
    if (this case Success(value: final v)) {
      callback(v);
    }
    return this;
  }

  /// Ejecuta una función solo si es fallido
  Result<L, R> onFailure(Function(L failure) callback) {
    if (this case ResultFailure(error: final e)) {
      callback(e);
    }
    return this;
  }

  /// Transforma el valor de éxito
  Result<L, T2> map<T2>(T2 Function(R success) mapper) {
    return switch (this) {
      Success(value: final v) => Success(mapper(v)),
      ResultFailure(error: final e) => ResultFailure(e),
    };
  }

  /// Transforma el valor de fallo
  Result<L2, R> mapFailure<L2>(L2 Function(L failure) mapper) {
    return switch (this) {
      Success(value: final v) => Success(v),
      ResultFailure(error: final e) => ResultFailure(mapper(e)),
    };
  }

  /// Retorna true si el resultado es exitoso
  bool get isSuccess => this is Success<L, R>;

  /// Retorna true si el resultado es fallido
  bool get isFailure => this is ResultFailure<L, R>;

  /// Obtiene el valor de éxito o null
  R? get successValue => switch (this) {
        Success(value: final v) => v,
        ResultFailure() => null,
      };

  /// Obtiene el valor de fallo o null
  L? get failureValue => switch (this) {
        Success() => null,
        ResultFailure(error: final e) => e,
      };
}
