import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/config/supabase_config.dart';
import 'core/di/injection_container.dart';
import 'core/logging/logging.dart';
import 'core/services/deep_link_service.dart' as core_services;
import 'features/auth/presentation/widgets/auth_gate.dart';

/// Callback para cargar variables de entorno.
/// Puede ser sobrescrita en tests.
Future<void> Function({String fileName}) loadEnv = ({String fileName = '.env'}) async {
  await dotenv.load(fileName: fileName);
};

/// Callback para inicializar Supabase.
/// Puede ser sobrescrita en tests.
Future<void> Function() initializeSupabase = () async {
  await SupabaseConfig.initialize();
};

/// Callback para configurar dependencias.
/// Puede ser sobrescrita en tests.
Future<void> Function() setupDependencies = () async {
  await configureDependencies();
};

/// Inicializa la aplicación cargando configuraciones y dependencias.
///
/// Esta función está separada de main() para permitir testing.
/// NOTA: WidgetsFlutterBinding.ensureInitialized() debe llamarse antes de esto.
Future<void> initializeApp() async {
  // Cargar variables de entorno (.env)
  await loadEnv(fileName: '.env');

  // Inicializar Supabase
  await initializeSupabase();

  // Configurar dependencias (Injectable)
  await setupDependencies();

  // Inicializar deep links
  try {
    final deepLinkService = getIt<core_services.DeepLinkService>();
    await deepLinkService.initialize();
    final logger = getIt<AppLogger>();
    logger.i('✅ Deep links inicializados');
  } catch (e) {
    final logger = getIt<AppLogger>();
    logger.w('Error inicializando deep links', context: {'error': e.toString()});
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar internacionalización
  await EasyLocalization.ensureInitialized();

  await initializeApp();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('es'), // Español
        Locale('en'), // Inglés
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'), // Idioma por defecto si no se detecta
      // ✅ NO usar startLocale para respetar preferencia guardada del usuario
      // Si hay idioma guardado en SharedPreferences, lo usa
      // Si no hay idioma guardado, detecta el idioma del sistema
      // Si el idioma del sistema no está soportado, usa fallbackLocale (español)
      saveLocale: true, // Guarda el idioma seleccionado automáticamente
      useOnlyLangCode: true, // Usa solo 'es' en lugar de 'es_MX'
      child: const ChismesApp(),
    ),
  );
}

class ChismesApp extends StatelessWidget {
  const ChismesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chismes',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      navigatorKey: navigatorKey, // ← Para deep links

      // Configuración de internacionalización
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      // ✅ AuthGate decide automáticamente entre Home/Login (sin delays artificiales)
      home: const AuthGate(),
    );
  }
}