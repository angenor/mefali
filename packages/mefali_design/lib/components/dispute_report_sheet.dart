import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

/// Bottom sheet pour signaler un litige sur une commande livree (Story 7.3).
class DisputeReportSheet extends StatefulWidget {
  const DisputeReportSheet({
    required this.onSubmit,
    this.isLoading = false,
    super.key,
  });

  final void Function({
    required DisputeType disputeType,
    String? description,
  }) onSubmit;
  final bool isLoading;

  @override
  State<DisputeReportSheet> createState() => _DisputeReportSheetState();
}

class _DisputeReportSheetState extends State<DisputeReportSheet> {
  DisputeType? _selectedType;
  final _descriptionController = TextEditingController();

  bool get _canSubmit => _selectedType != null && !widget.isLoading;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_canSubmit) return;

    final description = _descriptionController.text.trim();

    widget.onSubmit(
      disputeType: _selectedType!,
      description: description.isEmpty ? null : description,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            Text(
              'Signaler un probleme',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Quel probleme avez-vous rencontre ?',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Dispute type selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DisputeType.values.map((type) {
                final isSelected = _selectedType == type;
                return ChoiceChip(
                  label: Text(type.label),
                  selected: isSelected,
                  onSelected: widget.isLoading
                      ? null
                      : (selected) {
                          setState(() {
                            _selectedType = selected ? type : null;
                          });
                        },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Decrivez le probleme (optionnel)',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              maxLines: 3,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              enabled: !widget.isLoading,
            ),
            const SizedBox(height: 16),
            // Submit button
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _canSubmit ? _handleSubmit : null,
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('ENVOYER LE SIGNALEMENT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
