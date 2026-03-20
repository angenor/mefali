import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:mefali_design/mefali_design.dart';
import 'pending_accept_queue.dart';

/// Phase de la livraison dans cet ecran.
enum _DeliveryPhase { navigatingToMerchant, navigatingToClient }

/// Ecran de collecte et navigation GPS.
/// Phase 1: navigation vers le marchand + bouton COLLECTE.
/// Phase 2: navigation vers le client (apres COLLECTE).
class CollectionNavigationScreen extends ConsumerStatefulWidget {
  const CollectionNavigationScreen({required this.mission, super.key});

  final DeliveryMission mission;

  @override
  ConsumerState<CollectionNavigationScreen> createState() =>
      _CollectionNavigationScreenState();
}

class _CollectionNavigationScreenState
    extends ConsumerState<CollectionNavigationScreen> {
  _DeliveryPhase _phase = _DeliveryPhase.navigatingToMerchant;
  bool _isLoading = false;
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _locationUpdateTimer;

  // Bouake centre par defaut
  static const _defaultLatLng = LatLng(7.69, -5.03);

  @override
  void initState() {
    super.initState();
    _initLocationStream();
    _startLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Initialise le stream GPS.
  Future<void> _initLocationStream() async {
    final hasPermission = await _ensureGpsPermission();
    if (!hasPermission) return;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (position) {
        if (!mounted) return;
        setState(() => _currentPosition = position);
        _animateCameraToFit();
      },
      onError: (e) {
        debugPrint('GPS stream error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Signal GPS perdu'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      },
    );
  }

  /// Verifie et demande les permissions GPS (AC #6).
  Future<bool> _ensureGpsPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activez le GPS pour la navigation'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('GPS requis'),
            content: const Text(
              'mefali a besoin du GPS pour naviguer vers le marchand. '
              'Ouvrez les parametres pour autoriser.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ANNULER'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Geolocator.openAppSettings();
                },
                child: const Text('PARAMETRES'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    return true;
  }

  /// Envoie la position au serveur toutes les 10s (NFR7).
  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _sendLocationToServer(),
    );
  }

  Future<void> _sendLocationToServer() async {
    final pos = _currentPosition;
    if (pos == null) return;

    try {
      final endpoint = DeliveryEndpoint(ref.read(dioProvider));
      await endpoint.updateLocation(
        widget.mission.deliveryId,
        pos.latitude,
        pos.longitude,
      );
    } catch (e) {
      debugPrint('Location update failed: $e');
    }
  }

  /// Ajuste la camera pour montrer le livreur et la destination.
  void _animateCameraToFit() {
    if (_mapController == null || _currentPosition == null) return;

    final driverLatLng =
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    final destLatLng = _destinationLatLng;
    try {
      if (destLatLng != null) {
        final bounds = LatLngBounds(
          southwest: LatLng(
            driverLatLng.latitude < destLatLng.latitude
                ? driverLatLng.latitude
                : destLatLng.latitude,
            driverLatLng.longitude < destLatLng.longitude
                ? driverLatLng.longitude
                : destLatLng.longitude,
          ),
          northeast: LatLng(
            driverLatLng.latitude > destLatLng.latitude
                ? driverLatLng.latitude
                : destLatLng.latitude,
            driverLatLng.longitude > destLatLng.longitude
                ? driverLatLng.longitude
                : destLatLng.longitude,
          ),
        );
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 80),
        );
      } else {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(driverLatLng),
        );
      }
    } catch (e) {
      debugPrint('Camera animation failed: $e');
    }
  }

  /// Destination actuelle selon la phase.
  LatLng? get _destinationLatLng {
    final lat = widget.mission.deliveryLat;
    final lng = widget.mission.deliveryLng;
    if (_phase == _DeliveryPhase.navigatingToClient && lat != null && lng != null) {
      return LatLng(lat, lng);
    }
    // TODO(5-future): Ajouter merchant_lat/merchant_lng au modele DeliveryMission
    return null;
  }

  /// Markers pour la carte.
  Set<Marker> get _markers {
    final markers = <Marker>{};

    if (_currentPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Vous'),
        ),
      );
    }

    final dest = _destinationLatLng;
    if (dest != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: dest,
          icon: _phase == _DeliveryPhase.navigatingToMerchant
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: _phase == _DeliveryPhase.navigatingToMerchant
                ? widget.mission.merchantName
                : 'Client',
          ),
        ),
      );
    }

    return markers;
  }

  /// Confirme la collecte (AC #2, #5).
  Future<void> _handleCollecte() async {
    setState(() => _isLoading = true);

    final isOnline = await _checkOnline();

    if (isOnline) {
      try {
        final endpoint = DeliveryEndpoint(ref.read(dioProvider));
        await endpoint.confirmPickup(widget.mission.deliveryId);

        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Commande collectee'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 3),
            ),
          );
          setState(() {
            _phase = _DeliveryPhase.navigatingToClient;
            _isLoading = false;
          });
          _animateCameraToFit();
        }
      } on DioException catch (e) {
        setState(() => _isLoading = false);
        if (e.response?.statusCode == 409 && mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Erreur'),
              content: const Text(
                'La commande ne peut pas etre collectee dans cet etat.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (mounted) context.go('/home');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Offline: enqueue confirm_pickup (AC #5)
      await PendingAcceptQueue.instance.enqueue(
        widget.mission.deliveryId,
        widget.mission.orderId,
        missionData: widget.mission.toJson(),
        action: 'confirm_pickup',
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hors connexion — collecte en attente de sync'),
            backgroundColor: Color(0xFFFF9800),
            duration: Duration(seconds: 4),
          ),
        );
        setState(() {
          _phase = _DeliveryPhase.navigatingToClient;
          _isLoading = false;
        });
      }
    }
  }

  /// Confirme la livraison au client (AC #1, #2, #6, #7).
  Future<void> _handleLivre() async {
    setState(() => _isLoading = true);

    // Get current GPS position
    Position pos;
    try {
      pos = _currentPosition ?? await Geolocator.getCurrentPosition();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de recuperer votre position GPS'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final isOnline = await _checkOnline();

    if (isOnline) {
      try {
        final endpoint = DeliveryEndpoint(ref.read(dioProvider));
        final result = await endpoint.confirmDelivery(
          widget.mission.deliveryId,
          pos.latitude,
          pos.longitude,
        );

        if (mounted) {
          // Show WalletCreditFeedback overlay
          final earnings =
              (result['driver_earnings_fcfa'] as num?)?.toInt() ?? 0;
          WalletCreditFeedback.show(context, earnings);

          setState(() => _isLoading = false);

          // Navigate home after animation (2.5s)
          await Future<void>.delayed(const Duration(milliseconds: 2500));
          if (mounted) context.go('/home');
        }
      } on DioException catch (e) {
        setState(() => _isLoading = false);
        if (e.response?.statusCode == 400 && mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Trop loin'),
              content: const Text(
                'Vous etes trop loin de l\'adresse de livraison. '
                'Rapprochez-vous du client.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else if (e.response?.statusCode == 409 && mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Deja confirmee'),
              content: const Text('Cette livraison a deja ete confirmee.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (mounted) context.go('/home');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Offline: queue confirm_delivery (AC #6)
      await PendingAcceptQueue.instance.enqueue(
        widget.mission.deliveryId,
        widget.mission.orderId,
        action: 'confirm_delivery',
        missionData: {
          'lat': pos.latitude,
          'lng': pos.longitude,
        },
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hors connexion — livraison en attente de sync'),
            backgroundColor: Color(0xFFFF9800),
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _isLoading = false);
        // Navigate home — sync will happen on reconnect
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) context.go('/home');
      }
    }
  }

  Future<bool> _checkOnline() async {
    try {
      final result = await Connectivity().checkConnectivity();
      return !result.contains(ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initialLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : _defaultLatLng;

    return Scaffold(
      body: Stack(
        children: [
          // Carte Google Maps (60% haut)
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.4,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialLatLng,
                zoom: 15,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                _animateCameraToFit();
              },
            ),
          ),

          // Bottom sheet (40% bas)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: _buildBottomSheetContent(theme),
                ),
              ),
            ),
          ),

          // Bouton retour (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/home'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheetContent(ThemeData theme) {
    if (_phase == _DeliveryPhase.navigatingToMerchant) {
      return _buildCollectionPhase(theme);
    } else {
      return _buildDeliveryPhase(theme);
    }
  }

  /// Phase collection: info marchand + bouton COLLECTE.
  Widget _buildCollectionPhase(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Collecte chez le marchand',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Marchand info
        Row(
          children: [
            Icon(Icons.store, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mission.merchantName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.mission.merchantAddress != null)
                    Text(
                      widget.mission.merchantAddress!,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Items summary
        Text(
          widget.mission.itemsSummary,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        // Fee
        Text(
          '${(widget.mission.deliveryFee / 100).toStringAsFixed(0)} FCFA',
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // COLLECTE button — FilledButton, 56dp, full-width, brown
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _isLoading ? null : _handleCollecte,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5D4037),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'COLLECTE',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  /// Phase livraison: info client + en route.
  Widget _buildDeliveryPhase(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'En route vers le client',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.location_on, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.mission.deliveryAddress ?? 'Adresse client',
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
        if (widget.mission.estimatedDistanceM != null) ...[
          const SizedBox(height: 8),
          Text(
            '~${(widget.mission.estimatedDistanceM! / 1000).toStringAsFixed(1)} km',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        // Payment info
        Row(
          children: [
            Icon(
              widget.mission.paymentType == 'cod'
                  ? Icons.payments_outlined
                  : Icons.phone_android,
              size: 18,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              widget.mission.paymentType == 'cod' ? 'Cash a la livraison' : 'Paye',
              style: theme.textTheme.bodySmall,
            ),
            if (widget.mission.orderTotal != null) ...[
              const Text(' — '),
              Text(
                '${(widget.mission.orderTotal! / 100).toStringAsFixed(0)} FCFA',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // LIVRE button — FilledButton, 56dp, full-width, brown (AC #1)
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: _isLoading ? null : _handleLivre,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF5D4037),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'LIVRE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        // CLIENT ABSENT button — OutlinedButton, red, below LIVRE (AC #1 story 5.7)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _handleClientAbsent,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFF44336)),
              foregroundColor: const Color(0xFFF44336),
            ),
            child: const Text(
              'CLIENT ABSENT',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Signale le client absent (story 5.7, AC #1).
  Future<void> _handleClientAbsent() async {
    setState(() => _isLoading = true);

    Position pos;
    try {
      pos = _currentPosition ?? await Geolocator.getCurrentPosition();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de recuperer votre position GPS'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final isOnline = await _checkOnline();

    if (isOnline) {
      try {
        final endpoint = DeliveryEndpoint(ref.read(dioProvider));
        await endpoint.reportClientAbsent(
          widget.mission.deliveryId,
          pos.latitude,
          pos.longitude,
        );

        if (mounted) {
          setState(() => _isLoading = false);
          context.push('/delivery/client-absent', extra: {
            'deliveryId': widget.mission.deliveryId,
            'orderId': widget.mission.orderId,
            'paymentType': widget.mission.paymentType,
            'deliveryFee': widget.mission.deliveryFee,
            'customerPhone': widget.mission.customerPhone,
          });
        }
      } on DioException catch (e) {
        setState(() => _isLoading = false);
        if (e.response?.statusCode == 409 && mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Erreur'),
              content: const Text('La livraison ne peut pas etre signalée dans cet etat.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (mounted) context.go('/home');
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Offline: queue client_absent action
      await PendingAcceptQueue.instance.enqueue(
        widget.mission.deliveryId,
        widget.mission.orderId,
        action: 'client_absent',
        missionData: {
          'lat': pos.latitude,
          'lng': pos.longitude,
        },
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hors connexion — client absent en attente de sync'),
            backgroundColor: Color(0xFFFF9800),
            duration: Duration(seconds: 4),
          ),
        );
        setState(() => _isLoading = false);
        context.push('/delivery/client-absent', extra: {
          'deliveryId': widget.mission.deliveryId,
          'orderId': widget.mission.orderId,
          'paymentType': widget.mission.paymentType,
          'deliveryFee': widget.mission.deliveryFee,
          'customerPhone': widget.mission.customerPhone,
        });
      }
    }
  }
}
