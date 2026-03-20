import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Overlay celebratoire affichant "+X FCFA" apres une livraison confirmee.
///
/// Animation scale-up 0->1.0 sur 300ms (easeOutQuart), vibration,
/// auto-dismiss apres 2s avec fade out 500ms.
class WalletCreditFeedback {
  WalletCreditFeedback._();

  /// Affiche le feedback en overlay par-dessus l'ecran courant.
  /// [amount] est en centimes (divise par 100 pour l'affichage FCFA).
  static void show(BuildContext context, int amount) {
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => _WalletCreditOverlay(
        amountFcfa: amount ~/ 100,
        onDismiss: () => entry.remove(),
      ),
    );

    overlay.insert(entry);

    // Vibration haptic
    HapticFeedback.mediumImpact();
  }
}

class _WalletCreditOverlay extends StatefulWidget {
  const _WalletCreditOverlay({
    required this.amountFcfa,
    required this.onDismiss,
  });

  final int amountFcfa;
  final VoidCallback onDismiss;

  @override
  State<_WalletCreditOverlay> createState() => _WalletCreditOverlayState();
}

class _WalletCreditOverlayState extends State<_WalletCreditOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Scale up 0->1 over first 300ms (easeOutQuart)
    _scaleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.12, curve: Curves.easeOutQuart),
      ),
    );

    // Fade out during last 500ms (from 2000ms to 2500ms)
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${widget.amountFcfa} FCFA',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
