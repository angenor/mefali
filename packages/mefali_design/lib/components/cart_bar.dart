import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

/// Barre panier sticky en bas de l'ecran catalogue (story 4.2).
class CartBar extends StatelessWidget {
  const CartBar({
    required this.itemCount,
    required this.totalPrice,
    required this.onTap,
    super.key,
  });

  final int itemCount;

  /// Prix total en centimes FCFA.
  final int totalPrice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.primary,
      child: InkWell(
        onTap: onTap,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '$itemCount article${itemCount > 1 ? 's' : ''} — ${formatFcfa(totalPrice)}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                Text(
                  'Commander',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
