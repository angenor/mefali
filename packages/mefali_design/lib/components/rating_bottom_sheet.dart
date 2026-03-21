import 'package:flutter/material.dart';

/// Bottom sheet pour la double notation marchand + livreur (UX — Story 7.1).
/// Affiche 2 sections d'etoiles interactives et un bouton de soumission.
class RatingBottomSheet extends StatefulWidget {
  const RatingBottomSheet({
    required this.merchantName,
    required this.driverName,
    required this.onSubmit,
    this.isLoading = false,
    super.key,
  });

  final String merchantName;
  final String driverName;
  final void Function({
    required int merchantScore,
    required int driverScore,
    String? merchantComment,
    String? driverComment,
  }) onSubmit;
  final bool isLoading;

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  int _merchantScore = 0;
  int _driverScore = 0;
  final _merchantCommentController = TextEditingController();
  final _driverCommentController = TextEditingController();

  bool get _canSubmit =>
      _merchantScore > 0 && _driverScore > 0 && !widget.isLoading;

  @override
  void dispose() {
    _merchantCommentController.dispose();
    _driverCommentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (!_canSubmit) return;

    final merchantComment = _merchantCommentController.text.trim();
    final driverComment = _driverCommentController.text.trim();

    widget.onSubmit(
      merchantScore: _merchantScore,
      driverScore: _driverScore,
      merchantComment: merchantComment.isEmpty ? null : merchantComment,
      driverComment: driverComment.isEmpty ? null : driverComment,
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
              'Comment c\'etait ?',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Merchant rating section
            _RatingSection(
              label: widget.merchantName,
              score: _merchantScore,
              onScoreChanged: (score) => setState(() => _merchantScore = score),
              commentController: _merchantCommentController,
              hintText: 'Un commentaire ? (optionnel)',
            ),
            const SizedBox(height: 20),
            // Driver rating section
            _RatingSection(
              label: widget.driverName,
              score: _driverScore,
              onScoreChanged: (score) => setState(() => _driverScore = score),
              commentController: _driverCommentController,
              hintText: 'Un commentaire ? (optionnel)',
            ),
            const SizedBox(height: 24),
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
                    : const Text('NOTER'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section de notation : label + etoiles interactives + commentaire optionnel.
class _RatingSection extends StatelessWidget {
  const _RatingSection({
    required this.label,
    required this.score,
    required this.onScoreChanged,
    required this.commentController,
    required this.hintText,
  });

  final String label;
  final int score;
  final ValueChanged<int> onScoreChanged;
  final TextEditingController commentController;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        StarRatingRow(
          score: score,
          onScoreChanged: onScoreChanged,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: commentController,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          maxLines: 2,
          maxLength: 200,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}

/// Row de 5 etoiles interactives pour la notation 1-5.
/// Touch target >= 48dp par etoile.
class StarRatingRow extends StatelessWidget {
  const StarRatingRow({
    required this.score,
    required this.onScoreChanged,
    this.size = 40,
    super.key,
  });

  final int score;
  final ValueChanged<int> onScoreChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final isFilled = starIndex <= score;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onScoreChanged(starIndex),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: isFilled
                  ? colorScheme.primary
                  : colorScheme.onSurface.withAlpha(77),
            ),
          ),
        );
      }),
    );
  }
}
