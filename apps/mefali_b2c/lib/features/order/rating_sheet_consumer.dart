import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';

import 'saved_addresses_provider.dart';

/// Riverpod wrapper for RatingBottomSheet that handles submission,
/// offline queueing, and error display. Used in both delivery tracking
/// and order history screens.
class RatingSheetConsumer extends ConsumerStatefulWidget {
  const RatingSheetConsumer({
    required this.orderId,
    required this.merchantName,
    required this.driverName,
    required this.onDone,
    super.key,
  });

  final String orderId;
  final String merchantName;
  final String driverName;
  final VoidCallback onDone;

  @override
  ConsumerState<RatingSheetConsumer> createState() =>
      _RatingSheetConsumerState();
}

class _RatingSheetConsumerState extends ConsumerState<RatingSheetConsumer> {
  bool _isLoading = false;

  Future<void> _onSubmit({
    required int merchantScore,
    required int driverScore,
    String? merchantComment,
    String? driverComment,
  }) async {
    setState(() => _isLoading = true);

    try {
      final request = SubmitRatingRequest(
        merchantScore: merchantScore,
        driverScore: driverScore,
        merchantComment: merchantComment,
        driverComment: driverComment,
      );

      final endpoint = RatingEndpoint(ref.read(dioProvider));
      await endpoint.submitRating(widget.orderId, request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Merci pour votre avis !'),
              ],
            ),
            backgroundColor: Color(0xFF4CAF50),
            duration: Duration(seconds: 3),
          ),
        );
        widget.onDone();
      }
    } on DioException catch (e) {
      if (mounted) {
        if (_isConnectionError(e)) {
          await _enqueueOfflineRating(
            merchantScore: merchantScore,
            driverScore: driverScore,
            merchantComment: merchantComment,
            driverComment: driverComment,
          );
        } else {
          final message = e.response?.statusCode == 409
              ? 'Vous avez deja note cette commande'
              : 'Erreur lors de la notation';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isConnectionError(DioException e) {
    return e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  Future<void> _enqueueOfflineRating({
    required int merchantScore,
    required int driverScore,
    String? merchantComment,
    String? driverComment,
  }) async {
    final db = ref.read(mefaliDatabaseProvider);
    await db.enqueueSync(
      entityType: 'rating',
      entityId: widget.orderId,
      payload: {
        'order_id': widget.orderId,
        'merchant_score': merchantScore,
        'driver_score': driverScore,
        'merchant_comment': merchantComment,
        'driver_comment': driverComment,
      },
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note enregistree, sera envoyee quand vous serez en ligne'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RatingBottomSheet(
      merchantName: widget.merchantName,
      driverName: widget.driverName,
      isLoading: _isLoading,
      onSubmit: ({
        required int merchantScore,
        required int driverScore,
        String? merchantComment,
        String? driverComment,
      }) {
        _onSubmit(
          merchantScore: merchantScore,
          driverScore: driverScore,
          merchantComment: merchantComment,
          driverComment: driverComment,
        );
      },
    );
  }
}
