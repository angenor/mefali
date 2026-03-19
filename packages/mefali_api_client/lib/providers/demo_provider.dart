import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_core/mefali_core.dart';

/// Etats du mode demo.
enum DemoPhase {
  /// Demo non active.
  inactive,

  /// Demo active, en attente de simulation de commande.
  active,

  /// Commande en train d'arriver (timer 3s en cours).
  orderArriving,

  /// Commande arrivee, en attente d'acceptation.
  orderIncoming,

  /// Commande acceptee, en preparation.
  orderAccepted,

  /// Commande prete, livreur en route.
  orderReady,

  /// Commande livree avec succes.
  orderDelivered,
}

/// Etat complet du mode demo.
class DemoState {
  const DemoState({
    this.phase = DemoPhase.inactive,
    this.order,
  });

  final DemoPhase phase;
  final Order? order;

  DemoState copyWith({DemoPhase? phase, Order? order}) {
    return DemoState(
      phase: phase ?? this.phase,
      order: order ?? this.order,
    );
  }
}

/// Notifier gerant les transitions du mode demo.
class DemoNotifier extends Notifier<DemoState> {
  bool _alive = true;

  @override
  DemoState build() {
    ref.onDispose(() => _alive = false);
    return const DemoState();
  }

  /// Active le mode demo.
  void activateDemo() {
    state = const DemoState(phase: DemoPhase.active);
  }

  /// Simule l'arrivee d'une commande apres ~3 secondes.
  Future<void> simulateOrder() async {
    state = state.copyWith(phase: DemoPhase.orderArriving);

    await Future<void>.delayed(const Duration(seconds: 3));

    if (!_alive) return;

    // Jouer le son systeme de notification
    SystemSound.play(SystemSoundType.alert);
    HapticFeedback.heavyImpact();

    final order = DemoData.createDemoOrder();
    state = DemoState(phase: DemoPhase.orderIncoming, order: order);
  }

  /// Accepte la commande demo.
  void acceptOrder() {
    if (state.order == null) return;

    final updatedOrder = Order(
      id: state.order!.id,
      customerId: state.order!.customerId,
      merchantId: state.order!.merchantId,
      status: OrderStatus.confirmed,
      paymentType: state.order!.paymentType,
      paymentStatus: state.order!.paymentStatus,
      subtotal: state.order!.subtotal,
      deliveryFee: state.order!.deliveryFee,
      total: state.order!.total,
      notes: state.order!.notes,
      createdAt: state.order!.createdAt,
      updatedAt: DateTime.now(),
      items: state.order!.items,
    );

    state = DemoState(phase: DemoPhase.orderAccepted, order: updatedOrder);
  }

  /// Marque la commande comme prete, puis simule la livraison apres ~3s.
  Future<void> markReady() async {
    if (state.order == null) return;

    final readyOrder = Order(
      id: state.order!.id,
      customerId: state.order!.customerId,
      merchantId: state.order!.merchantId,
      status: OrderStatus.ready,
      paymentType: state.order!.paymentType,
      paymentStatus: state.order!.paymentStatus,
      subtotal: state.order!.subtotal,
      deliveryFee: state.order!.deliveryFee,
      total: state.order!.total,
      notes: state.order!.notes,
      createdAt: state.order!.createdAt,
      updatedAt: DateTime.now(),
      items: state.order!.items,
    );

    state = DemoState(phase: DemoPhase.orderReady, order: readyOrder);

    await Future<void>.delayed(const Duration(seconds: 3));

    if (!_alive) return;

    HapticFeedback.mediumImpact();

    final deliveredOrder = Order(
      id: state.order!.id,
      customerId: state.order!.customerId,
      merchantId: state.order!.merchantId,
      status: OrderStatus.delivered,
      paymentType: state.order!.paymentType,
      paymentStatus: 'completed',
      subtotal: state.order!.subtotal,
      deliveryFee: state.order!.deliveryFee,
      total: state.order!.total,
      notes: state.order!.notes,
      createdAt: state.order!.createdAt,
      updatedAt: DateTime.now(),
      items: state.order!.items,
    );

    state = DemoState(phase: DemoPhase.orderDelivered, order: deliveredOrder);
  }

  /// Relance le cycle demo (reset vers active).
  void resetCycle() {
    state = const DemoState(phase: DemoPhase.active);
  }

  /// Quitte le mode demo.
  void exitDemo() {
    state = const DemoState();
  }
}

/// Provider du mode demo.
final demoProvider =
    NotifierProvider.autoDispose<DemoNotifier, DemoState>(DemoNotifier.new);
