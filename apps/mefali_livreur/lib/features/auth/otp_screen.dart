import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

/// Ecran de saisie du code OTP a 6 chiffres.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  /// Numero de telephone au format international (+225...).
  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  Timer? _resendTimer;
  int _secondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _secondsRemaining = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _resendOtp() async {
    await ref.read(authControllerProvider.notifier).requestOtp(widget.phone);

    if (!mounted) return;
    final result = ref.read(authControllerProvider);

    if (result.hasValue) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code renvoye !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } else if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors du renvoi du code'),
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

  void _onOtpChanged(String value) {
    if (value.length != 6) return;
    context.go('/auth/register', extra: {'phone': widget.phone, 'otp': value});
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Verification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'Entrez le code recu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Un code a 6 chiffres a ete envoye au ${widget.phone}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              const Text('Code de verification'),
              const SizedBox(height: 8),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(letterSpacing: 16),
                decoration: const InputDecoration(counterText: ''),
                autofocus: true,
                enabled: !isLoading,
                onChanged: _onOtpChanged,
              ),
              const SizedBox(height: 24),
              if (isLoading)
                Center(
                  child: Text(
                    'Envoi en cours...',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                Center(
                  child: _secondsRemaining > 0
                      ? Text(
                          'Renvoyer le code dans ${_secondsRemaining}s',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : TextButton(
                          onPressed: _resendOtp,
                          child: const Text('Renvoyer le code'),
                        ),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
