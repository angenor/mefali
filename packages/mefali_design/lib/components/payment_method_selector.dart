import 'package:flutter/material.dart';

/// Selecteur de mode de paiement.
/// COD pre-selectionne, Mobile Money actif.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    required this.selectedMethod,
    required this.onChanged,
    super.key,
  });

  final String selectedMethod;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            'Mode de paiement',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        _PaymentOption(
          label: 'Cash a la livraison',
          isSelected: selectedMethod == 'cod',
          onTap: () => onChanged('cod'),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        _PaymentOption(
          label: 'Mobile Money',
          isSelected: selectedMethod == 'mobile_money',
          onTap: () => onChanged('mobile_money'),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.label,
    required this.isSelected,
    required this.textTheme,
    required this.colorScheme,
    this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
