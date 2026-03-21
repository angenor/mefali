import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

/// Ecran de saisie du prenom lors de la premiere inscription.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key, required this.phone, required this.otp});

  /// Numero de telephone au format international.
  final String phone;

  /// Code OTP saisi precedemment.
  final String otp;

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _nameController = TextEditingController();
  final _referralController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez entrer votre prenom';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final referral = _referralController.text.trim();
    await ref.read(authControllerProvider.notifier).verifyOtp(
          widget.phone,
          widget.otp,
          _nameController.text.trim(),
          referralCode: referral.isEmpty ? null : referral,
        );

    if (!mounted) return;
    final result = ref.read(authControllerProvider);

    if (result.hasValue) {
      context.go('/home');
    } else if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de la verification'),
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
      appBar: AppBar(title: const Text('Votre prenom')),
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
                  'Comment vous appelez-vous ?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Votre prenom sera visible par les commercants et livreurs.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                const Text('Prenom'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(),
                  validator: _validateName,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 24),
                const Text('Code parrain (optionnel)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _referralController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Ex: ABC123',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (!RegExp(r'^[A-Z0-9]{6}$').hasMatch(value.trim())) {
                      return 'Code invalide (6 caracteres alphanumeriques)';
                    }
                    return null;
                  },
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
                      : const Text('Commencer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
