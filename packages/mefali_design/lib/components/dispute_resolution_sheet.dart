import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

/// Bottom sheet pour resoudre un litige (admin).
class DisputeResolutionSheet extends StatefulWidget {
  const DisputeResolutionSheet({super.key, required this.onSubmit});

  final Future<void> Function({
    required ResolveAction action,
    required String resolution,
    int? creditAmount,
  }) onSubmit;

  @override
  State<DisputeResolutionSheet> createState() => _DisputeResolutionSheetState();
}

class _DisputeResolutionSheetState extends State<DisputeResolutionSheet> {
  ResolveAction _selectedAction = ResolveAction.dismiss;
  final _resolutionController = TextEditingController();
  final _creditAmountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _resolutionController.dispose();
    _creditAmountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final resolution = _resolutionController.text.trim();
    if (resolution.isEmpty) return;

    int? creditAmount;
    if (_selectedAction == ResolveAction.credit) {
      creditAmount = int.tryParse(_creditAmountController.text.trim());
      if (creditAmount == null || creditAmount <= 0) return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.onSubmit(
        action: _selectedAction,
        resolution: resolution,
        creditAmount: creditAmount,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Resoudre le litige',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Actions
          ...ResolveAction.values.map((action) => RadioListTile<ResolveAction>(
                title: Text(action.label),
                value: action,
                groupValue: _selectedAction,
                onChanged: (v) => setState(() => _selectedAction = v!),
                contentPadding: EdgeInsets.zero,
              )),

          // Montant credit (si action = credit)
          if (_selectedAction == ResolveAction.credit) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _creditAmountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Montant (FCFA)',
                border: OutlineInputBorder(),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Notes de resolution
          TextField(
            controller: _resolutionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes de resolution',
              hintText: 'Decrivez la decision prise...',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 16),

          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirmer la resolution'),
          ),
        ],
      ),
    );
  }
}
