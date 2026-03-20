import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Resultat de selection d'adresse.
class AddressResult {
  const AddressResult({
    required this.address,
    required this.lat,
    required this.lng,
  });

  final String address;
  final double lat;
  final double lng;
}

/// Composant de selection d'adresse sur carte (UX-DR11).
/// Layout: GoogleMap (60%) + bottom sheet (40%) avec pin central.
/// Le parent fournit les callbacks pour GPS et geocoding.
class MapAddressPicker extends StatefulWidget {
  const MapAddressPicker({
    required this.onAddressSelected,
    this.onMyLocationRequested,
    this.onCameraIdle,
    this.onSearchSubmitted,
    this.initialPosition,
    this.currentAddress,
    this.recentAddresses = const [],
    this.onRecentAddressTapped,
    super.key,
  });

  /// Appele quand l'utilisateur confirme l'adresse.
  final ValueChanged<AddressResult> onAddressSelected;

  /// Appele quand "Utiliser ma position" est presse.
  /// Le parent doit gerer la permission GPS et retourner la position.
  final Future<LatLng?> Function()? onMyLocationRequested;

  /// Appele quand la camera s'arrete (pour reverse geocoding par le parent).
  final void Function(double lat, double lng)? onCameraIdle;

  /// Appele quand l'utilisateur soumet une recherche textuelle.
  final void Function(String query)? onSearchSubmitted;

  /// Position initiale de la carte (defaut: Bouake centre).
  final LatLng? initialPosition;

  /// Adresse textuelle courante resolue.
  final String? currentAddress;

  /// Adresses recentes pour suggestions rapides.
  final List<AddressResult> recentAddresses;

  /// Appele quand une adresse recente est selectionnee.
  final ValueChanged<AddressResult>? onRecentAddressTapped;

  @override
  State<MapAddressPicker> createState() => _MapAddressPickerState();
}

class _MapAddressPickerState extends State<MapAddressPicker> {
  GoogleMapController? _mapController;
  final _searchController = TextEditingController();
  bool _isLocating = false;

  // Bouake centre par defaut.
  static const _defaultPosition = LatLng(7.6906, -5.0304);

  LatLng get _initialPosition => widget.initialPosition ?? _defaultPosition;

  LatLng _currentCenter = _defaultPosition;

  @override
  void initState() {
    super.initState();
    _currentCenter = _initialPosition;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MapAddressPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPosition != null &&
        widget.initialPosition != oldWidget.initialPosition) {
      _animateTo(widget.initialPosition!);
    }
  }

  Future<void> _animateTo(LatLng position) async {
    await _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );
  }

  Future<void> _onMyLocationPressed() async {
    if (widget.onMyLocationRequested == null || _isLocating) return;
    setState(() => _isLocating = true);
    try {
      final position = await widget.onMyLocationRequested!();
      if (position != null && mounted) {
        await _animateTo(position);
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentCenter = position.target;
  }

  void _onCameraIdle() {
    widget.onCameraIdle?.call(_currentCenter.latitude, _currentCenter.longitude);
  }

  void _onSearchSubmitted(String query) {
    if (query.trim().isEmpty) return;
    widget.onSearchSubmitted?.call(query.trim());
    FocusScope.of(context).unfocus();
  }

  void _onConfirm() {
    final address = widget.currentAddress;
    if (address == null || address.isEmpty) return;
    widget.onAddressSelected(
      AddressResult(
        address: address,
        lat: _currentCenter.latitude,
        lng: _currentCenter.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasAddress =
        widget.currentAddress != null && widget.currentAddress!.isNotEmpty;

    return Column(
      children: [
        // Carte 60%
        Expanded(
          flex: 6,
          child: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: 15,
                ),
                onMapCreated: (controller) => _mapController = controller,
                onCameraMove: _onCameraMove,
                onCameraIdle: _onCameraIdle,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
              // Pin central fixe
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Icon(
                    Icons.location_pin,
                    size: 48,
                    color: Colors.red,
                  ),
                ),
              ),
              // Ombre sous le pin
              Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bottom sheet 40%
        Expanded(
          flex: 4,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barre de recherche
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une adresse',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _onSearchSubmitted,
                  ),
                  const SizedBox(height: 12),
                  // Bouton "Utiliser ma position"
                  SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isLocating ? null : _onMyLocationPressed,
                      icon: _isLocating
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            )
                          : Icon(
                              Icons.my_location,
                              color: colorScheme.primary,
                            ),
                      label: Text(
                        _isLocating
                            ? 'Localisation...'
                            : 'Utiliser ma position',
                      ),
                    ),
                  ),
                  // Adresse courante
                  if (hasAddress) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.place,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.currentAddress!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  // Adresses recentes
                  if (widget.recentAddresses.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Adresses recentes',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final addr in widget.recentAddresses.take(3))
                      InkWell(
                        onTap: () => widget.onRecentAddressTapped?.call(addr),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.history,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  addr.address,
                                  style: textTheme.bodyMedium,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  // Bouton confirmer
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: hasAddress ? _onConfirm : null,
                      child: const Text('Confirmer cette adresse'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
