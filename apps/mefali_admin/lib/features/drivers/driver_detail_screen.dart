import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Ecran detail/historique d'un livreur pour l'admin.
class DriverDetailScreen extends ConsumerStatefulWidget {
  const DriverDetailScreen({super.key, required this.driverId});

  final String driverId;

  @override
  ConsumerState<DriverDetailScreen> createState() =>
      _DriverDetailScreenState();
}

class _DriverDetailScreenState extends ConsumerState<DriverDetailScreen> {
  int _page = 1;

  DriverHistoryParams get _params =>
      DriverHistoryParams(driverId: widget.driverId, page: _page);

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(driverHistoryProvider(_params));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique livreur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraichir',
            onPressed: () => ref.invalidate(driverHistoryProvider(_params)),
          ),
        ],
      ),
      body: asyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (history) {
          final d = history.driver;
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
                        Text(d.name ?? 'Livreur',
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('Telephone: ${d.phone}'),
                        Text('Statut: ${d.status.name}'),
                        Text('KYC: ${d.kycStatus ?? "non soumis"}'),
                        if (d.sponsorName != null)
                          Text('Sponsor: ${d.sponsorName}'),
                        Row(
                          children: [
                            const Text('Disponible: '),
                            Icon(
                              d.available
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color:
                                  d.available ? Colors.green : Colors.grey,
                              size: 20,
                            ),
                          ],
                        ),
                        Text(
                          'Inscrit le ${d.createdAt.day.toString().padLeft(2, "0")}/${d.createdAt.month.toString().padLeft(2, "0")}/${d.createdAt.year}',
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
                      label: 'Livraisons',
                      value: '${s.totalDeliveries}',
                      icon: Icons.moped,
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
                // Recent deliveries
                Text('Livraisons recentes',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (history.recentDeliveries.items.isEmpty)
                  const Text('Aucune livraison')
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                    showCheckboxColumn: false,
                    columns: const [
                      DataColumn(label: Text('Statut')),
                      DataColumn(label: Text('Marchand')),
                      DataColumn(label: Text('Date livraison')),
                    ],
                    rows: history.recentDeliveries.items.map((dl) {
                      return DataRow(cells: [
                        DataCell(Text(dl.status)),
                        DataCell(Text(dl.merchantName ?? '-')),
                        DataCell(Text(
                          dl.deliveredAt != null
                              ? '${dl.deliveredAt!.day.toString().padLeft(2, "0")}/${dl.deliveredAt!.month.toString().padLeft(2, "0")} ${dl.deliveredAt!.hour.toString().padLeft(2, "0")}:${dl.deliveredAt!.minute.toString().padLeft(2, "0")}'
                              : '-',
                        )),
                      ]);
                    }).toList(),
                    ),
                  ),
                _buildPagination(history.recentDeliveries.total),
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
