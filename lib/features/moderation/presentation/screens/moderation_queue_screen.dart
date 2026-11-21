import 'package:flutter/material.dart';

import 'package:chismes/core/l10n/l10n.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/error/error_codes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/moderation_appeal.dart';
import '../../domain/entities/moderation_item.dart';
import '../controllers/appeals_controller.dart';
import '../controllers/moderation_queue_controller.dart';
import '../widgets/appeals_tab.dart';
import '../widgets/moderation_item_card.dart';
import 'appeal_item_screen.dart';
import 'moderation_item_screen.dart';

/// Panel de moderación: pendientes, aprobados, rechazados y apelaciones.
///
/// Solo se muestra la entrada a moderadores, pero quien autoriza es el
/// servidor: a cualquier otro usuario `moderation-review` le responde 403 y
/// aquí se ve "sin permisos".
class ModerationQueueScreen extends StatefulWidget {
  const ModerationQueueScreen({super.key});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen>
    with SingleTickerProviderStateMixin {
  static const _statuses = ModerationQueueStatus.values;

  /// Índice de la pestaña Apelaciones (después de las de la cola)
  static final _appealsTab = _statuses.length;

  late final ModerationQueueController _controller;
  late final AppealsController _appealsController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ModerationQueueController>();
    _appealsController = getIt<AppealsController>();
    _tabController = TabController(length: _statuses.length + 1, vsync: this)
      ..addListener(_onTabChanged);
    _controller.ensureLoaded(ModerationQueueStatus.pending);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _controller.dispose();
    _appealsController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (index == _appealsTab) {
      _appealsController.select(_appealsController.selected);
    } else {
      _controller.ensureLoaded(_statuses[index]);
    }
  }

  Future<void> _openAppeal(ModerationAppeal appeal) async {
    final leftPending = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => AppealItemScreen(appeal: appeal)),
    );
    if (leftPending == true) {
      _appealsController.onAppealDecided(appeal.id);
      // Aceptar anula un rechazo: el historial de la cola cambió
      _controller.invalidateHistory();
    }
  }

  Future<void> _open(ModerationItem item) async {
    final leftPending = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ModerationItemScreen(item: item)),
    );
    if (leftPending == true) _controller.onItemDecided(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.moderationTitle),
        bottom: TabBar(
          controller: _tabController,
          // 4 pestañas no entran en 320 px con letra grande
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(text: l10n.moderationTabPending),
            Tab(text: l10n.moderationTabApproved),
            Tab(text: l10n.moderationTabRejected),
            Tab(text: l10n.moderationTabAppeals),
          ],
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => TabBarView(
          controller: _tabController,
          children: [
            for (final status in _statuses)
              _QueueList(
                status: status,
                state: _controller.tab(status),
                onRefresh: () => _controller.refresh(status),
                onLoadMore: () => _controller.loadMore(status),
                onOpen: _open,
              ),
            AppealsTab(controller: _appealsController, onOpen: _openAppeal),
          ],
        ),
      ),
    );
  }
}

class _QueueList extends StatelessWidget {
  /// Distancia al final de la lista para pedir la siguiente página
  static const double _loadMoreThreshold = 200;

  final ModerationQueueStatus status;
  final ModerationTabState state;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final ValueChanged<ModerationItem> onOpen;

  const _QueueList({
    required this.status,
    required this.state,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!state.loaded || (state.isLoading && state.items.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorCode != null && state.items.isEmpty) {
      final forbidden = state.errorCode == ErrorCode.forbidden;
      return _Message(
        icon: forbidden ? Icons.lock_outline : Icons.cloud_off_outlined,
        title: forbidden ? l10n.moderationForbidden : l10n.moderationLoadError,
        action: forbidden
            ? null
            : FilledButton.tonal(onPressed: onRefresh, child: Text(l10n.commonRetry)),
      );
    }

    if (state.items.isEmpty) {
      final pending = status == ModerationQueueStatus.pending;
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: constraints.maxHeight,
              child: _Message(
                icon: pending ? Icons.task_alt : Icons.history,
                title: pending ? l10n.moderationEmptyPending : l10n.moderationEmptyHistory,
                subtitle: pending ? l10n.moderationEmptyPendingHint : null,
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          final metrics = notification.metrics;
          if (metrics.pixels >= metrics.maxScrollExtent - _loadMoreThreshold) onLoadMore();
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            if (index >= state.items.length) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final item = state.items[index];
            return ModerationItemCard(item: item, onTap: () => onOpen(item));
          },
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const _Message({required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppSpacing.xxxl, color: muted),
            const SizedBox(height: AppSpacing.lg),
            Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
