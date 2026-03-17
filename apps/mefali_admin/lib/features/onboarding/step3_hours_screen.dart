import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';

/// Etape 3: Horaires d'ouverture — 7 jours avec toggle et sélecteur heure.
class Step3HoursScreen extends ConsumerStatefulWidget {
  const Step3HoursScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  ConsumerState<Step3HoursScreen> createState() => _Step3HoursScreenState();
}

class _Step3HoursScreenState extends ConsumerState<Step3HoursScreen> {
  static const _dayNames = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  final List<bool> _open = List.filled(7, true);
  final List<TimeOfDay> _openTimes = List.filled(7, const TimeOfDay(hour: 7, minute: 0));
  final List<TimeOfDay> _closeTimes = List.filled(7, const TimeOfDay(hour: 21, minute: 0));

  Future<void> _pickTime(int day, bool isOpen) async {
    final current = isOpen ? _openTimes[day] : _closeTimes[day];
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      setState(() {
        if (isOpen) {
          _openTimes[day] = picked;
        } else {
          _closeTimes[day] = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _saveHours() async {
    final hours = <Map<String, dynamic>>[];
    for (var i = 0; i < 7; i++) {
      hours.add({
        'day_of_week': i,
        'open_time': _formatTime(_openTimes[i]),
        'close_time': _formatTime(_closeTimes[i]),
        'is_closed': !_open[i],
      });
    }

    await ref.read(onboardingProvider.notifier).setHours(hours);

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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Etape 3/5 — Horaires',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Definissez les heures d\'ouverture.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: 7,
              itemBuilder: (context, i) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(_dayNames[i],
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        Switch(
                          value: _open[i],
                          onChanged: (v) => setState(() => _open[i] = v),
                        ),
                        if (_open[i]) ...[
                          TextButton(
                            onPressed: () => _pickTime(i, true),
                            child: Text(_formatTime(_openTimes[i])),
                          ),
                          const Text('-'),
                          TextButton(
                            onPressed: () => _pickTime(i, false),
                            child: Text(_formatTime(_closeTimes[i])),
                          ),
                        ] else
                          const Expanded(
                            child: Text('Ferme',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
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
                  onPressed: isLoading ? null : _saveHours,
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
