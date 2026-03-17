import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

/// Ecran d'inscription livreur : nom + telephone du sponsor.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key, required this.phone, required this.otp});

  /// Numero de telephone au format international.
  final String phone;

  /// Code OTP saisi precedemment.
  final String otp;

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _nameController = TextEditingController();
  final _sponsorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _sponsorController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre prenom';
    }
    return null;
  }

  String? _validateSponsorPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer le numero de votre sponsor';
    }
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (digits.length != 10 || !RegExp(r'^\d{10}$').hasMatch(digits)) {
      return 'Le numero doit contenir 10 chiffres';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final sponsorPhone =
        '+225${_sponsorController.text.replaceAll(RegExp(r'\s'), '')}';

    await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(
          widget.phone,
          widget.otp,
          _nameController.text.trim(),
          sponsorPhone,
        );

    if (!mounted) return;
    final result = ref.read(authControllerProvider);

    if (result.hasValue) {
      context.go('/home');
    } else if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de l\'inscription'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(days: 365),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Inscription Livreur')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Text(
                  'Completez votre inscription',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez votre prenom et le numero de votre sponsor.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                const Text('Prenom'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  validator: _validateName,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),
                const Text('Telephone du sponsor'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _sponsorController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    prefixText: '+225 ',
                    counterText: '',
                  ),
                  validator: _validateSponsorPhone,
                  enabled: !isLoading,
                ),
                const Spacer(),
                FilledButton(
                  onPressed: isLoading ? null : _onSubmit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('S\'inscrire'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
