import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// Statuts de commande.
@JsonEnum(fieldRename: FieldRename.snake)
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  collected,
  @JsonValue('in_transit')
  inTransit,
  delivered,
  cancelled;

  /// Valeur snake_case pour les appels API.
  String get apiValue {
    return switch (this) {
      OrderStatus.pending => 'pending',
      OrderStatus.confirmed => 'confirmed',
      OrderStatus.preparing => 'preparing',
      OrderStatus.ready => 'ready',
      OrderStatus.collected => 'collected',
      OrderStatus.inTransit => 'in_transit',
      OrderStatus.delivered => 'delivered',
      OrderStatus.cancelled => 'cancelled',
    };
  }

  /// Libelle francais pour l'affichage.
  String get label {
    return switch (this) {
      OrderStatus.pending => 'Nouvelle',
      OrderStatus.confirmed => 'En preparation',
      OrderStatus.preparing => 'En preparation',
      OrderStatus.ready => 'Prete',
      OrderStatus.collected => 'Collectee',
      OrderStatus.inTransit => 'En livraison',
      OrderStatus.delivered => 'Livree',
      OrderStatus.cancelled => 'Annulee',
    };
  }

  /// Couleur associee au statut.
  Color get color {
    return switch (this) {
      OrderStatus.pending => const Color(0xFFFF9800),
      OrderStatus.confirmed => const Color(0xFF2196F3),
      OrderStatus.preparing => const Color(0xFF2196F3),
      OrderStatus.ready => const Color(0xFF4CAF50),
      OrderStatus.collected => const Color(0xFF9C27B0),
      OrderStatus.inTransit => const Color(0xFF9C27B0),
      OrderStatus.delivered => const Color(0xFF4CAF50),
      OrderStatus.cancelled => const Color(0xFFF44336),
    };
  }

  /// Icone associee au statut.
  IconData get icon {
    return switch (this) {
      OrderStatus.pending => Icons.notifications_active,
      OrderStatus.confirmed => Icons.restaurant,
      OrderStatus.preparing => Icons.restaurant,
      OrderStatus.ready => Icons.check_circle,
      OrderStatus.collected => Icons.delivery_dining,
      OrderStatus.inTransit => Icons.delivery_dining,
      OrderStatus.delivered => Icons.done_all,
      OrderStatus.cancelled => Icons.cancel,
    };
  }

  /// La commande est-elle active (visible dans la liste marchand) ?
  bool get isActive =>
      this == pending ||
      this == confirmed ||
      this == preparing ||
      this == ready;
}
