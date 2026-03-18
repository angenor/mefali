import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

/// 4 etats de disponibilite marchand.
@JsonEnum(fieldRename: FieldRename.snake)
enum VendorStatus {
  open,
  overwhelmed,
  @JsonValue('auto_paused')
  autoPaused,
  closed;

  /// Valeur snake_case pour les appels API.
  String get apiValue {
    return switch (this) {
      VendorStatus.open => 'open',
      VendorStatus.overwhelmed => 'overwhelmed',
      VendorStatus.autoPaused => 'auto_paused',
      VendorStatus.closed => 'closed',
    };
  }

  /// Libelle francais pour l'affichage.
  String get label {
    return switch (this) {
      VendorStatus.open => 'Ouvert',
      VendorStatus.overwhelmed => 'Deborde',
      VendorStatus.autoPaused => 'Auto-pause',
      VendorStatus.closed => 'Ferme',
    };
  }

  /// Couleur light associee a l'etat.
  Color get color {
    return switch (this) {
      VendorStatus.open => const Color(0xFF4CAF50),
      VendorStatus.overwhelmed => const Color(0xFFFF9800),
      VendorStatus.autoPaused => const Color(0xFF9E9E9E),
      VendorStatus.closed => const Color(0xFFF44336),
    };
  }

  /// Transitions manuelles autorisees depuis cet etat.
  List<VendorStatus> get validManualTransitions {
    return switch (this) {
      VendorStatus.open => [VendorStatus.overwhelmed, VendorStatus.closed],
      VendorStatus.overwhelmed => [VendorStatus.open, VendorStatus.closed],
      VendorStatus.closed => [VendorStatus.open],
      VendorStatus.autoPaused => [VendorStatus.open],
    };
  }

  /// Icone associee a l'etat.
  IconData get icon {
    return switch (this) {
      VendorStatus.open => Icons.check_circle,
      VendorStatus.overwhelmed => Icons.schedule,
      VendorStatus.autoPaused => Icons.pause_circle,
      VendorStatus.closed => Icons.cancel,
    };
  }
}
