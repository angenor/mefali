import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';
import '../theme/mefali_custom_colors.dart';

/// Carte de mission de livraison pour le livreur (UX-DR5).
/// Affiche : restaurant, destination, distance, gain, timer 30s, bouton ACCEPTER.
class DeliveryMissionCard extends StatefulWidget {
  const DeliveryMissionCard({
    required this.mission,
    required this.onAccept,
    this.onRefuse,
    this.onDismiss,
    this.isLoading = false,
    this.autoDismissSeconds = 30,
    super.key,
  });

  final DeliveryMission mission;
  final VoidCallback onAccept;
  final VoidCallback? onRefuse;
  final VoidCallback? onDismiss;
  final bool isLoading;
  final int autoDismissSeconds;

  @override
  State<DeliveryMissionCard> createState() => _DeliveryMissionCardState();
}

class _DeliveryMissionCardState extends State<DeliveryMissionCard> {
  late int _secondsRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.autoDismissSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsRemaining <= 1) {
        _timer?.cancel();
        widget.onDismiss?.call();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  @override
  void didUpdateWidget(DeliveryMissionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final m = widget.mission;

    final distanceText = m.estimatedDistanceM != null
        ? '~${(m.estimatedDistanceM! / 1000).toStringAsFixed(1)} km'
        : null;

    final gainText = formatFcfa(m.deliveryFee);
    final progress = _secondsRemaining / widget.autoDismissSeconds;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Restaurant name
            Text(
              m.merchantName,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (m.merchantAddress != null)
              Text(
                m.merchantAddress!,
                style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: 8),

            // Arrow separator
            Icon(Icons.arrow_downward, color: colorScheme.onSurfaceVariant, size: 20),

            const SizedBox(height: 8),

            // Delivery address
            Text(
              m.deliveryAddress ?? 'Adresse inconnue',
              style: textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (distanceText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(distanceText, style: textTheme.bodySmall),
              ),

            const SizedBox(height: 16),

            // Gain (delivery fee) — big green text (success color from theme)
            Center(
              child: Text(
                gainText,
                style: textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).extension<MefaliCustomColors>()?.success
                      ?? const Color(0xFF4CAF50),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Items summary
            Text(
              m.itemsSummary,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Timer progress bar + countdown
            LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              '${_secondsRemaining}s',
              style: textTheme.bodySmall,
              textAlign: TextAlign.end,
            ),

            const SizedBox(height: 12),

            // ACCEPTER button — full width, 56dp (driver in motion)
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: widget.isLoading ? null : widget.onAccept,
                child: widget.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'ACCEPTER',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            if (widget.onRefuse != null) ...[
              const SizedBox(height: 8),

              // REFUSER button — secondary, smaller (avoid accidental taps)
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: widget.isLoading ? null : widget.onRefuse,
                  child: const Text('REFUSER'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
