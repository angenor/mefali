import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

/// Ecran de saisie du numero de telephone pour l'inscription/connexion.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numero';
    }
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (digits.length != 10 || !RegExp(r'^\d{10}$').hasMatch(digits)) {
      return 'Le numero doit contenir 10 chiffres';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '+225${_phoneController.text.replaceAll(RegExp(r'\s'), '')}';
    await ref.read(authControllerProvider.notifier).requestOtp(phone);

    if (!mounted) return;
    final result = ref.read(authControllerProvider);

    if (result.hasValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code envoye !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      context.go('/auth/otp', extra: phone);
    } else if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de l\'envoi du code'),
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
      appBar: AppBar(title: const Text('Inscription')),
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
                  'Entrez votre numero de telephone',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Nous vous enverrons un code de verification par SMS.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                const Text('Numero de telephone'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    prefixText: '+225 ',
                    counterText: '',
                  ),
                  validator: _validatePhone,
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
                      : const Text('Continuer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
