import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

/// Ecran principal du mode demo B2B.
///
/// Reproduit le layout du HomeScreen avec tabs Commandes | Catalogue | Stats
/// mais avec des donnees fictives locales. Aucun appel API.
class DemoScreen extends ConsumerStatefulWidget {
  const DemoScreen({super.key});

  @override
  ConsumerState<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends ConsumerState<DemoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _exitDemo() {
    ref.read(demoProvider.notifier).exitDemo();
    context.go('/auth/phone');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chez Dramane'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'DEMO',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        actions: [
          // Statut "Ouvert" non interactif
          const VendorStatusIndicator(
            status: VendorStatus.open,
            interactive: false,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Quitter la demo',
            onPressed: _exitDemo,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Commandes'),
            Tab(text: 'Catalogue'),
            Tab(text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DemoOrdersTab(),
          _DemoCatalogueTab(),
          _DemoStatsTab(),
        ],
      ),
    );
  }
}

/// Tab Commandes : affiche un etat vide ou la commande demo.
class _DemoOrdersTab extends ConsumerWidget {
  const _DemoOrdersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demoState = ref.watch(demoProvider);

    return switch (demoState.phase) {
      DemoPhase.inactive || DemoPhase.active => const _DemoOrdersEmpty(),
      DemoPhase.orderArriving => const _DemoOrderArriving(),
      DemoPhase.orderIncoming => _DemoOrderCard(
          order: demoState.order!,
          onAccept: () => ref.read(demoProvider.notifier).acceptOrder(),
        ),
      DemoPhase.orderAccepted => _DemoOrderCard(
          order: demoState.order!,
          onReady: () => ref.read(demoProvider.notifier).markReady(),
        ),
      DemoPhase.orderReady => _DemoOrderCard(order: demoState.order!),
      DemoPhase.orderDelivered => _DemoOrderDelivered(
          order: demoState.order!,
          onReset: () => ref.read(demoProvider.notifier).resetCycle(),
        ),
    };
  }
}

/// Etat vide avec bouton "Simuler une commande".
class _DemoOrdersEmpty extends ConsumerWidget {
  const _DemoOrdersEmpty();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
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
            'Aucune commande pour le moment',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: () => ref.read(demoProvider.notifier).simulateOrder(),
              icon: const Icon(Icons.notifications_active),
              label: const Text(
                'Simuler une commande',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Indicateur d'arrivee de commande (timer 3s).
class _DemoOrderArriving extends StatelessWidget {
  const _DemoOrderArriving();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          Text(
            'Un client passe commande...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

/// OrderCard demo avec actions contextuelles.
class _DemoOrderCard extends StatelessWidget {
  const _DemoOrderCard({
    required this.order,
    this.onAccept,
    this.onReady,
  });

  final Order order;
  final VoidCallback? onAccept;
  final VoidCallback? onReady;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (order.status == OrderStatus.pending)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              color: const Color(0xFFFF9800).withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active,
                        color: Color(0xFFFF9800)),
                    const SizedBox(width: 8),
                    Text(
                      'Nouvelle commande !',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFFFF9800),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        OrderCard(
          order: order,
          onAccept: onAccept,
          onReady: onReady,
        ),
      ],
    );
  }
}

/// Ecran de livraison reussie avec option de relancer.
class _DemoOrderDelivered extends StatelessWidget {
  const _DemoOrderDelivered({
    required this.order,
    required this.onReset,
  });

  final Order order;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<MefaliCustomColors>();
    final successColor = customColors?.success ?? const Color(0xFF4CAF50);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: successColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 64, color: successColor),
                const SizedBox(height: 12),
                Text(
                  'Livree !',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: successColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${order.totalFormatted} credite sur votre wallet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        OrderCard(order: order),
        const SizedBox(height: 16),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.replay),
            label: const Text('Relancer la demo'),
          ),
        ),
      ],
    );
  }
}

