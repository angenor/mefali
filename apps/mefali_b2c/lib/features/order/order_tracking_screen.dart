import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

/// Ecran de suivi de commande active (story 4.4, AC4).
class OrderTrackingScreen extends ConsumerStatefulWidget {
  const OrderTrackingScreen({
    required this.orderId,
    super.key,
  });

  final String orderId;

  @override
  ConsumerState<OrderTrackingScreen> createState() =>
      _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidate(orderProvider(widget.orderId)),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suivi de commande'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(orderProvider(widget.orderId));
          // Wait for the provider to refresh
          await ref.read(orderProvider(widget.orderId).future);
        },
        child: orderAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorBody(
            onRetry: () => ref.invalidate(orderProvider(widget.orderId)),
          ),
          data: (order) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Order header
              _OrderHeader(order: order),
              const SizedBox(height: 24),
              // Status timeline
              _StatusTimeline(currentStatus: order.status),
              const SizedBox(height: 24),
              // Order summary
              _OrderSummary(order: order),
              const SizedBox(height: 16),
              // Call restaurant button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _callRestaurant,
                  icon: const Icon(Icons.phone),
                  label: const Text('Appeler le restaurant'),
                ),
              ),
              const SizedBox(height: 16),
              // Return home
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Retour a l\'accueil'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callRestaurant() async {
    // Placeholder: in a real scenario, merchant phone would be in the order data
    // For now, show a snackbar
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Numero du restaurant non disponible pour le moment'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          order.status.icon,
          size: 48,
          color: order.status.color,
        ),
        const SizedBox(height: 8),
        Text(
          order.status.label,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: order.status.color,
          ),
        ),
        const SizedBox(height: 4),
        if (order.merchantName != null)
          Text(
            order.merchantName!,
            style: textTheme.titleSmall,
          ),
        const SizedBox(height: 2),
        Text(
          'Commande #${order.id.substring(0, 8).toUpperCase()}',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Timeline verticale des etapes de commande.
class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.currentStatus});

  final OrderStatus currentStatus;

  static const _steps = [
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.preparing,
    OrderStatus.ready,
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    var currentIndex = _steps.indexOf(currentStatus);
    // Post-ready statuses (collected, inTransit, delivered): all steps done
    if (currentIndex < 0 && currentStatus != OrderStatus.cancelled) {
      currentIndex = _steps.length;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progression',
              style:
                  textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < _steps.length; i++) ...[
              _TimelineStep(
                status: _steps[i],
                isPast: i < currentIndex,
                isCurrent: i == currentIndex,
                isFuture: i > currentIndex,
                isLast: i == _steps.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.status,
    required this.isPast,
    required this.isCurrent,
    required this.isFuture,
    required this.isLast,
  });

  final OrderStatus status;
  final bool isPast;
  final bool isCurrent;
  final bool isFuture;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final color = isFuture
        ? colorScheme.onSurfaceVariant.withAlpha(80)
        : status.color;

    final icon = isPast ? Icons.check_circle : status.icon;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, size: 24, color: color),
            if (!isLast)
              Container(
                width: 2,
                height: 24,
                color: isFuture
                    ? colorScheme.onSurfaceVariant.withAlpha(40)
                    : color,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              status.label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isFuture
                    ? colorScheme.onSurfaceVariant.withAlpha(120)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recapitulatif',
              style:
                  textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (order.items.isNotEmpty)
              for (final item in order.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${item.productName ?? 'Article'} x${item.quantity}',
                        style: textTheme.bodyMedium,
                      ),
                      Text(formatFcfa(item.lineTotal),
                          style: textTheme.bodyMedium),
                    ],
                  ),
                ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Livraison', style: textTheme.bodyMedium),
                Text(formatFcfa(order.deliveryFee), style: textTheme.bodyMedium),
              ],
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatFcfa(order.total),
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.payments_outlined, size: 16,
                    color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Cash a la livraison',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline, size: 64, color: colorScheme.error),
        const SizedBox(height: 16),
        Text(
          'Impossible de charger la commande',
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reessayer'),
          ),
        ),
      ],
    );
  }
}
