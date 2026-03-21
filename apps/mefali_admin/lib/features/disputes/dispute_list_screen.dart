import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

import 'dispute_detail_screen.dart';
import 'dispute_status_color.dart';

/// Ecran liste des litiges pour l'admin.
class DisputeListScreen extends ConsumerStatefulWidget {
  const DisputeListScreen({super.key});

  @override
  ConsumerState<DisputeListScreen> createState() => _DisputeListScreenState();
}

class _DisputeListScreenState extends ConsumerState<DisputeListScreen> {
  String? _statusFilter;

  static const _statusFilters = [
    (label: 'Tous', value: null),
    (label: 'Ouverts', value: 'open'),
    (label: 'En traitement', value: 'in_progress'),
    (label: 'Resolus', value: 'resolved'),
  ];

  DisputeListParams get _params =>
      DisputeListParams(status: _statusFilter);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncData = ref.watch(adminDisputesProvider(_params));

    return Column(
      children: [
        // Filtres
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusFilters.map((f) {
                final isSelected = f.value == _statusFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _statusFilter = f.value);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Liste
        Expanded(
          child: asyncData.when(
            loading: () => _buildSkeleton(context),
            error: (e, _) => Center(
              child: Text(
                'Erreur de chargement',
                style: theme.textTheme.bodyLarge,
              ),
            ),
            data: (result) {
              if (result.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun litige en attente',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(adminDisputesProvider(_params));
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: result.items.length,
                  itemBuilder: (context, index) {
                    final item = result.items[index];
                    return _DisputeCard(
                      item: item,
                      onTap: () => _openDetail(item.id),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 5,
      itemBuilder: (_, __) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120, height: 14, color: color),
                    const SizedBox(height: 6),
                    Container(width: 80, height: 12, color: color),
                  ],
                ),
              ),
              Container(width: 60, height: 24, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(String disputeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DisputeDetailScreen(disputeId: disputeId),
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  const _DisputeCard({required this.item, required this.onTap});

  final AdminDisputeListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = disputeStatusColor(item.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.report_problem, color: Colors.orange[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.disputeType.label,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.merchantName ?? 'Marchand inconnu',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${item.orderTotal} FCFA',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Chip(
                    label: Text(
                      item.status.label,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: statusColor),
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(item.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    return '$d/$m ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
}

