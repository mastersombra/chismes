import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../l10n/l10n.dart';
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
        _logger.i('Deep link received (app open)', context: {'uri': uri.toString()});
        _handleDeepLink(uri);
      },
      onError: (error) {
        _logger.e('Error receiving deep link', error: error);
      },
    );

    // Manejar link cuando app se ABRE desde el link
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _logger.i('Initial deep link (app closed)', context: {'uri': initialUri.toString()});
        // Pequeño delay para que la app termine de inicializar
        await Future.delayed(const Duration(milliseconds: 500));
        _handleDeepLink(initialUri);
      }
    } catch (error) {
      _logger.e('Error getting initial deep link', error: error);
    }
  }

  /// Maneja el deep link y navega a la pantalla correspondiente
  void _handleDeepLink(Uri uri) {
    _logger.d('Processing deep link', context: {
      'uri': uri.toString(),
      'scheme': uri.scheme,
      'host': uri.host,
      'path': uri.path,
      'pathSegments': uri.pathSegments,
    });

    // Validar esquema
    if (uri.scheme != 'chismes') {
      _logger.w('Unsupported scheme', context: {'scheme': uri.scheme});
      return;
    }

    // En chismes://gossip/abc123 el tipo es el host ("gossip") y el ID es el
    // primer segmento del path. También se acepta chismes:///gossip/abc123.
    final segments = [
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ];

    // Validar que hay tipo de link
    if (segments.isEmpty) {
      _logger.w('Deep link without path', context: {'uri': uri.toString()});
      return;
    }

    final type = segments.first; // "gossip", "profile", "auth", etc.

    switch (type) {
      case 'auth':
        // Deep link de autenticación (OAuth)
        // Supabase lo maneja automáticamente, no hacer nada
        _logger.i('Auth deep link (handled by Supabase)', context: {'uri': uri.toString()});
        break;

      case 'gossip':
        _handleGossipLink(uri, segments);
        break;

      case 'profile':
        _handleProfileLink(uri, segments);
        break;

      case 'feed':
        _handleFeedLink(uri);
        break;

      default:
        _logger.w('Unsupported deep link type', context: {'type': type});
    }
  }

  /// Maneja deep link de chisme: chismes://gossip/{id}
  void _handleGossipLink(Uri uri, List<String> segments) {
    if (segments.length < 2) {
      _logger.w('Gossip deep link without ID', context: {'uri': uri.toString()});
      return;
    }

    final gossipId = segments[1]; // "abc123"
    _logger.i('Navigating to gossip', context: {'gossipId': gossipId});

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
    _logger.d('Should open gossip with ID: $gossipId');
    final context = _navigatorKey.currentContext;
    if (context != null) {
      _showSnackBar(context.l10n.deepLinkOpeningGossip(gossipId));
    }
  }

  /// Maneja deep link de perfil: chismes://profile/{id}
  void _handleProfileLink(Uri uri, List<String> segments) {
    if (segments.length < 2) {
      _logger.w('Profile deep link without ID', context: {'uri': uri.toString()});
      return;
    }

    final userId = segments[1];
    _logger.i('Navigating to profile', context: {'userId': userId});

    // TODO: Implementar cuando tengas ProfileScreen
    _logger.d('Should open profile with ID: $userId');
    final context = _navigatorKey.currentContext;
    if (context != null) {
      _showSnackBar(context.l10n.deepLinkOpeningProfile(userId));
    }
  }

  /// Maneja deep link de feed: chismes://feed?city={id}
  void _handleFeedLink(Uri uri) {
    final cityId = uri.queryParameters['city'];

    if (cityId != null) {
      _logger.i('Navigating to filtered feed', context: {'cityId': cityId});
      // TODO: Implementar filtro de feed
      final context = _navigatorKey.currentContext;
      if (context != null) {
        _showSnackBar(context.l10n.deepLinkOpeningCityFeed(cityId));
      }
    } else {
      _logger.i('Navigating to general feed');
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
