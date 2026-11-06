import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../gossip/presentation/widgets/gossip_card.dart';
import '../controllers/popular_tab_controller.dart';
import 'feed_gossip_adapter.dart';
import 'new_gossips_banner.dart';

/// Widget del tab Popular.
///
/// **Responsabilidades:**
/// - Renderizar feed popular
/// - Manejar pull-to-refresh
/// - Manejar infinite scroll
/// - Mostrar banner de nuevos chismes
/// - Mostrar location header
///
/// **Arquitectura:**
/// - Usa ListenableBuilder para escuchar cambios del controller
/// - CustomScrollView para manejar headers + lista
/// - Detecta scroll para infinite loading
class PopularTab extends StatelessWidget {
  final PopularTabController controller;

  const PopularTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;

        // Loading inicial
        if (state.isLoadingInitial) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // Error
        if (state.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: AppSpacing.md),
                Text(
                  state.errorMessage ?? AppLocalizations.homePopularLoadError,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => controller.loadFeed(),
                  icon: const Icon(Icons.refresh),
                  label: Text(AppLocalizations.commonRetry),
                ),
              ],
            ),
          );
        }

        // Feed vacío
        if (state.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => controller.refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mood_bad, size: 64, color: Colors.grey),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        AppLocalizations.homePopularEmpty,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Feed con chismes
        return RefreshIndicator(
          onRefresh: () => controller.refresh(),
          child: CustomScrollView(
            slivers: [
              // Location header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    state.locationHeaderText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              // Banner de nuevos chismes (condicional)
              if (state.hasNewGossips)
                SliverToBoxAdapter(
                  child: NewGossipsBanner(
                    count: state.newGossipsCount,
                    onTap: () => controller.loadNewGossips(),
                  ),
                ),

              // Lista de chismes
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Preload cuando faltan 3 items
                    if (index == state.gossips.length - 3) {
                      controller.loadMore();
                    }

                    final gossip = state.gossips[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: GossipCard(
                        gossip: FeedGossipAdapter.toGossip(gossip),
                        // TODO: Mostrar badge de ciudad si !isFromMyCity
                      ),
                    );
                  },
                  childCount: state.gossips.length,
                ),
              ),

              // Loading indicator al final (infinite scroll)
              if (state.isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),

              // Mensaje "No hay más" al final
              if (!state.hasMore && state.gossips.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Center(
                      child: Text(
                        AppLocalizations.homePopularNoMore,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
