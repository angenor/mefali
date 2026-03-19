import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

/// Ecran dashboard performance de l'agent terrain.
class AgentPerformanceScreen extends ConsumerWidget {
  const AgentPerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(agentPerformanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes performances')),
      body: statsAsync.when(
        data: (state) => _DashboardContent(state: state),
        loading: () => const _SkeletonLoading(),
        error: (error, _) => _ErrorState(
          error: error,
          onRetry: () => ref.invalidate(agentPerformanceProvider),
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.state});

  final AgentPerformanceState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(agentPerformanceProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.isCached) _CacheBanner(lastSync: state.lastSync),
          _StatsCards(stats: state.stats),
          const SizedBox(height: 16),
          if (state.stats.recentMerchants.isNotEmpty)
            _RecentMerchantsList(merchants: state.stats.recentMerchants),
        ],
      ),
    );
  }
}

/// 3 cartes stat : Marchands, KYC, Commandes.
class _StatsCards extends StatelessWidget {
  const _StatsCards({required this.stats});

  final AgentPerformanceStats stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StatCard(
          icon: Icons.store,
          label: 'Marchands onboardes',
          today: stats.merchantsOnboarded.today,
          thisWeek: stats.merchantsOnboarded.thisWeek,
          total: stats.merchantsOnboarded.total,
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.badge,
          label: 'KYC valides',
          today: stats.kycValidated.today,
          thisWeek: stats.kycValidated.thisWeek,
          total: stats.kycValidated.total,
        ),
        const SizedBox(height: 12),
        _StatCard(
          icon: Icons.receipt_long,
          label: 'Premieres commandes',
          today: null,
          thisWeek: stats.merchantsWithFirstOrder.thisWeek,
          total: stats.merchantsWithFirstOrder.total,
        ),
      ],
    );
  }
}

/// Carte statistique individuelle avec today/week/total.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.today,
    required this.thisWeek,
    required this.total,
  });

  final IconData icon;
  final String label;
  final int? today;
  final int thisWeek;
  final int total;

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<MefaliCustomColors>();
    final hasActivity = (today ?? 0) > 0;
    final accentColor = hasActivity
        ? (customColors?.success ?? const Color(0xFF4CAF50))
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 24),
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (today != null) ...[
                  Expanded(
                    child: _PeriodValue(
                      label: "Aujourd'hui",
                      value: today!,
                      isMain: true,
                      accentColor: accentColor,
                    ),
                  ),
                ],
                Expanded(
                  child: _PeriodValue(
                    label: 'Cette semaine',
                    value: thisWeek,
                    isMain: today == null,
                    accentColor: accentColor,
                  ),
                ),
                Expanded(
                  child: _PeriodValue(
                    label: 'Total',
                    value: total,
                    isMain: false,
                    accentColor: null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Valeur d'une periode (today/week/total) dans une carte.
class _PeriodValue extends StatelessWidget {
  const _PeriodValue({
    required this.label,
    required this.value,
    required this.isMain,
    this.accentColor,
  });

  final String label;
  final int value;
  final bool isMain;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: isMain
              ? Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Liste des 5 derniers marchands onboardes.
class _RecentMerchantsList extends StatelessWidget {
  const _RecentMerchantsList({required this.merchants});

  final List<RecentMerchant> merchants;

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<MefaliCustomColors>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Derniers marchands onboardes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ...merchants.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.store, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.name,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _formatDate(m.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: m.hasFirstOrder
                              ? (customColors?.success ?? const Color(0xFF4CAF50))
                                  .withValues(alpha: 0.15)
                              : MefaliColors.warningLight
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m.hasFirstOrder ? 'Commande recue' : 'En attente',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: m.hasFirstOrder
                                        ? (customColors?.success ??
                                            const Color(0xFF4CAF50))
                                        : MefaliColors.warningLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// Bandeau cache offline.
class _CacheBanner extends StatelessWidget {
  const _CacheBanner({required this.lastSync});

  final DateTime lastSync;

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(lastSync);
    final ago = diff.inMinutes < 60
        ? '${diff.inMinutes} min'
        : '${diff.inHours}h${diff.inMinutes % 60}';

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
                  'Donnees hors ligne - il y a $ago',
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

/// Skeleton loading.
class _SkeletonLoading extends StatelessWidget {
  const _SkeletonLoading();

  @override
  Widget build(BuildContext context) {
    final skeletonColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _SkeletonCard(height: 110, color: skeletonColor),
          const SizedBox(height: 12),
          _SkeletonCard(height: 110, color: skeletonColor),
          const SizedBox(height: 12),
          _SkeletonCard(height: 110, color: skeletonColor),
          const SizedBox(height: 16),
          _SkeletonCard(height: 200, color: skeletonColor),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
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
          Text('Erreur: $error'),
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

/// Formate un timestamp ISO en date lisible.
String _formatDate(String isoDate) {
  try {
    final dt = DateTime.parse(isoDate);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  } catch (_) {
    return isoDate;
  }
}
