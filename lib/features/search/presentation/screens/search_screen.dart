
import 'package:flutter/material.dart';

import '../../../gossip/domain/entities/gossip.dart';
import '../../../gossip/presentation/widgets/gossip_card.dart';
import '../../../gossip/domain/usecases/get_gossips.dart';
import '../../../gossip/domain/usecases/search_gossips.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/result/result.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/search_history_service.dart';
import '../../../../core/services/location_service.dart';
import 'package:chismes/core/l10n/l10n.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Gossip> results = [];
  List<Gossip> recentGossips = [];
  List<String> searchHistory = [];
  bool hasSearched = false;
  bool isLoading = false;
  bool isLoadingRecent = false;
  bool showHistory = false;
  bool filterByCity = false;
  String? errorMessage;
  String currentQuery = '';
  SavedLocation? userLocation;

  // ✅ Usar DI container (Injectable)
  late final GetGossips _getGossips;
  late final SearchGossips _searchGossips;
  late final SearchHistoryService _historyService;
  late final LocationService _locationService;

  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getGossips = getIt<GetGossips>();
    _searchGossips = getIt<SearchGossips>();
    _historyService = getIt<SearchHistoryService>();
    _locationService = getIt<LocationService>();
    _loadRecentGossips();
    _loadSearchHistory();
    _loadUserLocation();

    // Mostrar historial cuando el TextField recibe foco
    _searchFocusNode.addListener(() {
      if (_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() {
          showHistory = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Carga el historial de búsquedas
  Future<void> _loadSearchHistory() async {
    final history = await _historyService.getHistory();
    if (mounted) {
      setState(() {
        searchHistory = history;
      });
    }
  }

  /// Carga la ubicación guardada del usuario
  Future<void> _loadUserLocation() async {
    final location = await _locationService.getDefaultLocation();
    if (mounted) {
      setState(() {
        userLocation = location;
      });
    }
  }

  /// Carga los chismes recientes para mostrar en el estado inicial
  void _loadRecentGossips() async {
    setState(() {
      isLoadingRecent = true;
      errorMessage = null;
    });

    final result = await _getGossips();

    result.when(
      onSuccess: (gossips) {
        if (mounted) {
          setState(() {
            // Tomar solo los primeros 10 recientes
            recentGossips = gossips.take(10).toList();
            isLoadingRecent = false;
          });
        }
      },
      onFailure: (error) {
        if (mounted) {
          setState(() {
            errorMessage = ErrorMessages.getMessage(context, error.code);
            isLoadingRecent = false;
          });
        }
      },
    );
  }

  void searchGossip(String query) async {
    // Si el query está vacío, resetear a estado inicial
    if (query.trim().isEmpty) {
      setState(() {
        hasSearched = false;
        results = [];
        currentQuery = '';
        errorMessage = null;
        showHistory = true;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      currentQuery = query;
      showHistory = false;
    });

    // ✅ BÚSQUEDA EN SERVIDOR (optimizada)
    // - Solo descarga resultados relevantes
    // - Búsqueda ejecutada en PostgreSQL (ILIKE)
    // - Más rápido con grandes volúmenes
    // - Filtro opcional por ciudad del usuario
    final result = await _searchGossips(
      query: query,
      cityId: filterByCity ? userLocation?.cityId : null,
    );

    result.when(
      onSuccess: (gossips) {
        if (mounted) {
          setState(() {
            hasSearched = true;
            results = gossips;
            isLoading = false;
          });

          // Guardar en historial (siempre, incluso sin resultados)
          _historyService.addSearch(query).then((_) => _loadSearchHistory());
        }
      },
      onFailure: (error) {
        if (mounted) {
          setState(() {
            errorMessage = ErrorMessages.getMessage(context, error.code);
            isLoading = false;
          });
        }
      },
    );
  }

  /// Ejecuta búsqueda desde el historial
  void _searchFromHistory(String query) {
    _searchController.text = query;
    setState(() {
      showHistory = false;
    });
    searchGossip(query);
  }

  /// Elimina un item del historial
  Future<void> _removeFromHistory(String query) async {
    await _historyService.removeSearch(query);
    await _loadSearchHistory();
  }

  /// Limpia todo el historial
  Future<void> _clearHistory() async {
    await _historyService.clearHistory();
    await _loadSearchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.searchTitle),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: searchGossip,
              decoration: InputDecoration(
                hintText: context.l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(AppSpacing.sm),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              searchGossip('');
                            },
                          )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),

          // Mostrar historial de búsquedas
          if (showHistory && searchHistory.isNotEmpty)
            _buildSearchHistory(context),

          // Filtro por ciudad (solo si usuario tiene ubicación)
          if (userLocation != null && !showHistory)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: AppSpacing.xs),
                        Text(context.l10n.searchFilterOnlyCity(userLocation!.cityName)),
                      ],
                    ),
                    selected: filterByCity,
                    onSelected: (selected) {
                      setState(() {
                        filterByCity = selected;
                      });
                      // Re-ejecutar búsqueda si hay query activo
                      if (currentQuery.isNotEmpty) {
                        searchGossip(currentQuery);
                      }
                    },
                  ),
                ],
              ),
            ),

          // Mostrar mensaje de error si existe
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    // Estado: Buscando
    if (isLoading && hasSearched) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado: Mostrando resultados de búsqueda
    if (hasSearched) {
      if (results.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 60,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                context.l10n.searchNoResults,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.searchTryOtherWords,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              context.l10n.searchResultsCount(results.length),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: results.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                return GossipCard(
                  gossip: results[index],
                );
              },
            ),
          ),
        ],
      );
    }

    // Estado: Inicial - Cargando recientes
    if (isLoadingRecent) {
      return const Center(child: CircularProgressIndicator());
    }

    // Estado: Inicial - Mostrar recientes
    if (recentGossips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.searchByTopic,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.searchByKeyword,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            children: [
              const Text(
                '🆕',
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.l10n.searchRecent,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: recentGossips.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.72,
            ),
            itemBuilder: (context, index) {
              return GossipCard(
                gossip: recentGossips[index],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchHistory(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    context.l10n.searchRecentSearches,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _clearHistory,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  context.l10n.searchClearAll,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...searchHistory.take(5).map((query) {
            return InkWell(
              onTap: () => _searchFromHistory(query),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        query,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => _removeFromHistory(query),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 16,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}