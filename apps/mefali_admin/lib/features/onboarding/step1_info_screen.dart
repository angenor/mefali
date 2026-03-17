import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Etape 1: Infos commerce — telephone, nom, adresse, categorie.
class Step1InfoScreen extends ConsumerStatefulWidget {
  const Step1InfoScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  ConsumerState<Step1InfoScreen> createState() => _Step1InfoScreenState();
}

class _Step1InfoScreenState extends ConsumerState<Step1InfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _category;
  bool _otpSent = false;
  final _otpController = TextEditingController();

  static const _categories = [
    'Restaurant',
    'Maquis',
    'Boulangerie',
    'Epicerie',
    'Jus / Boissons',
    'Autre',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '+225${_phoneController.text.replaceAll(RegExp(r'\s'), '')}';
    await ref.read(onboardingProvider.notifier).requestOtp(
          phone: phone,
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          category: _category,
        );

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
      setState(() => _otpSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code envoye au marchand !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _verifyOtp() async {
    final phone = '+225${_phoneController.text.replaceAll(RegExp(r'\s'), '')}';
    await ref.read(onboardingProvider.notifier).verifyAndCreate(
          phone: phone,
          otp: _otpController.text.trim(),
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
          category: _category,
        );

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marchand cree !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(onboardingProvider).isLoading;
    final isCreated =
        ref.watch(onboardingProvider).whenOrNull(data: (s) => s.isCreated) ??
            false;

    // Si deja cree (reprise), passer directement
    if (isCreated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text('Marchand deja cree'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: widget.onNext,
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Etape 1/5 — Infos commerce',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            const Text('Telephone du marchand'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                prefixText: '+225 ',
                counterText: '',
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Requis';
                final d = v.replaceAll(RegExp(r'\s'), '');
                if (d.length != 10) return '10 chiffres requis';
                return null;
              },
              enabled: !_otpSent && !isLoading,
            ),
            const SizedBox(height: 16),
            const Text('Nom du commerce'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Ex: Chez Adjoua',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requis' : null,
              enabled: !_otpSent && !isLoading,
            ),
            const SizedBox(height: 16),
            const Text('Adresse'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Ex: Marche central, Bouake (optionnel)',
              ),
              enabled: !_otpSent && !isLoading,
            ),
            const SizedBox(height: 16),
            const Text('Categorie'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: _otpSent || isLoading
                  ? null
                  : (v) => setState(() => _category = v),
              decoration: const InputDecoration(
                hintText: 'Selectionner (optionnel)',
              ),
            ),
            const SizedBox(height: 32),
            if (!_otpSent) ...[
              FilledButton(
                onPressed: isLoading ? null : _sendOtp,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Envoyer OTP'),
              ),
            ] else ...[
              const Text('Code de verification'),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(letterSpacing: 16),
                decoration: const InputDecoration(counterText: ''),
                autofocus: true,
                enabled: !isLoading,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isLoading ? null : _verifyOtp,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verifier et creer'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() => _otpSent = false),
                child: const Text('Modifier les informations'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
