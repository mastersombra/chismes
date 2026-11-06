import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection_container.config.dart';

final getIt = GetIt.instance;

/// Global navigator key para deep links y navegación programática
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
Future<void> configureDependencies() async {
  // Registrar navigator key para DeepLinkService
  getIt.registerSingleton<GlobalKey<NavigatorState>>(
    navigatorKey,
    instanceName: 'navigatorKey',
  );

  $initGetIt(getIt);
}
