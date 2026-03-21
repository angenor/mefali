import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Ecran detail/historique d'un marchand pour l'admin.
class MerchantDetailScreen extends ConsumerStatefulWidget {
  const MerchantDetailScreen({super.key, required this.merchantId});

  final String merchantId;

  @override
  ConsumerState<MerchantDetailScreen> createState() =>
      _MerchantDetailScreenState();
}

class _MerchantDetailScreenState extends ConsumerState<MerchantDetailScreen> {
  int _page = 1;

  MerchantHistoryParams get _params =>
      MerchantHistoryParams(merchantId: widget.merchantId, page: _page);

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(merchantHistoryProvider(_params));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique marchand'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraichir',
            onPressed: () => ref.invalidate(merchantHistoryProvider(_params)),
          ),
        ],
      ),
      body: asyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (history) {
          final m = history.merchant;
          final s = history.stats;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profil card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.name, style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        if (m.address != null)
                          Text('Adresse: ${m.address}'),
                        Text('Categorie: ${m.category ?? "-"}'),
                        Row(
                          children: [
                            const Text('Statut: '),
                            Chip(
                              label: Text(m.status.label),
                              backgroundColor:
                                  m.status.color.withValues(alpha: 0.2),
                              labelStyle: TextStyle(color: m.status.color),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        Text('KYC: ${m.kycStatus ?? "non soumis"}'),
                        Text(
                          'Inscrit le ${m.createdAt.day.toString().padLeft(2, "0")}/${m.createdAt.month.toString().padLeft(2, "0")}/${m.createdAt.year}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats cards
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      label: 'Commandes',
                      value: '${s.totalOrders}',
                      icon: Icons.receipt_long,
                    ),
                    _StatCard(
                      label: 'Taux completion',
                      value: '${s.completionRate}%',
                      icon: Icons.check_circle,
                    ),
                    _StatCard(
                      label: 'Note moyenne',
                      value: s.avgRating.toStringAsFixed(1),
                      icon: Icons.star,
                    ),
                    _StatCard(
                      label: 'Litiges',
                      value: '${s.totalDisputes}',
                      icon: Icons.warning_amber,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Recent orders
                Text('Commandes recentes',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (history.recentOrders.items.isEmpty)
                  const Text('Aucune commande')
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Total'), numeric: true),
                      DataColumn(label: Text('Client')),
                      DataColumn(label: Text('Date')),
                    ],
                    rows: history.recentOrders.items.map((o) {
                      return DataRow(cells: [
                        DataCell(Text(o.status)),
                        DataCell(Text('${o.total} FCFA')),
                        DataCell(Text(o.customerName ?? '-')),
                        DataCell(Text(
                          '${o.createdAt.day.toString().padLeft(2, "0")}/${o.createdAt.month.toString().padLeft(2, "0")} ${o.createdAt.hour.toString().padLeft(2, "0")}:${o.createdAt.minute.toString().padLeft(2, "0")}',
                        )),
                      ]);
                    }).toList(),
                    ),
                  ),
                _buildPagination(history.recentOrders.total),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPagination(int total) {
    final totalPages = (total / 10).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _page > 1
                ? () => setState(() => _page--)
                : null,
          ),
          Text('Page $_page / $totalPages'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < totalPages
                ? () => setState(() => _page++)
                : null,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 28, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineSmall),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
