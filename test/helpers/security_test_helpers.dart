import 'package:flutter_test/flutter_test.dart';

/// Helpers para testing de seguridad
///
/// Uso:
/// ```dart
/// SecurityTestHelpers.verifyMessageSecurity(message);
/// ```
class SecurityTestHelpers {
  SecurityTestHelpers._();

  /// Términos prohibidos en mensajes de error del usuario
  /// Basado en OWASP Security Testing Guide
  static const List<String> _forbiddenTerms = [
    // Database & Backend
    'postgres', 'postgresql', 'mysql', 'mongodb', 'redis', 'database',
    'db', 'sql', 'query', 'table', 'column', 'schema',

    // Server & Infrastructure
    'server', 'localhost', 'internal', 'prod', 'staging', 'dev',
    'port', '3000', '5432', '27017', 'timeout', 'connection refused',

    // Authentication & Tokens
    'password', 'pwd', 'pass', 'token', 'jwt', 'bearer', 'session',
    'cookie', 'auth_token', 'api_key', 'secret',

    // Technical Terms
    'exception', 'stack', 'trace', 'stacktrace', 'error stack',
    'null pointer', 'undefined', 'regex', 'regexp',

    // Path Disclosure
    '/var/', '/home/', '/usr/', 'c:\\', 'd:\\',
    'node_modules', 'lib/', 'src/', '.dart', '.java', '.py',

    // Version Info
    'version', 'v1.0', 'build', 'commit',

    // Email addresses & IPs (patterns)
    '@internal', '@admin', '192.168', '10.0', '127.0.0.1',
  ];

  /// Términos permitidos en mensajes de usuario
  static const List<String> _allowedTerms = [
    // User-friendly terms
    'email', 'correo', 'formato', 'inválido', 'requerido', 'required',
    'contraseña', 'password', 'usuario', 'user', 'nombre', 'name',
    'muy corto', 'muy largo', 'demasiado', 'mínimo', 'máximo',
    'carácter', 'caracteres', 'letra', 'número', 'especial',
    'mayúscula', 'minúscula', 'espacio', 'vacío', 'empty',

    // Error categories
    'error', 'validación', 'validation', 'datos', 'data',
    'servidor', 'conexión', 'connection', 'red', 'network',

    // Actions
    'intenta', 'verifica', 'revisa', 'try', 'check', 'verify',
  ];

  /// Verifica que un mensaje de error sea seguro para el usuario
  ///
  /// Verificaciones:
  /// - No contiene información técnica sensible
  /// - No expone rutas del sistema
  /// - No revela versiones o estructura interna
  /// - Longitud razonable (< 300 caracteres)
  /// - Contiene al menos un término permitido
  ///
  /// Throws [TestFailure] si el mensaje no es seguro
  static void verifyMessageSecurity(String? message, {
    String context = '',
    List<String>? additionalForbidden,
    int maxLength = 300,
  }) {
    if (message == null || message.isEmpty) {
      return; // Mensaje vacío es seguro
    }

    final contextPrefix = context.isNotEmpty ? '[$context] ' : '';
    final lowerMsg = message.toLowerCase();

    // 1. Verificar términos prohibidos
    final allForbidden = [
      ..._forbiddenTerms,
      if (additionalForbidden != null) ...additionalForbidden,
    ];

    for (final term in allForbidden) {
      if (lowerMsg.contains(term.toLowerCase())) {
        fail(
          '${contextPrefix}Mensaje contiene término prohibido "$term": "$message"\n'
          'Los mensajes de usuario NO deben exponer información técnica.',
        );
      }
    }

    // 2. Verificar longitud razonable
    if (message.length > maxLength) {
      fail(
        '${contextPrefix}Mensaje muy largo (${message.length} caracteres, max: $maxLength).\n'
        'Mensaje: "$message"\n'
        'Mensajes largos pueden indicar data leakage.',
      );
    }

    // 3. Verificar que contiene al menos un término permitido
    final hasAllowedTerm = _allowedTerms.any(
      (term) => lowerMsg.contains(term.toLowerCase()),
    );

    if (!hasAllowedTerm) {
      // Warning, no fail (puede ser un mensaje válido sin nuestros términos)
      // ignore: avoid_print
      print(
        'ℹ️  ${contextPrefix}Mensaje no contiene términos conocidos: "$message"',
      );
    }

    // 4. Verificar patrones peligrosos con regex
    _verifyNoEmailLeakage(message, contextPrefix);
    _verifyNoIPLeakage(message, contextPrefix);
    _verifyNoPathLeakage(message, contextPrefix);
  }

