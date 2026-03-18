import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

/// Ecran dashboard ventes hebdomadaires du marchand.
class SalesDashboardScreen extends ConsumerWidget {
  const SalesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(weeklyStatsProvider);

    return statsAsync.when(
      data: (state) => _DashboardContent(state: state),
      loading: () => const _SkeletonLoading(),
      error: (error, _) => _ErrorState(
        error: error,
        onRetry: () => ref.invalidate(weeklyStatsProvider),
      ),
    );
  }
}

/// Contenu principal du dashboard.
class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.state});

  final WeeklySalesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = state.stats;
    final currentIsEmpty = stats.currentWeek.orderCount == 0;
    final allEmpty = currentIsEmpty && stats.previousWeek.orderCount == 0;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(weeklyStatsProvider),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bandeau offline
          if (state.isCached) _CacheBanner(lastSync: state.lastSync),
          if (allEmpty)
            const _EmptyState()
          else ...[
            _SummaryCards(stats: stats),
            const SizedBox(height: 16),
            _WeekComparison(stats: stats),
            const SizedBox(height: 16),
            if (stats.productBreakdown.isNotEmpty)
              _ProductBreakdown(products: stats.productBreakdown),
            // AC5: encouragement quand semaine courante vide mais precedente a des donnees
            if (currentIsEmpty)
              const _EmptyWeekEncouragement(),
          ],
        ],
      ),
    );
  }
}

/// Bandeau indiquant les donnees en cache.
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
              const Icon(Icons.cloud_off, size: 18, color: MefaliColors.warningLight),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Donnees en cache (il y a $ago). Synchronisation au retour de connexion.',
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

/// Cartes resume : total ventes + nombre commandes.
class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.stats});

  final WeeklySales stats;

  @override
  Widget build(BuildContext context) {
    final current = stats.currentWeek;
    final previous = stats.previousWeek;
    final customColors = Theme.of(context).extension<MefaliCustomColors>();

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Total ventes',
            value: _formatFcfa(current.totalSales),
            growth: _growthPercent(current.totalSales, previous.totalSales),
            successColor: customColors?.success,
            errorColor: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Commandes',
            value: '${current.orderCount}',
            growth: _growthPercent(current.orderCount, previous.orderCount),
            successColor: customColors?.success,
            errorColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}

/// Carte resume individuelle avec indicateur de croissance.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.growth,
    this.successColor,
    this.errorColor,
  });

  final String label;
  final String value;
  final double growth;
  final Color? successColor;
  final Color? errorColor;

  @override
  Widget build(BuildContext context) {
    final isPositive = growth >= 0;
    final growthColor = isPositive
        ? (successColor ?? const Color(0xFF4CAF50))
        : (errorColor ?? const Color(0xFFF44336));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: growthColor,
                ),
                const SizedBox(width: 2),
                Text(
                  '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: growthColor,
                        fontWeight: FontWeight.w600,
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

/// Comparaison semaine courante vs precedente.
class _WeekComparison extends StatelessWidget {
  const _WeekComparison({required this.stats});

  final WeeklySales stats;

  @override
  Widget build(BuildContext context) {
    final current = stats.currentWeek;
    final previous = stats.previousWeek;
    final diff = current.totalSales - previous.totalSales;
    final isPositive = diff >= 0;
    final customColors = Theme.of(context).extension<MefaliCustomColors>();
    final growthColor = isPositive
        ? (customColors?.success ?? const Color(0xFF4CAF50))
        : Theme.of(context).colorScheme.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comparaison', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _ComparisonRow(
              label: 'Semaine courante',
              amount: _formatFcfa(current.totalSales),
              orders: '${current.orderCount} cmd',
              isCurrent: true,
            ),
            const Divider(height: 16),
            _ComparisonRow(
              label: 'Semaine precedente',
              amount: _formatFcfa(previous.totalSales),
              orders: '${previous.orderCount} cmd',
              isCurrent: false,
            ),
            const Divider(height: 16),
            Row(
              children: [
                Text('Croissance', style: Theme.of(context).textTheme.bodyMedium),
                const Spacer(),
                Text(
                  '${isPositive ? '+' : ''}${_formatFcfa(diff)} (${isPositive ? '+' : ''}${_growthPercent(current.totalSales, previous.totalSales).toStringAsFixed(0)}%)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: growthColor,
                        fontWeight: FontWeight.bold,
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

/// Ligne de comparaison (courante ou precedente).
class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.amount,
    required this.orders,
    required this.isCurrent,
  });

  final String label;
  final String amount;
  final String orders;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isCurrent ? FontWeight.w600 : null,
                ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.bold : null,
                  ),
            ),
            Text(orders, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

/// Repartition par produit avec top produit en surbrillance.
class _ProductBreakdown extends StatelessWidget {
  const _ProductBreakdown({required this.products});

  final List<ProductSales> products;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repartition par produit',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            ...products.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return _ProductRow(
                product: product,
                isTop: index == 0,
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Ligne produit avec barre de progression du pourcentage.
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.isTop});

  final ProductSales product;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTop
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  product.productName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                      ),
                ),
              ),
              Text(
                _formatFcfa(product.revenue),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '${product.quantitySold} vendus',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              Text(
                '${product.percentage.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: product.percentage / 100,
              minHeight: 6,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

/// Encouragement compact quand semaine courante vide mais precedente a des donnees.
class _EmptyWeekEncouragement extends StatelessWidget {
  const _EmptyWeekEncouragement();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pas de commandes cette semaine',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Continuez a ameliorer votre catalogue !',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Etat vide : aucune commande cette semaine.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Pas de commandes cette semaine',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Continuez a ameliorer votre catalogue !',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Etat erreur avec bouton reessayer.
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

/// Skeleton loading pour le dashboard.
class _SkeletonLoading extends StatelessWidget {
  const _SkeletonLoading();

  @override
  Widget build(BuildContext context) {
    final skeletonColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Summary cards skeleton
          Row(
            children: [
              Expanded(child: _SkeletonCard(height: 100, color: skeletonColor)),
              const SizedBox(width: 12),
              Expanded(child: _SkeletonCard(height: 100, color: skeletonColor)),
            ],
          ),
          const SizedBox(height: 16),
          // Comparison skeleton
          _SkeletonCard(height: 140, color: skeletonColor),
          const SizedBox(height: 16),
          // Product breakdown skeleton
          _SkeletonCard(height: 200, color: skeletonColor),
        ],
      ),
    );
  }
}

/// Carte skeleton individuelle.
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

// --- Utilitaires ---

/// Formate un montant en centimes vers FCFA avec separateur milliers.
String _formatFcfa(int centimes) {
  final fcfa = (centimes / 100).round();
  final negative = fcfa < 0;
  final str = fcfa.abs().toString();
  final buffer = StringBuffer();
  if (negative) buffer.write('-');
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(str[i]);
  }
  return '${buffer.toString()} FCFA';
}

/// Calcule le pourcentage de croissance entre deux valeurs.
double _growthPercent(int current, int previous) {
  if (previous == 0) return current > 0 ? 100.0 : 0.0;
  return ((current - previous) / previous) * 100.0;
}
