import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:url_launcher/url_launcher.dart';

import 'rating_sheet_consumer.dart';

/// Ecran de suivi temps reel de livraison (story 5.5).
///
/// Affiche la carte Google Maps plein ecran avec le marker du livreur
/// (point bleu) et la destination (marker rouge). Bottom sheet avec
/// ETA, nom du livreur et bouton appeler.
class DeliveryTrackingScreen extends ConsumerStatefulWidget {
  const DeliveryTrackingScreen({
    required this.orderId,
    this.deliveryLat,
    this.deliveryLng,
    this.deliveryAddress,
    this.merchantName,
    super.key,
  });

  final String orderId;
  final double? deliveryLat;
  final double? deliveryLng;
  final String? deliveryAddress;
  final String? merchantName;

  @override
  ConsumerState<DeliveryTrackingScreen> createState() =>
      _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState
    extends ConsumerState<DeliveryTrackingScreen> {
  GoogleMapController? _mapController;
  LatLng? _driverPosition;
  int _etaSeconds = 0;
  String? _driverName;
  String? _driverPhone;
  bool _isFallback = false;
  bool _isDelivered = false;
  bool _isClientAbsent = false;

  LatLng? get _destination =>
      widget.deliveryLat != null && widget.deliveryLng != null
          ? LatLng(widget.deliveryLat!, widget.deliveryLng!)
          : null;

  @override
  Widget build(BuildContext context) {
    final trackingAsync = ref.watch(deliveryTrackingProvider(widget.orderId));

    trackingAsync.whenData((update) {
      // Handle delivery.confirmed event
      if (update.status == 'delivered' && !_isDelivered) {
        setState(() => _isDelivered = true);
        _showDeliveredAndGoHome();
        return;
      }

      // Handle client absent event
      if (update.status == 'client_absent' && !_isClientAbsent) {
        setState(() => _isClientAbsent = true);
        return;
      }

      // Handle absent resolved event
      if (update.status == 'absent_resolved') {
        _showAbsentResolvedAndGoHome();
        return;
      }

      if (_driverPosition?.latitude != update.lat ||
          _driverPosition?.longitude != update.lng ||
          _isFallback != update.isFallback) {
        setState(() {
          _driverPosition = LatLng(update.lat, update.lng);
          _etaSeconds = update.etaSeconds;
          _driverName = update.driverName ?? _driverName;
          _driverPhone = update.driverPhone ?? _driverPhone;
          _isFallback = update.isFallback;
        });
        _updateCamera();
      }
    });

    final isFallback = _isFallback;

    return Scaffold(
      body: Stack(
        children: [
          // Google Maps plein ecran
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _destination ?? const LatLng(7.69, -5.03),
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _buildMarkers(),
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Banner connexion instable
          if (isFallback)
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.orange,
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                child: const Text(
                  'Connexion instable - mise a jour ralentie',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Bouton retour
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => context.go('/home'),
              ),
            ),
          ),

          // Bottom sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomSheet(context),
          ),
        ],
      ),
    );
  }

  void _showDeliveredAndGoHome() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Commande livree !'),
        backgroundColor: Color(0xFF4CAF50),
        duration: Duration(seconds: 2),
      ),
    );
    // Show rating sheet after SnackBar disappears (2s duration + 500ms buffer).
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _showRatingSheet();
    });
  }

  void _showRatingSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => RatingSheetConsumer(
        orderId: widget.orderId,
        merchantName: widget.merchantName ?? 'Le restaurant',
        driverName: _driverName ?? 'Le livreur',
        onDone: () {
          Navigator.of(sheetContext).pop();
          if (mounted) _showPostRatingShare();
        },
      ),
    ).then((_) {
      // If dismissed without rating, go home (AC #4)
      if (mounted) context.go('/home');
    });
  }

  void _showPostRatingShare() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _PostRatingShareContent(
        onShare: () async {
          Navigator.of(ctx).pop();
          if (mounted) context.go('/home');
        },
        onSkip: () {
          Navigator.of(ctx).pop();
          if (mounted) context.go('/home');
        },
      ),
    ).then((_) {
      if (mounted) context.go('/home');
    });
  }

  void _showAbsentResolvedAndGoHome() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Votre commande n\'a pas pu etre livree'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/home');
    });
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    if (_driverPosition != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _driverPosition!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        onTap: _showDriverInfo,
      ));
    }

    if (_destination != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destination!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ));
    }

    return markers;
  }

  void _updateCamera() {
    if (_mapController == null || _driverPosition == null) return;

    if (_destination != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          min(_driverPosition!.latitude, _destination!.latitude) - 0.005,
          min(_driverPosition!.longitude, _destination!.longitude) - 0.005,
        ),
        northeast: LatLng(
          max(_driverPosition!.latitude, _destination!.latitude) + 0.005,
          max(_driverPosition!.longitude, _destination!.longitude) + 0.005,
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(_driverPosition!),
      );
    }
  }

  Widget _buildBottomSheet(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final etaMin = (_etaSeconds / 60).ceil();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Statut livreur
            Row(
              children: [
                const Icon(Icons.delivery_dining,
                    color: Color(0xFF5D4037), size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isClientAbsent
                        ? 'Le livreur ne vous trouve pas'
                        : _driverPosition != null
                            ? '${_driverName ?? 'Votre livreur'} est en route !'
                            : 'Recherche du livreur...',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _isClientAbsent ? Colors.orange : null,
                    ),
                  ),
                ),
              ],
            ),

            // ETA
            if (_driverPosition != null && _etaSeconds > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.timer, size: 20, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Arrive dans $etaMin min',
                    style: textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF5D4037),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],

            // Adresse de livraison
            if (widget.deliveryAddress != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.deliveryAddress!,
                      style: textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Bouton appeler
            if (_driverPhone != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _callDriver(_driverPhone!),
                  icon: const Icon(Icons.phone),
                  label: Text('Appeler ${_driverName ?? 'le livreur'}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDriverInfo() {
    if (_driverName == null && _driverPhone == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              child: Icon(Icons.person, size: 36),
            ),
            const SizedBox(height: 12),
            Text(
              _driverName ?? 'Livreur',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_driverPhone != null) ...[
              const SizedBox(height: 8),
              Text(
                _driverPhone!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _callDriver(_driverPhone!);
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Appeler'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5D4037),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _callDriver(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

/// Widget Consumer pour le post-rating share — fetch le referral code du user.
class _PostRatingShareContent extends ConsumerWidget {
  const _PostRatingShareContent({
    required this.onShare,
    required this.onSkip,
  });

  final VoidCallback onShare;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralAsync = ref.watch(referralCodeProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Merci pour votre avis !',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              final code = referralAsync.value?.referralCode ?? '';
              final message = code.isNotEmpty
                  ? WhatsAppShareHelper.buildAppInviteMessage(
                      referralCode: code,
                      shareBaseUrl: 'https://api.mefali.ci',
                    )
                  : 'Rejoins mefali ! L\'app pour commander a manger a Bouake.\nhttps://api.mefali.ci/share';
              final success =
                  await WhatsAppShareHelper.shareOnWhatsApp(message);
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('WhatsApp non disponible'),
                  ),
                );
              }
              onShare();
            },
            icon: const Icon(Icons.share),
            label: const Text('Partager mefali sur WhatsApp'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF25D366),
              side: const BorderSide(color: Color(0xFF25D366)),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            child: const Text('Plus tard'),
          ),
        ],
      ),
    );
  }
}
