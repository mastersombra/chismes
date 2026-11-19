/// Entorno de ejecución de la app, elegido al compilar con `--dart-define`.
///
/// ```bash
/// flutter run                                              # dev (default, lee .env)
/// flutter build apk --dart-define-from-file=config/staging.json
/// flutter build ipa --dart-define-from-file=config/prod.json
/// ```
///
/// Cada `config/<env>.json` define `ENV`, `SUPABASE_URL` y `SUPABASE_ANON_KEY`
/// (plantilla: `config/env.example.json`; los JSON reales no se commitean).
enum AppEnvironment {
  dev,
  staging,
  prod;

  /// Valor de `--dart-define=ENV=...` (constante de compilación).
  static const String _defined = String.fromEnvironment('ENV');

  /// Entorno de este build. Sin `ENV` definido es [dev].
  static AppEnvironment get current => parse(_defined);

  /// Convierte el valor de `ENV` en un entorno.
  ///
  /// Vacío → [dev]. Un valor desconocido lanza [ArgumentError] para que un
  /// typo (`--dart-define=ENV=produccion`) no compile en silencio como dev.
  static AppEnvironment parse(String value) {
    if (value.isEmpty) return AppEnvironment.dev;
    for (final env in AppEnvironment.values) {
      if (env.name == value) return env;
    }
    throw ArgumentError.value(
      value,
      'ENV',
      'Debe ser uno de: ${AppEnvironment.values.map((e) => e.name).join(', ')}',
    );
  }

  bool get isProd => this == AppEnvironment.prod;
}
