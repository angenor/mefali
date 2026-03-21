import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

import 'rating_sheet_consumer.dart';

/// Ecran liste des commandes du client (story 4.4, AC5).
class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(customerOrdersProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes commandes')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerOrdersProvider);
          await ref.read(customerOrdersProvider.future);
        },
        child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBody(
            onRetry: () => ref.invalidate(customerOrdersProvider),
          ),
          data: (orders) {
            if (orders.isEmpty) {
              return const _EmptyBody();
            }

            final active = orders
                .where((o) =>
                    o.status != OrderStatus.delivered &&
                    o.status != OrderStatus.cancelled)
                .toList();
            final past = orders
                .where((o) =>
                    o.status == OrderStatus.delivered ||
                    o.status == OrderStatus.cancelled)
                .take(20)
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active.isNotEmpty) ...[
                  Text(
                    'En cours',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (final order in active)
                    OrderListItem(
                      order: order,
                      onTap: () =>
                          context.push('/order/tracking/${order.id}'),
                    ),
                  const SizedBox(height: 24),
                ],
                if (past.isNotEmpty) ...[
                  Text(
                    'Historique',
                    style: textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  for (final order in past)
                    OrderListItem(order: order),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class OrderListItem extends ConsumerWidget {
  const OrderListItem({required this.order, this.onTap, super.key});

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    // Check if delivered order has been rated
    final bool isDelivered = order.status == OrderStatus.delivered;
    final ratingAsync = isDelivered
        ? ref.watch(orderRatingProvider(order.id))
        : null;
    final bool hasRating = ratingAsync?.whenOrNull(data: (r) => r) != null;
    final bool canRate = isDelivered && !hasRating;

    // Check dispute status for delivered orders
    final disputeAsync = isDelivered
        ? ref.watch(orderDisputeProvider(order.id))
        : null;
    final dispute = disputeAsync?.whenOrNull(data: (d) => d);
    final bool hasDispute = dispute != null;
    final bool canReport = isDelivered && !hasDispute;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                children: [
                  // Status icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: order.status.color.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      order.status.icon,
                      color: order.status.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Order info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.merchantName ?? '#${order.id.substring(0, 8).toUpperCase()}',
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.items.length} article${order.items.length > 1 ? 's' : ''} · ${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Total and status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatFcfa(order.total),
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: order.status.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          order.status.label,
                          style: textTheme.labelSmall?.copyWith(
                            color: order.status.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ],
              ),
              // Rate button for delivered orders without rating
              if (canRate) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _showRatingSheet(context, ref),
                    icon: const Icon(Icons.star_outline_rounded, size: 18),
                    label: const Text('Noter'),
                  ),
                ),
              ],
              // Dispute badge
              if (hasDispute) ...[
                const SizedBox(height: 8),
                _DisputeBadge(status: dispute.status),
              ],
              // Report problem button (only if no dispute yet)
              if (canReport) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 36,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDisputeSheet(context, ref),
                    icon: const Icon(Icons.report_problem_outlined, size: 18),
                    label: const Text('Signaler un probleme'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error.withAlpha(120),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDisputeSheet(BuildContext context, WidgetRef ref) {
    var isLoading = false;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => DisputeReportSheet(
          isLoading: isLoading,
          onSubmit: ({required disputeType, description}) async {
            setSheetState(() => isLoading = true);
            try {
              final endpoint = DisputeEndpoint(ref.read(dioProvider));
              await endpoint.createDispute(
                order.id,
                CreateDisputeRequest(
                  disputeType: disputeType,
                  description: description,
                ),
              );
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
              ref.invalidate(orderDisputeProvider(order.id));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Votre signalement a ete envoye. Nous reviendrons vers vous.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } on DioException catch (e) {
              setSheetState(() => isLoading = false);
              final statusCode = e.response?.statusCode;
              if (statusCode == 409 && context.mounted) {
                Navigator.of(sheetContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Vous avez deja signale un probleme pour cette commande',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  void _showRatingSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => RatingSheetConsumer(
        orderId: order.id,
        merchantName: order.merchantName ?? 'Le restaurant',
        driverName: 'Le livreur',
        onDone: () {
          Navigator.of(sheetContext).pop();
          ref.invalidate(orderRatingProvider(order.id));
        },
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long,
              size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Aucune commande',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Vos commandes apparaitront ici',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisputeBadge extends StatelessWidget {
  const _DisputeBadge({required this.status});

  final DisputeStatus status;

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (status) {
      DisputeStatus.open => (Colors.orange, Icons.schedule),
      DisputeStatus.inProgress => (Colors.blue, Icons.hourglass_top),
      DisputeStatus.resolved => (Colors.green, Icons.check_circle_outline),
      DisputeStatus.closed => (Colors.grey, Icons.cancel_outlined),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: Icon(icon, size: 16, color: color),
        label: Text(
          status.label,
          style: TextStyle(color: color, fontSize: 12),
        ),
        backgroundColor: color.withAlpha(25),
        side: BorderSide.none,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Impossible de charger les commandes',
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
        ],
      ),
    );
  }
}
