import 'package:flutter/material.dart';

import '../../models/alarm.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _windows = [15, 30, 45];

  final _userService = UserService();

  Alarm _draft = const Alarm();
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final user = await _userService.getUser();
      if (!mounted) return;
      setState(() {
        _draft = user?.alarm ?? const Alarm();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _update(Alarm alarm) {
    setState(() {
      _draft = alarm;
      _error = null;
    });
  }

  int? _minutesOf(String time) {
    if (time.isEmpty) return null;
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _clock(int minutes, {bool pad = false}) {
    final total = minutes % (24 * 60);
    final h = total ~/ 60;
    final m = total % 60;
    final hour = h % 12 == 0 ? 12 : h % 12;
    final period = h < 12 ? 'AM' : 'PM';
    final hourText = pad ? hour.toString().padLeft(2, '0') : '$hour';
    return '$hourText:${m.toString().padLeft(2, '0')} $period';
  }

  Future<void> _pickTime() async {
    final current = _minutesOf(_draft.time);
    final initial = current == null
        ? const TimeOfDay(hour: 7, minute: 0)
        : TimeOfDay(hour: current ~/ 60, minute: current % 60);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => _pickerTheme(context, child!),
    );
    if (picked == null) return;
    final value =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    _update(_draft.copyWith(time: value));
  }

  Widget _pickerTheme(BuildContext context, Widget child) {
    final c = context.colors;
    final base = Theme.of(context);
    Color pick(Set<WidgetState> states, Color on, Color off) {
      return states.contains(WidgetState.selected) ? on : off;
    }

    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: c.primary,
          onPrimary: c.background,
          surface: c.surface,
          onSurface: c.text,
        ),
        timePickerTheme: TimePickerThemeData(
          backgroundColor: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          helpTextStyle: TextStyle(
            color: c.muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
          hourMinuteColor: WidgetStateColor.resolveWith(
            (states) => pick(states, c.primary, c.surfaceAlt),
          ),
          hourMinuteTextColor: WidgetStateColor.resolveWith(
            (states) => pick(states, c.background, c.text),
          ),
          dayPeriodColor: WidgetStateColor.resolveWith(
            (states) => pick(states, c.primary, Colors.transparent),
          ),
          dayPeriodTextColor: WidgetStateColor.resolveWith(
            (states) => pick(states, c.background, c.text),
          ),
          dayPeriodBorderSide: BorderSide(color: c.surfaceAlt, width: 1.5),
          dialBackgroundColor: c.surfaceAlt,
          dialHandColor: c.primary,
          dialTextColor: WidgetStateColor.resolveWith(
            (states) => pick(states, c.background, c.text),
          ),
          entryModeIconColor: c.muted,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: c.primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: child,
    );
  }

  void _toggleDay(int day) {
    final days = List<int>.from(_draft.days);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    days.sort();
    _update(_draft.copyWith(days: days));
  }

  void _save() {
    if (_draft.smart && _draft.time.isEmpty) {
      setState(() => _error = 'Set a target wake-up time to use Smart Alarm.');
      return;
    }
    if (_draft.time.isNotEmpty && _draft.days.isEmpty) {
      setState(() => _error = 'Select at least one day for this wake-up time.');
      return;
    }
    _userService.updateAlarm(_draft).catchError((_) {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Smart Alarm settings saved')));
    Navigator.pop(context, _draft);
  }

  Widget _label(String value, TextTheme text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(value, style: text.labelSmall),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final target = _minutesOf(_draft.time);
    final repeats = _draft.repeats;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.gradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Material(
                      color: c.surfaceAlt,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(context),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(Icons.chevron_left, color: c.text),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'SMART ALARM',
                        style: text.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              if (_loading)
                Expanded(
                  child: Center(
                    child: CircularProgressIndicator(color: c.primary),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Smart Alarm', style: text.headlineLarge),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Smart Alarm',
                                    style: text.bodyLarge!.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _draft.smart ? 'On' : 'Off. Saved settings are kept but inactive.',
                                    style: text.bodySmall!.copyWith(
                                      color: c.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _draft.smart,
                              onChanged: (value) =>
                                  _update(_draft.copyWith(smart: value)),
                              thumbColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? c.background
                                    : c.muted,
                              ),
                              trackColor: WidgetStateProperty.resolveWith(
                                (states) =>
                                    states.contains(WidgetState.selected)
                                    ? c.primary
                                    : c.surfaceAlt,
                              ),
                              trackOutlineColor: WidgetStateProperty.all(
                                Colors.transparent,
                              ),
                            ),
                          ],
                        ),
                        _label('TARGET WAKE-UP TIME', text),
                        Material(
                          color: c.surface,
                          shape: StadiumBorder(
                            side: BorderSide(color: c.surfaceAlt, width: 1.5),
                          ),
                          child: InkWell(
                            customBorder: const StadiumBorder(),
                            onTap: _pickTime,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 18,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      target == null
                                          ? 'Set a time'
                                          : _clock(target, pad: true),
                                      style: text.bodyLarge!.copyWith(
                                        color: target == null
                                            ? c.muted
                                            : c.text,
                                      ),
                                    ),
                                  ),
                                  Icon(Icons.schedule, color: c.text, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                        _label('DAYS', text),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < _days.length; i++)
                              _Chip(
                                label: _days[i],
                                selected: _draft.days.contains(i),
                                onTap: () => _toggleDay(i),
                              ),
                          ],
                        ),
                        _label('EARLY WAKE-UP WINDOW', text),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final minutes in _windows)
                              _Chip(
                                label: '$minutes minutes',
                                selected: _draft.window == minutes,
                                onTap: () =>
                                    _update(_draft.copyWith(window: minutes)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'If we detect light sleep during this window before your target wake-up time, we’ll wake you. If not, the alarm sounds at your target wake-up time.',
                          style: text.bodySmall!.copyWith(color: c.muted),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          target == null
                              ? 'Set a target wake-up time to see the window.'
                              : 'Wake-up window: ${_clock(target - _draft.window)} to ${_clock(target)}',
                          style: text.bodyLarge!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        _label('ALARM REPEATS', text),
                        Row(
                          children: [
                            _RoundButton(
                              icon: Icons.remove,
                              onTap: repeats > 0
                                  ? () => _update(
                                      _draft.copyWith(repeats: repeats - 1),
                                    )
                                  : null,
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                repeats == 0
                                    ? 'No repeats'
                                    : repeats == 1
                                    ? '1 repeat'
                                    : '$repeats repeats',
                                style: text.bodyLarge!.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            _RoundButton(
                              icon: Icons.add,
                              onTap: repeats < 5
                                  ? () => _update(
                                      _draft.copyWith(repeats: repeats + 1),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 18),
                          Text(
                            _error!,
                            style: text.bodyMedium!.copyWith(color: c.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Save',
                        onPressed: _loading ? null : _save,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: 'Cancel',
                        style: AppButtonStyle.secondary,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Material(
      color: selected ? c.primary : c.surface,
      shape: StadiumBorder(
        side: selected
            ? BorderSide.none
            : BorderSide(color: c.surfaceAlt, width: 1.5),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: text.bodyMedium!.copyWith(
                    color: selected ? c.background : c.text,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _RoundButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Material(
      color: c.surface,
      shape: CircleBorder(side: BorderSide(color: c.surfaceAlt, width: 1.5)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: onTap == null ? c.muted : c.text),
        ),
      ),
    );
  }
}
