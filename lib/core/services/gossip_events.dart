import 'dart:async';

import 'package:injectable/injectable.dart';

/// Eventos de chismes compartidos entre features.
///
/// Las features no dependen entre sí: `gossip` (Crea) emite
/// [gossipPublished] y `home` (feed) escucha [onPublished] para recargar.
@lazySingleton
class GossipEvents {
  final _published = StreamController<void>.broadcast();

  /// Se emite cada vez que el usuario publica un chisme con éxito.
  Stream<void> get onPublished => _published.stream;

  /// Notifica que se publicó un chisme.
  void gossipPublished() => _published.add(null);

  @disposeMethod
  void dispose() => _published.close();
}
