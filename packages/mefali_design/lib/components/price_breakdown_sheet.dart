import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

import 'payment_method_selector.dart';

/// Recapitulatif transparent des prix (UX-DR9).
/// Affiche articles + livraison + total, le total etant le texte le plus gros.
class PriceBreakdownSheet extends StatefulWidget {
  const PriceBreakdownSheet({
    required this.items,
    required this.deliveryFee,
    required this.onIncrement,
    required this.onDecrement,
    required this.onOrder,
    this.isOrdering = false,
    super.key,
  });

  final List<CartItem> items;

  /// Frais de livraison en centimes FCFA.
  final int deliveryFee;
  final void Function(String productId) onIncrement;
  final void Function(String productId) onDecrement;
  final void Function(String paymentType) onOrder;
  final bool isOrdering;

  @override
  State<PriceBreakdownSheet> createState() => _PriceBreakdownSheetState();
}

class _PriceBreakdownSheetState extends State<PriceBreakdownSheet> {
  String _paymentMethod = 'cod';

  int get _subtotal => widget.items.fold(0, (sum, item) => sum + item.totalPrice);
  int get _total => _subtotal + widget.deliveryFee;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Text(
              'Votre commande',
              style: textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Item list
            for (final item in widget.items)
              _CartItemRow(
                item: item,
                onIncrement: () => widget.onIncrement(item.product.id),
                onDecrement: () => widget.onDecrement(item.product.id),
              ),
            const Divider(height: 24),
            // Sous-total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sous-total', style: textTheme.bodyMedium),
                Text(formatFcfa(_subtotal), style: textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 8),
            // Livraison
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Livraison', style: textTheme.bodyMedium),
                Text(formatFcfa(widget.deliveryFee), style: textTheme.bodyMedium),
              ],
            ),
            const Divider(height: 24),
            // TOTAL — biggest text on screen (UX-DR9)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL',
                  style: textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatFcfa(_total),
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Payment method selector (story 4.4)
            PaymentMethodSelector(
              selectedMethod: _paymentMethod,
              onChanged: (value) => setState(() => _paymentMethod = value),
            ),
            const SizedBox(height: 16),
            // Order button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.isOrdering
                    ? null
                    : () => widget.onOrder(_paymentMethod),
                child: widget.isOrdering
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Text('Confirmer — ${formatFcfa(_total)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Quantity controls
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 24,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: onDecrement,
            color: colorScheme.primary,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 24,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: onIncrement,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          // Product name
          Expanded(
            child: Text(item.product.name, style: textTheme.bodyMedium),
          ),
          // Line total
          Text(
            formatFcfa(item.totalPrice),
            style: textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Skeleton variant pour le PriceBreakdownSheet (UX-DR14).
class PriceBreakdownSheetSkeleton extends StatefulWidget {
  const PriceBreakdownSheetSkeleton({super.key});

  @override
  State<PriceBreakdownSheetSkeleton> createState() =>
      _PriceBreakdownSheetSkeletonState();
}

class _PriceBreakdownSheetSkeletonState
    extends State<PriceBreakdownSheetSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Color?> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colorScheme = Theme.of(context).colorScheme;
    _animation = ColorTween(
      begin: colorScheme.surfaceContainerHighest.withAlpha(100),
      end: colorScheme.surfaceContainerHighest.withAlpha(40),
    ).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _skeletonBox(40, 4),
                const SizedBox(height: 16),
                _skeletonBox(120, 18),
                const SizedBox(height: 16),
                for (var i = 0; i < 3; i++) ...[
                  _skeletonRow(),
                  const SizedBox(height: 8),
                ],
                const Divider(height: 24),
                _skeletonRow(),
                const Divider(height: 24),
                _skeletonRow(height: 28),
                const SizedBox(height: 24),
                _skeletonBox(double.infinity, 48),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _skeletonBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _animation.value,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _skeletonRow({double height = 18}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _skeletonBox(120, height),
        _skeletonBox(80, height),
      ],
    );
  }
}
