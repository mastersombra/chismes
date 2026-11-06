import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../controllers/popular_tab_controller.dart';
import '../controllers/following_tab_controller.dart';
import '../states/following_tab_state.dart';
import '../widgets/popular_tab.dart';
import '../widgets/following_tab.dart';

/// Pantalla principal del Home con 2 tabs: Populares y Siguiendo.
///
/// **Responsabilidades:**
/// - Mostrar TabBar con 2 tabs
/// - Inicializar controllers de cada tab
/// - Gestionar navegación entre tabs
///
/// **Arquitectura:**
/// - Los controllers se obtienen del DI container (getIt)
/// - Cada tab es un widget independiente con su propio controller
/// - Los controllers se disposen automáticamente al salir de la pantalla
///
/// **Uso:**
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => const HomeScreen()),
/// );
/// ```
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PopularTabController _popularController;
  late FollowingTabController _followingController;

  @override
  void initState() {
    super.initState();

    // Inicializar TabController
    _tabController = TabController(length: 2, vsync: this);

    // Obtener controllers del DI
    _popularController = getIt<PopularTabController>();
    _followingController = getIt<FollowingTabController>();

    // Cargar feed inicial del tab activo (Populares)
    _popularController.loadFeed();

    // Escuchar cambios de tab para cargar feed cuando sea necesario
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;

    // Si cambia a tab Siguiendo y no ha cargado aún, cargar
    if (_tabController.index == 1 &&
        _followingController.state.status == FollowingTabStatus.initial) {
      _followingController.loadFeed();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _popularController.dispose();
    _followingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('home.discover_header'.tr()),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.local_fire_department),
              text: 'home.tabs.popular'.tr(),
            ),
            Tab(
              icon: const Icon(Icons.favorite),
              text: 'home.tabs.following'.tr(),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PopularTab(controller: _popularController),
          FollowingTab(controller: _followingController),
        ],
      ),
    );
  }
}
