import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

import 'dispute_status_color.dart';

/// Ecran detail d'un litige pour l'admin.
class DisputeDetailScreen extends ConsumerWidget {
  const DisputeDetailScreen({super.key, required this.disputeId});

  final String disputeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDetail = ref.watch(disputeDetailProvider(disputeId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail du litige')),
      body: asyncDetail.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => Center(
          child: Text('Erreur: $e', style: theme.textTheme.bodyLarge),
        ),
        data: (detail) => _DetailContent(detail: detail, disputeId: disputeId),
      ),
    );
  }
}

class _DetailContent extends ConsumerWidget {
  const _DetailContent({required this.detail, required this.disputeId});

  final DisputeDetail detail;
  final String disputeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dispute = detail.dispute;
    final isResolvable =
        dispute.status == DisputeStatus.open ||
        dispute.status == DisputeStatus.inProgress;
    final statusColor = disputeStatusColor(dispute.status);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: type + status + date
                Row(
                  children: [
                    Icon(Icons.report_problem, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dispute.disputeType.label,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    Chip(
                      label: Text(
                        dispute.status.label,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                        ),
                      ),
                      side: BorderSide(color: statusColor),
                      backgroundColor:
                          statusColor.withValues(alpha: 0.1),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description du litige
                if (dispute.description != null &&
                    dispute.description!.isNotEmpty) ...[
                  Text('Description du client',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(dispute.description!),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Resolution (si resolue)
                if (dispute.resolution != null &&
                    dispute.resolution!.isNotEmpty) ...[
                  Text('Resolution', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(dispute.resolution!),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Timeline
                OrderTimeline(events: detail.timeline),
                const SizedBox(height: 20),

                // Stats marchand
                Text('Historique marchand',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _StatsCard(
                  icon: Icons.store,
                  name: detail.merchantStats.name ?? 'Marchand',
                  stats: [
                    '${detail.merchantStats.totalOrders} commandes',
                    '${detail.merchantStats.totalDisputes} litiges',
                  ],
                ),
                const SizedBox(height: 12),

                // Stats livreur
                if (detail.driverStats != null) ...[
                  Text('Historique livreur',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _StatsCard(
                    icon: Icons.moped,
                    name: detail.driverStats!.name ?? 'Livreur',
                    stats: [
                      '${detail.driverStats!.totalOrders} livraisons',
                      '${detail.driverStats!.totalDisputes} litiges',
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bouton resoudre
        if (isResolvable)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => _showResolutionSheet(context, ref),
                  child: const Text('Resoudre ce litige'),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showResolutionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DisputeResolutionSheet(
        onSubmit: ({
          required ResolveAction action,
          required String resolution,
          int? creditAmount,
        }) async {
          try {
            final endpoint = ref.read(adminEndpointProvider);
            await endpoint.resolveDispute(
              disputeId,
              ResolveDisputeRequest(
                action: action,
                resolution: resolution,
                creditAmount: creditAmount,
              ),
            );

            if (context.mounted) {
              Navigator.of(ctx).pop(); // fermer bottom sheet
              Navigator.of(context).pop(); // retour a la liste

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Litige resolu avec succes'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );

              // Invalider les providers pour rafraichir
              ref.invalidate(disputeDetailProvider(disputeId));
              ref.invalidate(adminDisputesProvider);
              ref.invalidate(adminDashboardProvider);
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: $e'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 10),
                  action: SnackBarAction(
                    label: 'Fermer',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.icon,
    required this.name,
    required this.stats,
  });

  final IconData icon;
  final String name;
  final List<String> stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: theme.textTheme.titleSmall),
                  ...stats.map(
                    (s) => Text(s, style: theme.textTheme.bodySmall),
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

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Container(width: 160, height: 20, color: color),
              const Spacer(),
              Container(width: 70, height: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14))),
            ],
          ),
          const SizedBox(height: 24),
          Container(width: 140, height: 14, color: color),
          const SizedBox(height: 8),
          Container(height: 60, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 24),
          Container(width: 160, height: 16, color: color),
          const SizedBox(height: 12),
          for (var i = 0; i < 4; i++) ...[
            Row(
              children: [
                Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Container(width: 140, height: 14, color: color),
              ],
            ),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 12),
          Container(width: 160, height: 16, color: color),
          const SizedBox(height: 8),
          Container(height: 70, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
          const SizedBox(height: 16),
          Container(width: 140, height: 16, color: color),
          const SizedBox(height: 8),
          Container(height: 70, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12))),
        ],
      ),
    );
  }
}
