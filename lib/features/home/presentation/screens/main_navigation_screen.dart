import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../search/presentation/screens/search_screen.dart';
import '../../../gossip/presentation/screens/add_gossip_screen.dart';
import '../../../gossip/presentation/controllers/add_gossip_controller.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'home_screen.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  MainNavigationScreenState createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  // ✅ Lista de pantallas para navegación
  final List<Widget> _screens = [
    const HomeScreen(),
    const SearchScreen(),
    AddGossipScreen(controller: getIt<AddGossipController>()),
    const ProfileScreen(),
  ];

  // ✅ Usar DI container (Injectable)
  late final AddGossipController _addGossipController;

  @override
  void initState() {
    super.initState();

    // ✅ Resolver dependencias de Injectable/GetIt
    _addGossipController = getIt<AddGossipController>();

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
            label: 'navigation.home'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search_outlined),
            activeIcon: const Icon(Icons.search),
            label: 'navigation.explore'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline),
            activeIcon: const Icon(Icons.add_circle),
            label: 'navigation.create'.tr(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: 'navigation.profile'.tr(),
          ),
        ],
      ),
    );
  }
}
