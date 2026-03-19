import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mefali_api_client/mefali_api_client.dart';
import 'package:mefali_core/mefali_core.dart';

/// Ecran de gestion des horaires et fermetures exceptionnelles.
class BusinessHoursScreen extends ConsumerStatefulWidget {
  const BusinessHoursScreen({super.key});

  @override
  ConsumerState<BusinessHoursScreen> createState() =>
      _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends ConsumerState<BusinessHoursScreen> {
  // Editable state for 7 days (0=Lundi..6=Dimanche)
  late List<_DayEntry> _days;
  bool _initialized = false;

  void _initFromHours(List<BusinessHours> hours) {
    if (_initialized) return;
    _days = List.generate(7, (i) {
      final existing = hours.where((h) => h.dayOfWeek == i).firstOrNull;
      if (existing != null) {
        return _DayEntry(
          dayOfWeek: i,
          isClosed: existing.isClosed,
          openTime: _parseTime(existing.openTime),
          closeTime: _parseTime(existing.closeTime),
        );
      }
      return _DayEntry(dayOfWeek: i, isClosed: false);
    });
    _initialized = true;
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts.length > 1 ? parts[1] : '0'),
    );
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatTimeDisplay(TimeOfDay t) => _formatTime(t);

  Future<void> _pickTime(int dayIndex, {required bool isOpen}) async {
    final current =
        isOpen ? _days[dayIndex].openTime : _days[dayIndex].closeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
    );
    if (picked != null && mounted) {
      setState(() {
        if (isOpen) {
          _days[dayIndex] = _days[dayIndex].copyWith(openTime: picked);
        } else {
          _days[dayIndex] = _days[dayIndex].copyWith(closeTime: picked);
        }
      });
    }
  }

  Future<void> _saveHours() async {
    final hoursData = _days.map((d) => {
      'day_of_week': d.dayOfWeek,
      'open_time': _formatTime(d.openTime),
      'close_time': _formatTime(d.closeTime),
      'is_closed': d.isClosed,
    }).toList();

    await ref.read(businessHoursNotifierProvider.notifier).saveHours(hoursData);

    if (!mounted) return;
    final state = ref.read(businessHoursNotifierProvider);
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
          content: Text('Horaires mis à jour'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _addClosure() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;

    final reason = await _showReasonDialog();
    if (!mounted) return;

    final dateStr =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    await ref
        .read(exceptionalClosuresNotifierProvider.notifier)
        .createClosure(closureDate: dateStr, reason: reason);

    if (!mounted) return;
    final state = ref.read(exceptionalClosuresNotifierProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${state.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<String?> _showReasonDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motif (optionnel)'),
        content: TextField(
          controller: controller,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: 'Ex: Jour férié, Congé...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Passer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result?.isEmpty == true ? null : result;
  }

  Future<void> _deleteClosure(String closureId) async {
    await ref
        .read(exceptionalClosuresNotifierProvider.notifier)
        .deleteClosure(closureId);
  }

  @override
  Widget build(BuildContext context) {
    final hoursAsync = ref.watch(merchantHoursProvider);
    final closuresAsync = ref.watch(upcomingClosuresProvider);
    final saveState = ref.watch(businessHoursNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Horaires'),
      ),
      body: hoursAsync.when(
        loading: () => const _SkeletonLoading(),
        error: (e, _) => Center(
          child: Text('Erreur: $e', style: TextStyle(color: theme.colorScheme.error)),
        ),
        data: (hours) {
          _initFromHours(hours);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Empty state guidance
                    if (hours.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 48,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Configurez vos horaires pour indiquer votre disponibilité',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // 7 days
                    ...List.generate(7, (i) => _DayTile(
                      entry: _days[i],
                      onClosedChanged: (closed) {
                        setState(() {
                          _days[i] = _days[i].copyWith(isClosed: closed);
                        });
                      },
                      onOpenTimeTap: () => _pickTime(i, isOpen: true),
                      onCloseTimeTap: () => _pickTime(i, isOpen: false),
                      formatTime: _formatTimeDisplay,
                    )),
                    const SizedBox(height: 24),
                    // Exceptional closures section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fermetures exceptionnelles',
                          style: theme.textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _addClosure,
                        ),
                      ],
                    ),
                    closuresAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) => Text('Erreur: $e'),
                      data: (closures) {
                        if (closures.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Aucune fermeture exceptionnelle',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: closures.map((c) => _ClosureTile(
                            closure: c,
                            onDelete: () => _deleteClosure(c.id),
                          )).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Save button
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saveState.isLoading ? null : _saveHours,
                    child: saveState.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Editable state for one day.
class _DayEntry {
  _DayEntry({
    required this.dayOfWeek,
    required this.isClosed,
    this.openTime = const TimeOfDay(hour: 8, minute: 0),
    this.closeTime = const TimeOfDay(hour: 18, minute: 0),
  });

  final int dayOfWeek;
  final bool isClosed;
  final TimeOfDay openTime;
  final TimeOfDay closeTime;

  String get dayName => BusinessHours.dayNames[dayOfWeek];

  _DayEntry copyWith({
    bool? isClosed,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
  }) {
    return _DayEntry(
      dayOfWeek: dayOfWeek,
      isClosed: isClosed ?? this.isClosed,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

/// Tile for one day of the week.
class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.entry,
    required this.onClosedChanged,
    required this.onOpenTimeTap,
    required this.onCloseTimeTap,
    required this.formatTime,
  });

  final _DayEntry entry;
  final ValueChanged<bool> onClosedChanged;
  final VoidCallback onOpenTimeTap;
  final VoidCallback onCloseTimeTap;
  final String Function(TimeOfDay) formatTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.dayName,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Switch(
                  value: !entry.isClosed,
                  onChanged: (open) => onClosedChanged(!open),
                ),
              ],
            ),
            if (!entry.isClosed) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _TimeButton(
                      label: 'Ouverture',
                      time: formatTime(entry.openTime),
                      onTap: onOpenTimeTap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeButton(
                      label: 'Fermeture',
                      time: formatTime(entry.closeTime),
                      onTap: onCloseTimeTap,
                    ),
                  ),
                ],
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Fermé',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Button to select a time.
class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final String time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(time, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

/// Tile for an exceptional closure.
class _ClosureTile extends StatelessWidget {
  const _ClosureTile({
    required this.closure,
    required this.onDelete,
  });

  final ExceptionalClosure closure;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final d = closure.closureDate;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.event_busy, color: theme.colorScheme.error),
        title: Text(dateStr),
        subtitle: closure.reason != null ? Text(closure.reason!) : null,
        trailing: IconButton(
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

/// Skeleton loading state.
class _SkeletonLoading extends StatelessWidget {
  const _SkeletonLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(
        7,
        (_) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 64,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 48,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
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