  /// Verifica que el mensaje no filtra emails
  static void _verifyNoEmailLeakage(String message, String contextPrefix) {
    final emailPattern = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final match = emailPattern.firstMatch(message);

    if (match != null) {
      fail(
        '${contextPrefix}Mensaje contiene dirección de email: "${match.group(0)}"\n'
        'Mensaje completo: "$message"\n'
        'NUNCA expongas emails de usuarios en mensajes de error.',
      );
    }
  }

  /// Verifica que el mensaje no filtra IPs
  static void _verifyNoIPLeakage(String message, String contextPrefix) {
    final ipPattern = RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b');
    final match = ipPattern.firstMatch(message);

    if (match != null) {
      fail(
        '${contextPrefix}Mensaje contiene dirección IP: "${match.group(0)}"\n'
        'Mensaje completo: "$message"\n'
        'NUNCA expongas IPs en mensajes de error.',
      );
    }
  }

  /// Verifica que el mensaje no filtra rutas del sistema
  static void _verifyNoPathLeakage(String message, String contextPrefix) {
    // Unix paths
    if (message.contains('/') && (
        message.contains('/var') ||
        message.contains('/home') ||
        message.contains('/usr') ||
        message.contains('/opt')
    )) {
      fail(
        '${contextPrefix}Mensaje contiene ruta Unix: "$message"\n'
        'NUNCA expongas rutas del sistema.',
      );
    }

    // Windows paths
    if (RegExp(r'[A-Z]:\\').hasMatch(message)) {
      fail(
        '${contextPrefix}Mensaje contiene ruta Windows: "$message"\n'
        'NUNCA expongas rutas del sistema.',
      );
    }
  }

  /// Verifica que el input del usuario no aparece en el mensaje
  /// (previene reflection attacks)
  static void verifyNoUserInputReflection(
    String? message,
    String userInput, {
    String context = '',
  }) {
    if (message == null || message.isEmpty || userInput.isEmpty) {
      return;
    }

    final contextPrefix = context.isNotEmpty ? '[$context] ' : '';

    // El input del usuario NO debe aparecer sin sanitizar en el mensaje
    if (message.contains(userInput) && userInput.length > 3) {
      fail(
        '${contextPrefix}Mensaje refleja input del usuario sin sanitizar: "$userInput"\n'
        'Mensaje completo: "$message"\n'
        'Esto puede permitir XSS o inyección de código.',
      );
    }
  }

  /// Verifica que el mensaje está en el idioma esperado
  static void verifyMessageLanguage(
    String? message, {
    required String expectedLanguage,
    String context = '',
  }) {
    if (message == null || message.isEmpty) {
      return;
    }

    final contextPrefix = context.isNotEmpty ? '[$context] ' : '';

    if (expectedLanguage == 'es') {
      // Debe contener caracteres propios del español
      final spanishIndicators = ['á', 'é', 'í', 'ó', 'ú', 'ñ', 'ü'];
      final containsSpanishChars = spanishIndicators.any(
        (char) => message.toLowerCase().contains(char),
      );

      // O palabras claramente en español
      final spanishWords = [
        'el', 'la', 'los', 'las', 'un', 'una', 'es', 'está',
        'correo', 'contraseña', 'usuario', 'debe', 'tiene',
      ];
      final containsSpanishWords = spanishWords.any(
        (word) => message.toLowerCase().contains(word),
      );

      if (!containsSpanishChars && !containsSpanishWords) {
        // Warning, no fail
        // ignore: avoid_print
        print(
          'ℹ️  ${contextPrefix}Mensaje puede no estar en español: "$message"',
        );
      }
    }
  }

  /// Crea un matcher para mensajes seguros
  static Matcher isSafeUserMessage({
    List<String>? additionalForbidden,
    int maxLength = 300,
  }) {
    return predicate<String>(
      (message) {
        try {
          verifyMessageSecurity(
            message,
            additionalForbidden: additionalForbidden,
            maxLength: maxLength,
          );
          return true;
        } catch (e) {
          return false;
        }
      },
      'es un mensaje seguro para el usuario',
    );
  }
}
