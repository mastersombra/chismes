import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../gossip/domain/entities/gossip.dart';
import '../../../gossip/presentation/widgets/gossip_card.dart';
import '../../../gossip/domain/usecases/get_gossips.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/result/result.dart';
import '../../../../core/di/injection_container.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Gossip> results = [];
  bool hasSearched = false;
  bool isLoading = false;
  String? errorMessage;

  // ✅ Usar DI container (Injectable)
  late final GetGossips _getGossips;

  @override
  void initState() {
    super.initState();
    _getGossips = getIt<GetGossips>();
  }

  void searchGossip(String query) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await _getGossips();

    result.when(
      onSuccess: (allGossips) {
        final searchLower = query.toLowerCase();
        final filtered = allGossips.where((gossip) {
          final subjectLower = gossip.subject.toLowerCase();
          final contentLower = gossip.content.toLowerCase();

          return subjectLower.contains(searchLower) ||
              contentLower.contains(searchLower);
        }).toList();

        if (mounted) {
          setState(() {
            hasSearched = true;
            results = filtered;
            isLoading = false;
          });
        }
      },
      onFailure: (error) {
        if (mounted) {
          setState(() {
            errorMessage = ErrorMessages.getMessage(error.code);
            isLoading = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('search.title'.tr()),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: TextField(
              onChanged: searchGossip,
              decoration: InputDecoration(
                hintText: 'search.hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ),

          Expanded(
            child: !hasSearched
                ? Center(
                    child: Text(
                      'search.empty_state'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : results.isEmpty
                    ? Center(
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
                              'search.no_results'.tr(),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: results.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
      ),
    );
  }
}