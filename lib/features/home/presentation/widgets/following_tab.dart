import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../gossip/presentation/widgets/gossip_card.dart';
import '../controllers/following_tab_controller.dart';
import '../states/following_tab_state.dart';
import 'feed_gossip_adapter.dart';

/// Widget del tab Siguiendo.
///
/// **Responsabilidades:**
/// - Renderizar feed de personas que sigo
/// - Fallback a recomendados si no hay chismes
/// - Empty state si no sigue a nadie
/// - Manejar pull-to-refresh
/// - Manejar infinite scroll
class FollowingTab extends StatelessWidget {
  final FollowingTabController controller;

  const FollowingTab({
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
                  state.errorMessage ?? 'home.error.load_failed'.tr(),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () => controller.loadFeed(),
                  icon: const Icon(Icons.refresh),
                  label: Text('home.error.retry'.tr()),
                ),
              ],
            ),
          );
        }

        // Caso 1: No sigue a nadie (empty state especial)
        if (state.isNotFollowing) {
          return _buildEmptyStateNotFollowing(context);
        }

        // Caso 2 y 3: Mostrando feed (normal o recomendados)
        return _buildFeedList(context, state);
      },
    );
  }

  /// Empty state cuando no sigue a nadie
  Widget _buildEmptyStateNotFollowing(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: Colors.grey),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'home.following.empty_state_title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'home.following.empty_state_message'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a pantalla de explorar usuarios
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('home.following.feature_not_implemented'.tr()),
                  ),
                );
              },
              icon: const Icon(Icons.search),
              label: Text('home.following.explore_users_button'.tr()),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: () {
                // TODO: Cambiar a tab Populares
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('home.following.use_popular_tab_hint'.tr()),
                  ),
                );
              },
              child: Text('home.following.view_popular_link'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  /// Feed list (normal o recomendados)
  Widget _buildFeedList(BuildContext context, FollowingTabState state) {
    return RefreshIndicator(
      onRefresh: () => controller.refresh(),
      child: CustomScrollView(
        slivers: [
          // Badge "Recomendados para ti" si está en modo fallback
          if (state.isShowingRecommended)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                margin: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'home.following.recommended_badge'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Lista de chismes
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final gossips = state.activeList;

                // Preload cuando faltan 3 items
                if (index == gossips.length - 3) {
                  controller.loadMore();
                }

                final gossip = gossips[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  child: GossipCard(
                    gossip: FeedGossipAdapter.toGossip(gossip),
                  ),
                );
              },
              childCount: state.activeList.length,
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
          if (!state.hasMore && state.activeList.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: Text(
                    'home.popular.no_more'.tr(),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),

          // Banner inferior si está mostrando recomendados
          if (state.isShowingRecommended && state.activeList.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Center(
                  child: Text(
                    'home.following.no_posts_message'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
