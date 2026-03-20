import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mefali_design/mefali_design.dart';

import 'saved_addresses_provider.dart';

/// Ecran de selection d'adresse de livraison (story 4.6).
class AddressSelectionScreen extends ConsumerStatefulWidget {
  const AddressSelectionScreen({super.key});

  @override
  ConsumerState<AddressSelectionScreen> createState() =>
      _AddressSelectionScreenState();
}

class _AddressSelectionScreenState
    extends ConsumerState<AddressSelectionScreen> {
  String? _currentAddress;
  LatLng? _resolvedPosition;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentAsync = ref.watch(savedAddressesProvider);
    final recentAddresses = recentAsync.value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresse de livraison'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: MapAddressPicker(
        currentAddress: _currentAddress,
        recentAddresses: recentAddresses
            .map(
              (e) => AddressResult(address: e.address, lat: e.lat, lng: e.lng),
            )
            .toList(),
        onMyLocationRequested: _requestLocation,
        onCameraIdle: _onCameraIdle,
        onSearchSubmitted: _onSearchSubmitted,
        onRecentAddressTapped: _onRecentAddressTapped,
        initialPosition: _resolvedPosition,
        onAddressSelected: (result) {
          context.pop(result);
        },
      ),
    );
  }

  Future<LatLng?> _requestLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission de localisation refusee. '
              'Vous pouvez deplacer le pin sur la carte.',
            ),
          ),
        );
      }
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
    final latLng = LatLng(position.latitude, position.longitude);
    await _reverseGeocode(position.latitude, position.longitude);
    return latLng;
  }

  Future<void> _onCameraIdle(double lat, double lng) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _reverseGeocode(lat, lng);
    });
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final placemarks =
          await geocoding.placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final parts = <String>[
          if (place.street != null && place.street!.isNotEmpty) place.street!,
          if (place.subLocality != null && place.subLocality!.isNotEmpty)
            place.subLocality!,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality!,
        ];
        setState(() {
          _currentAddress =
              parts.isNotEmpty ? parts.join(', ') : '$lat, $lng';
          _resolvedPosition = LatLng(lat, lng);
        });
      }
    } on Exception {
      if (mounted) {
        setState(() {
          _currentAddress = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
          _resolvedPosition = LatLng(lat, lng);
        });
      }
    }
  }

  Future<void> _onSearchSubmitted(String query) async {
    try {
      final locations =
          await geocoding.locationFromAddress(query);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        setState(() {
          _resolvedPosition = LatLng(loc.latitude, loc.longitude);
        });
        await _reverseGeocode(loc.latitude, loc.longitude);
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adresse introuvable. Deplacez le pin sur la carte.'),
          ),
        );
      }
    }
  }

  void _onRecentAddressTapped(AddressResult addr) {
    context.pop(addr);
  }
}
