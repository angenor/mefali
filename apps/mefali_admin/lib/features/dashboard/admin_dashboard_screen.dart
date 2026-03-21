import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

/// Ecran dashboard operationnel admin — 4 KPIs avec auto-refresh.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidate(adminDashboardProvider),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return dashboardAsync.when(
      data: (state) => _DashboardContent(state: state),
      loading: () => const _SkeletonLoading(),
      error: (error, _) => _ErrorState(
        error: error,
        onRetry: () => ref.invalidate(adminDashboardProvider),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.state});

  final AdminDashboardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(adminDashboardProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.isCached) _CacheBanner(lastSync: state.lastSync),
          _KpiGrid(stats: state.stats),
        ],
      ),
    );
  }
}

/// Grille 2x2 de cartes KPI.
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: crossAxisCount == 2 ? 2.2 : 3.0,
          children: [
            _KpiCard(
              icon: Icons.receipt_long,
              label: 'Commandes du jour',
              value: stats.ordersToday,
              color: Theme.of(context).colorScheme.primary,
            ),
            _KpiCard(
              icon: Icons.store,
              label: 'Marchands actifs',
              value: stats.activeMerchants,
              color: Theme.of(context).colorScheme.primary,
            ),
            _KpiCard(
              icon: Icons.moped,
              label: 'Livreurs en ligne',
              value: stats.driversOnline,
              color: Theme.of(context).colorScheme.primary,
            ),
            _KpiCard(
              icon: Icons.warning_amber,
              label: 'Litiges en attente',
              value: stats.pendingDisputes,
              color: stats.pendingDisputes > 0
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
          ],
        );
      },
    );
  }
}

/// Carte KPI individuelle.
class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigation vers les listes detaillees (stub pour cette story)
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                '$value',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau donnees en cache.
class _CacheBanner extends StatelessWidget {
  const _CacheBanner({required this.lastSync});

  final DateTime lastSync;

  @override
  Widget build(BuildContext context) {
    final time =
        '${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: MefaliColors.warningLight.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.cloud_off,
                  size: 18, color: MefaliColors.warningLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Derniere mise a jour: $time',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loading pour le dashboard.
class _SkeletonLoading extends StatelessWidget {
  const _SkeletonLoading();

  @override
  Widget build(BuildContext context) {
    final skeletonColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: List.generate(
          4,
          (_) => Container(
            decoration: BoxDecoration(
              color: skeletonColor,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etat erreur avec retry.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text('Erreur de chargement', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('$error', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }
}
