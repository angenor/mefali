import 'package:flutter/material.dart';
import 'package:mefali_core/mefali_core.dart';

/// Couleur associee au statut d'un litige.
Color disputeStatusColor(DisputeStatus status) {
  switch (status) {
    case DisputeStatus.open:
      return Colors.orange;
    case DisputeStatus.inProgress:
      return Colors.blue;
    case DisputeStatus.resolved:
      return Colors.green;
    case DisputeStatus.closed:
      return Colors.grey;
  }
}
