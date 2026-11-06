import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../logging/logging.dart';

/// Servicio para manejar deep links en la aplicación
///
/// **Deep Links Soportados:**
/// - `chismes://gossip/{id}` - Abre un chisme específico
/// - `chismes://profile/{id}` - Abre perfil de usuario (futuro)
/// - `chismes://feed?city={id}` - Abre feed filtrado (futuro)
///
/// **Usos:**
/// 1. Compartir chismes entre usuarios (WhatsApp, Telegram, etc.)
/// 2. Notificaciones push (reutiliza el mismo código)
/// 3. Links internos de la app
///
/// **NO requiere:**
/// - Hosting
/// - Dominio
/// - Landing page web
///
/// **Solo funciona cuando:**
/// - Ambos usuarios tienen la app instalada
/// - Para usuarios sin app, necesitarás Universal Links (https://) en el futuro
@singleton
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  final GlobalKey<NavigatorState> _navigatorKey;
  final AppLogger _logger;

  StreamSubscription<Uri>? _linkSubscription;

  DeepLinkService(
    @Named('navigatorKey') this._navigatorKey,
    this._logger,
  );

  /// Inicializa el servicio y empieza a escuchar deep links
  Future<void> initialize() async {
    // Manejar link cuando app YA está abierta
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _logger.i('📥 Deep link recibido (app abierta)', context: {'uri': uri.toString()});
        _handleDeepLink(uri);
      },
      onError: (error) {
        _logger.e('Error recibiendo deep link', error: error);
      },
    );

    // Manejar link cuando app se ABRE desde el link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _logger.i('📥 Deep link inicial (app cerrada)', context: {'uri': initialUri.toString()});
        // Pequeño delay para que la app termine de inicializar
        await Future.delayed(const Duration(milliseconds: 500));
        _handleDeepLink(initialUri);
      }
    } catch (error) {
      _logger.e('Error obteniendo deep link inicial', error: error);
    }
  }

  /// Maneja el deep link y navega a la pantalla correspondiente
  void _handleDeepLink(Uri uri) {
    _logger.d('🔗 Procesando deep link', context: {
      'uri': uri.toString(),
      'scheme': uri.scheme,
      'host': uri.host,
      'path': uri.path,
      'pathSegments': uri.pathSegments,
    });

    // Validar esquema
    if (uri.scheme != 'chismes') {
      _logger.w('Esquema no soportado', context: {'scheme': uri.scheme});
      return;
    }

    // Validar que hay segmentos de path
    if (uri.pathSegments.isEmpty) {
      _logger.w('Deep link sin path', context: {'uri': uri.toString()});
      return;
    }

    final type = uri.pathSegments.first; // "gossip", "profile", "auth", etc.

    switch (type) {
      case 'auth':
        // Deep link de autenticación (OAuth)
        // Supabase lo maneja automáticamente, no hacer nada
        _logger.i('✅ Deep link de auth (manejado por Supabase)', context: {'uri': uri.toString()});
        break;

      case 'gossip':
        _handleGossipLink(uri);
        break;

      case 'profile':
        _handleProfileLink(uri);
        break;

      case 'feed':
        _handleFeedLink(uri);
        break;

      default:
        _logger.w('Tipo de deep link no soportado', context: {'type': type});
    }
  }

  /// Maneja deep link de chisme: chismes://gossip/{id}
  void _handleGossipLink(Uri uri) {
    if (uri.pathSegments.length < 2) {
      _logger.w('Deep link de gossip sin ID', context: {'uri': uri.toString()});
      return;
    }

    final gossipId = uri.pathSegments[1]; // "abc123"
    _logger.i('✅ Navegando a chisme', context: {'gossipId': gossipId});

    // Navegar a pantalla de detalle de chisme
    // TODO: Cuando implementes GossipDetailScreen, descomentar esto:
    /*
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => GossipDetailScreen(gossipId: gossipId),
      ),
    );
    */

    // Por ahora, solo mostrar un mensaje
    _logger.d('📍 Debería abrir chisme con ID: $gossipId');
    _showSnackBar('Abriendo chisme: $gossipId');
  }

  /// Maneja deep link de perfil: chismes://profile/{id}
  void _handleProfileLink(Uri uri) {
    if (uri.pathSegments.length < 2) {
      _logger.w('Deep link de profile sin ID', context: {'uri': uri.toString()});
      return;
    }

    final userId = uri.pathSegments[1];
    _logger.i('✅ Navegando a perfil', context: {'userId': userId});

    // TODO: Implementar cuando tengas ProfileScreen
    _logger.d('📍 Debería abrir perfil con ID: $userId');
    _showSnackBar('Abriendo perfil: $userId');
  }

  /// Maneja deep link de feed: chismes://feed?city={id}
  void _handleFeedLink(Uri uri) {
    final cityId = uri.queryParameters['city'];

    if (cityId != null) {
      _logger.i('✅ Navegando a feed filtrado', context: {'cityId': cityId});
      // TODO: Implementar filtro de feed
      _showSnackBar('Abriendo feed de ciudad: $cityId');
    } else {
      _logger.i('✅ Navegando a feed general');
      // Navegar a home
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  /// Muestra un SnackBar (útil para debugging)
  void _showSnackBar(String message) {
    final context = _navigatorKey.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Genera un deep link para compartir un chisme
  ///
  /// Ejemplo: `chismes://gossip/abc123`
  static String generateGossipLink(String gossipId) {
    return 'chismes://gossip/$gossipId';
  }

  /// Genera un deep link para compartir un perfil
  ///
  /// Ejemplo: `chismes://profile/user123`
  static String generateProfileLink(String userId) {
    return 'chismes://profile/$userId';
  }

  /// Genera un deep link para feed filtrado
  ///
  /// Ejemplo: `chismes://feed?city=medellin`
  static String generateFeedLink({String? cityId}) {
    if (cityId != null) {
      return 'chismes://feed?city=$cityId';
    }
    return 'chismes://feed';
  }

  /// Limpia recursos
  void dispose() {
    _linkSubscription?.cancel();
  }
}
