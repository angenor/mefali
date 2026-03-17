import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
/// Etape 5: Verification — resume complet et bouton VALIDER.
class Step5VerifyScreen extends ConsumerWidget {
  const Step5VerifyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (data) => _VerifyContent(data: data),
    );
  }
}

class _VerifyContent extends ConsumerStatefulWidget {
  const _VerifyContent({required this.data});

  final OnboardingState data;

  @override
  ConsumerState<_VerifyContent> createState() => _VerifyContentState();
}

class _VerifyContentState extends ConsumerState<_VerifyContent> {
  bool _isLoading = false;

  Future<void> _finalize() async {
    setState(() => _isLoading = true);

    await ref.read(onboardingProvider.notifier).finalize();

    if (!mounted) return;
    setState(() => _isLoading = false);

    final state = ref.read(onboardingProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${state.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marchand onboarde avec succes !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final merchant = widget.data.merchant;
    final products = widget.data.products;
    final hours = widget.data.businessHours;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Etape 5/5 — Verification',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          // Infos marchand
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Commerce', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (merchant != null) ...[
                    Text('Nom: ${merchant.name}'),
                    if (merchant.address != null) Text('Adresse: ${merchant.address}'),
                    if (merchant.category != null) Text('Categorie: ${merchant.category}'),
                  ] else
                    const Text('Non renseigne'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Produits
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Produits (${products.length})',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (products.isEmpty)
                    const Text('Aucun produit ajoute')
                  else
                    ...products.map((p) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.name),
                              Text('${p.price} F'),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Horaires
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Horaires', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (hours.isEmpty)
                    const Text('Non renseignes')
                  else
                    ...hours.map((h) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            h.isClosed
                                ? '${h.dayName}: Ferme'
                                : '${h.dayName}: ${h.openTime} - ${h.closeTime}',
                          ),
                        )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Wallet
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    widget.data.walletCreated ? Icons.check_circle : Icons.cancel,
                    color: widget.data.walletCreated ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.data.walletCreated ? 'Wallet cree' : 'Wallet non cree',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isLoading ? null : _finalize,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('VALIDER'),
          ),
        ],
      ),
    );
  }
}
