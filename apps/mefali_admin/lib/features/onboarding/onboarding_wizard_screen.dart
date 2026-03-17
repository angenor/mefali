import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

import 'step1_info_screen.dart';
import 'step2_catalogue_screen.dart';
import 'step3_hours_screen.dart';
import 'step4_payment_screen.dart';
import 'step5_verify_screen.dart';

/// Conteneur wizard 5 etapes avec barre de progression.
class OnboardingWizardScreen extends ConsumerStatefulWidget {
  const OnboardingWizardScreen({super.key, this.merchantId});

  /// Si non-null, reprend un onboarding en cours.
  final String? merchantId;

  @override
  ConsumerState<OnboardingWizardScreen> createState() =>
      _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState
    extends ConsumerState<OnboardingWizardScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    if (widget.merchantId != null) {
      // Reprend un onboarding existant
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref
            .read(onboardingProvider.notifier)
            .loadOnboardingStatus(widget.merchantId!);
        // Auto-navigate to the current step after loading
        final step = ref
                .read(onboardingProvider)
                .whenOrNull(data: (s) => s.currentStep) ??
            0;
        if (step > 0 && _pageController.hasClients) {
          _pageController.jumpToPage(step);
        }
      });
    } else {
      // Nouvel onboarding
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(onboardingProvider.notifier).reset();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);

    final currentStep = state.whenOrNull(data: (s) => s.currentStep) ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding marchand'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          // Barre de progression 1/5 → 5/5
          _ProgressBar(currentStep: currentStep),
          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1InfoScreen(onNext: () => _goToStep(1)),
                Step2CatalogueScreen(onNext: () => _goToStep(2)),
                Step3HoursScreen(onNext: () => _goToStep(3)),
                Step4PaymentScreen(onNext: () => _goToStep(4)),
                const Step5VerifyScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.currentStep});

  final int currentStep;

  static const _labels = ['Infos', 'Catalogue', 'Horaires', 'Paiement', 'Validation'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: List.generate(5, (i) {
              final isActive = i <= currentStep;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) {
              return Expanded(
                child: Text(
                  _labels[i],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight:
                            i == currentStep ? FontWeight.bold : FontWeight.normal,
                      ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