/// Tab Catalogue : liste des 4 produits fictifs.
class _DemoCatalogueTab extends StatelessWidget {
  const _DemoCatalogueTab();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: DemoData.products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = DemoData.products[index];
        return _DemoProductCard(product: product);
      },
    );
  }
}

/// Carte produit demo.
class _DemoProductCard extends StatelessWidget {
  const _DemoProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          radius: 28,
          child: Icon(
            _productIcon(product.name),
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          product.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('Stock: ${product.stock}'),
        trailing: Text(
          formatFcfa(product.price),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  IconData _productIcon(String name) {
    return switch (name) {
      'Garba' => Icons.lunch_dining,
      'Alloco-Poisson' => Icons.set_meal,
      'Attieke-Poisson' => Icons.restaurant,
      'Jus Bissap' => Icons.local_drink,
      _ => Icons.fastfood,
    };
  }
}

/// Tab Stats : dashboard fictif.
class _DemoStatsTab extends StatelessWidget {
  const _DemoStatsTab();

  @override
  Widget build(BuildContext context) {
    const stats = DemoData.weeklySales;
    final current = stats.currentWeek;
    final previous = stats.previousWeek;
    final customColors = Theme.of(context).extension<MefaliCustomColors>();
    final successColor = customColors?.success ?? const Color(0xFF4CAF50);

    final salesGrowth = _growthPercent(current.totalSales, previous.totalSales);
    final orderGrowth = _growthPercent(current.orderCount, previous.orderCount);
    final salesIsPositive = salesGrowth >= 0;
    final orderIsPositive = orderGrowth >= 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Cartes resume
        Row(
          children: [
            Expanded(
              child: _DemoStatCard(
                label: 'Total ventes',
                value: formatFcfa(current.totalSales),
                growth: salesGrowth,
                isPositive: salesIsPositive,
                successColor: successColor,
                errorColor: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DemoStatCard(
                label: 'Commandes',
                value: '${current.orderCount}',
                growth: orderGrowth,
                isPositive: orderIsPositive,
                successColor: successColor,
                errorColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Comparaison
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comparaison',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                _DemoComparisonRow(
                  label: 'Semaine courante',
                  amount: formatFcfa(current.totalSales),
                  orders: '${current.orderCount} cmd',
                  isCurrent: true,
                ),
                const Divider(height: 16),
                _DemoComparisonRow(
                  label: 'Semaine precedente',
                  amount: formatFcfa(previous.totalSales),
                  orders: '${previous.orderCount} cmd',
                  isCurrent: false,
                ),
                const Divider(height: 16),
                Row(
                  children: [
                    Text('Croissance',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const Spacer(),
                    Text(
                      '+${salesGrowth.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: successColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Repartition produits
        if (stats.productBreakdown.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Repartition par produit',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 12),
                  ...stats.productBreakdown.asMap().entries.map((entry) {
                    final product = entry.value;
                    final isTop = entry.key == 0;
                    return _DemoProductRow(product: product, isTop: isTop);
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Carte stat demo.
class _DemoStatCard extends StatelessWidget {
  const _DemoStatCard({
    required this.label,
    required this.value,
    required this.growth,
    required this.isPositive,
    required this.successColor,
    required this.errorColor,
  });

  final String label;
  final String value;
  final double growth;
  final bool isPositive;
  final Color successColor;
  final Color errorColor;

  @override
  Widget build(BuildContext context) {
    final growthColor = isPositive ? successColor : errorColor;

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

/// Ligne de comparaison demo.
class _DemoComparisonRow extends StatelessWidget {
  const _DemoComparisonRow({
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

/// Ligne produit demo avec barre de progression.
class _DemoProductRow extends StatelessWidget {
  const _DemoProductRow({required this.product, required this.isTop});

  final ProductSales product;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isTop ? Theme.of(context).colorScheme.primaryContainer : null,
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
                formatFcfa(product.revenue),
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
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

double _growthPercent(int current, int previous) {
  if (previous == 0) return current > 0 ? 100.0 : 0.0;
  return ((current - previous) / previous) * 100.0;
}
