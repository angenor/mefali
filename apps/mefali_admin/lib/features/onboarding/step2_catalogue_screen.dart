import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
/// Etape 2: Catalogue — ajout de produits (nom, prix).
class Step2CatalogueScreen extends ConsumerStatefulWidget {
  const Step2CatalogueScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  ConsumerState<Step2CatalogueScreen> createState() =>
      _Step2CatalogueScreenState();
}

class _Step2CatalogueScreenState extends ConsumerState<Step2CatalogueScreen> {
  final List<Map<String, dynamic>> _products = [];

  void _addProduct() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Ajouter un produit',
                style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 16),
            const Text('Nom du produit'),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Ex: Garba'),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text('Prix (FCFA)'),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Ex: 500'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final price = int.tryParse(priceController.text.trim()) ?? 0;
                if (name.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Nom et prix valide requis'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                setState(() {
                  _products.add({'name': name, 'price': price});
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProducts() async {
    if (_products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ajoutez au moins un produit'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await ref.read(onboardingProvider.notifier).addProducts(_products);

    if (!mounted) return;
    final state = ref.read(onboardingProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${state.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingProvider).isLoading;
    final existing =
        ref.watch(onboardingProvider).whenOrNull(data: (s) => s.products) ??
            [];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Etape 2/5 — Catalogue',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez les produits du marchand.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // Produits existants (reprise)
          if (existing.isNotEmpty) ...[
            Text('Produits existants:', style: Theme.of(context).textTheme.labelLarge),
            ...existing.map((p) => ListTile(
                  dense: true,
                  title: Text(p.name),
                  trailing: Text('${p.price} F'),
                )),
            const Divider(),
          ],
          // Nouveaux produits
          ..._products.map((p) => ListTile(
                dense: true,
                leading: const Icon(Icons.restaurant_menu),
                title: Text(p['name'] as String),
                trailing: Text('${p['price']} F'),
                onLongPress: () {
                  setState(() => _products.remove(p));
                },
              )),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Ajouter un produit'),
            onPressed: isLoading ? null : _addProduct,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onNext,
                  child: const Text('Passer'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: isLoading ? null : _saveProducts,
                  child: isLoading
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
