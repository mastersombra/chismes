
import 'package:flutter/material.dart';

import '../../../search/presentation/screens/search_screen.dart';
import '../../../gossip/presentation/screens/add_gossip_screen.dart';
import '../../../gossip/presentation/controllers/add_gossip_controller.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'home_screen.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:chismes/core/l10n/l10n.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  MainNavigationScreenState createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // Una sola instancia: AddGossipController es factory y arranca la detección
  // GPS al crearse. Dos instancias pedían permisos en paralelo; Android
  // descarta una petición y su Future nunca completa (spinner infinito).
  late final AddGossipController _addGossipController;

  // Lista de pantallas para navegación (usa el controller de arriba)
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // ✅ Resolver dependencias de Injectable/GetIt
    _addGossipController = getIt<AddGossipController>();
    _screens = [
      const HomeScreen(),
      const SearchScreen(),
      AddGossipScreen(controller: _addGossipController),
      const ProfileScreen(),
    ];

    // ✅ AuthGate ya maneja autenticación (no necesitamos guards duplicados aquí)
    // Si el usuario llega aquí, AuthGate ya validó que está autenticado
    // Si cierra sesión, AuthGate detectará el cambio y navegará automáticamente
  }

  @override
  void dispose() {
    _addGossipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.accentBlue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: context.l10n.navigationHome,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
            label: context.l10n.navigationExplore,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            activeIcon: const Icon(Icons.add_circle),
            label: context.l10n.navigationCreate,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: context.l10n.navigationProfile,
          ),
        ],
      ),
    );
  }
}
