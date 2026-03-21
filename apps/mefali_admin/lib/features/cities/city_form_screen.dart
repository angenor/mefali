import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

/// Ecran formulaire de creation/edition d'une ville.
class CityFormScreen extends ConsumerStatefulWidget {
  const CityFormScreen({super.key, this.city});

  final CityConfig? city;

  bool get isEditing => city != null;

  @override
  ConsumerState<CityFormScreen> createState() => _CityFormScreenState();
}

class _CityFormScreenState extends ConsumerState<CityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _multiplierController;
  late final TextEditingController _zonesController;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.city?.cityName ?? '',
    );
    _multiplierController = TextEditingController(
      text: widget.city?.deliveryMultiplier.toStringAsFixed(2) ?? '1.00',
    );
    _zonesController = TextEditingController(
      text: widget.city?.zonesGeojson != null
          ? const JsonEncoder.withIndent('  ')
              .convert(widget.city!.zonesGeojson)
          : '',
    );
    _isActive = widget.city?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _multiplierController.dispose();
    _zonesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Modifier la ville' : 'Ajouter une ville',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de la ville',
                  hintText: 'Ex: Bouake',
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom de la ville est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _multiplierController,
                decoration: const InputDecoration(
                  labelText: 'Multiplicateur de livraison',
                  hintText: '1.00',
                  prefixText: 'x',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le multiplicateur est requis';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return 'Le multiplicateur doit etre superieur a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _zonesController,
                decoration: const InputDecoration(
                  labelText: 'Zones GeoJSON (optionnel)',
                  hintText: '{"type": "FeatureCollection", "features": [...]}',
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    try {
                      jsonDecode(value);
                    } catch (_) {
                      return 'JSON invalide';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Ville active'),
                subtitle: Text(
                  _isActive
                      ? 'Les commandes sont acceptees'
                      : 'Les commandes sont bloquees',
                ),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final endpoint = ref.read(adminEndpointProvider);
      final multiplier = double.parse(_multiplierController.text);
      final zonesText = _zonesController.text.trim();
      final zones = zonesText.isNotEmpty
          ? jsonDecode(zonesText) as Map<String, dynamic>
          : null;

      if (widget.isEditing) {
        await endpoint.updateCity(
          widget.city!.id,
          cityName: _nameController.text.trim(),
          deliveryMultiplier: multiplier,
          zonesGeojson: zones,
          isActive: _isActive,
        );
      } else {
        await endpoint.createCity(
          cityName: _nameController.text.trim(),
          deliveryMultiplier: multiplier,
          zonesGeojson: zones,
          isActive: _isActive,
        );
      }

      ref.invalidate(adminCitiesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditing
                  ? 'Ville mise a jour'
                  : 'Ville ajoutee',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        String message = e.message ?? 'Erreur inconnue';
        if (e.response?.data case final Map<String, dynamic> data) {
          if (data['error'] case final Map<String, dynamic> error) {
            message = error['message'] as String? ?? message;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
