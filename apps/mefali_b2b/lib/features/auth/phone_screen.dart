import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_design/mefali_design.dart';

/// Ecran de login marchand — saisie du numero de telephone.
class B2bPhoneScreen extends ConsumerStatefulWidget {
  const B2bPhoneScreen({super.key});

  @override
  ConsumerState<B2bPhoneScreen> createState() => _B2bPhoneScreenState();
}

class _B2bPhoneScreenState extends ConsumerState<B2bPhoneScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Veuillez entrer votre numero';
    final digits = value.replaceAll(RegExp(r'\s'), '');
    if (digits.length != 10 || !RegExp(r'^\d{10}$').hasMatch(digits)) {
      return 'Le numero doit contenir 10 chiffres';
    }
    return null;
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final phone = '+225${_phoneController.text.replaceAll(RegExp(r'\s'), '')}';

    try {
      final authEndpoint = AuthEndpoint(ref.read(dioProvider));
      await authEndpoint.requestOtp(phone);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code envoye !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      context.go('/auth/otp', extra: phone);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('mefali Marchand')),
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
                  'Connexion Marchand',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Entrez votre numero pour recevoir un code de verification.',
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
                  enabled: !_isLoading,
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isLoading ? null : _onSubmit,
                  child: _isLoading
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
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    ref.read(demoProvider.notifier).activateDemo();
                    context.go('/demo');
                  },
                  icon: const Icon(
                    Icons.play_circle_outline,
                    color: MefaliColors.warningLight,
                  ),
                  label: const Text(
                    'Voir la demo',
                    style: TextStyle(color: MefaliColors.warningLight),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
