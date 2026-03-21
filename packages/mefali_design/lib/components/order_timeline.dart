import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

/// Timeline verticale horodatee d'une commande pour resolution litiges admin.
/// Etats: complete (vert), en cours (marron pulsant), futur (gris).
class OrderTimeline extends StatefulWidget {
  const OrderTimeline({super.key, required this.events});

  final List<OrderTimelineEvent> events;

  @override
  State<OrderTimeline> createState() => _OrderTimelineState();
}

class _OrderTimelineState extends State<OrderTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final mo = local.month.toString().padLeft(2, '0');
    return '$h:$m - $d/$mo';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Find the first event without timestamp = "en cours"
    final inProgressIndex = widget.events.indexWhere((e) => e.timestamp == null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Timeline commande', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...List.generate(widget.events.length, (index) {
          final event = widget.events[index];
          final isLast = index == widget.events.length - 1;
          final hasTimestamp = event.timestamp != null;
          final isInProgress = index == inProgressIndex;

          // 3 states: complete (green), in progress (brown), future (grey)
          final Color color;
          final IconData icon;
          if (hasTimestamp) {
            color = const Color(0xFF4CAF50); // vert
            icon = Icons.check_circle;
          } else if (isInProgress) {
            color = const Color(0xFF5D4037); // marron
            icon = Icons.access_time_filled;
          } else {
            color = Colors.grey;
            icon = Icons.radio_button_unchecked;
          }

          Widget iconWidget = Icon(icon, color: color, size: 20);
          if (isInProgress) {
            iconWidget = AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, child) => Opacity(
                opacity: _pulseAnimation.value,
                child: child,
              ),
              child: iconWidget,
            );
          }

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne gauche : dot + ligne
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      iconWidget,
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Contenu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.label,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: hasTimestamp
                                ? null
                                : isInProgress
                                    ? const Color(0xFF5D4037)
                                    : Colors.grey,
                          ),
                        ),
                        if (hasTimestamp)
                          Text(
                            _formatTimestamp(event.timestamp!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        if (isInProgress)
                          Text(
                            'En cours...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF5D4037),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
