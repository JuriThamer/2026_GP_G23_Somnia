import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/tranquil_tone.dart';
import '../../services/tone_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/somnia_nav_bar.dart';

class SoundsScreen extends StatefulWidget {
  const SoundsScreen({super.key});

  @override
  State<SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends State<SoundsScreen> {
  final ToneService _toneService = ToneService.instance;

  List<TranquilTone> _tones = [];
  String? _selectedId;

  bool _isLoading = true;
  bool _isBusy = false;

  String? _error;

  Timer? _ticker;

  TranquilTone? get _selectedTone {
    for (final tone in _tones) {
      if (tone.toneId == _selectedId) return tone;
    }

    return _tones.isEmpty ? null : _tones.first;
  }

  bool get _selectedIsCurrent =>
      _selectedTone != null &&
          _toneService.currentTone?.toneId == _selectedTone!.toneId;

  bool get _selectedIsPlaying => _selectedIsCurrent && _toneService.isPlaying;

  int get _elapsedSeconds =>
      _selectedIsCurrent ? _toneService.elapsed.inSeconds : 0;

  @override
  void initState() {
    super.initState();
    _toneService.addListener(_onToneChanged);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _toneService.isPlaying) {
        setState(() {});
      }
    });
    _loadTones();
  }

  void _onToneChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadTones() async {
    try {
      final tones = await _toneService.getTones();

      if (!mounted) return;

      setState(() {
        _tones = tones;
        _selectedId =
            _toneService.currentTone?.toneId ??
                (tones.isEmpty ? null : tones.first.toneId);
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error loading tones: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Could not load tones. Please try again.';
      });
    }
  }

  Future<void> _selectTone(TranquilTone tone) async {
    if (_isBusy || tone.toneId == _selectedTone?.toneId) return;

    final current = _toneService.currentTone;

    if (current != null && current.toneId != tone.toneId) {
      await _toneService.stop();
    }

    if (!mounted) return;

    setState(() {
      _selectedId = tone.toneId;
    });
  }

  Future<void> _togglePlay() async {
    final tone = _selectedTone;

    if (tone == null || _isBusy) return;

    if (_selectedIsPlaying) {
      await _toneService.pause();
      return;
    }

    setState(() {
      _isBusy = true;
    });

    try {
      await _toneService.play(tone);
    } catch (e) {
      debugPrint('Error playing tone: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not play this tone. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  String _durationLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    return hours == 1 ? '1 hour' : '$hours hours';
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  IconData _iconFor(TranquilTone tone) {
    final value = tone.title.toLowerCase();

    if (value.contains('white noise') || value.contains('whitenoise')) {
      return Icons.graphic_eq_rounded;
    }

    if (value.contains('forest') ||
        value.contains('bird') ||
        value.contains('nature')) {
      return Icons.forest_outlined;
    }

    if (value.contains('river') ||
        value.contains('water') ||
        value.contains('stream') ||
        value.contains('ocean')) {
      return Icons.waves_outlined;
    }

    if (value.contains('rain')) {
      return Icons.water_drop_outlined;
    }

    return Icons.air;
  }

  @override
  void dispose() {
    _toneService.removeListener(_onToneChanged);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final selectedTone = _selectedTone;
    final timerMinutes = _toneService.timerMinutes;

    return Scaffold(
      bottomNavigationBar: const SomniaNavBar(current: NavTab.tones),
      body: Container(
        decoration: BoxDecoration(gradient: colors.gradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                children: [
                  Material(
                    color: colors.surfaceAlt,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.chevron_left, color: colors.text),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Tranquil Tones', style: text.headlineLarge),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SettingsAvatar(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose a calming tone to play as you fall asleep.',
                style: text.bodySmall,
              ),
              const SizedBox(height: 28),
              Text('NOW PLAYING', style: text.labelSmall),
              const SizedBox(height: 12),
              if (_isLoading)
                const AppCard(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _tones.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });

                          _loadTones();
                        },
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              else if (selectedTone == null)
                  const AppCard(
                    padding: EdgeInsets.all(22),
                    child: Center(
                      child: Text('No tones are available right now.'),
                    ),
                  )
                else
                  AppCard(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _iconFor(selectedTone),
                            size: 34,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          selectedTone.title,
                          style: text.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${selectedTone.durationMinutes} min',
                          style: text.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text('Stop after', style: text.bodySmall),
                            const Spacer(),
                            DropdownButton<int>(
                              value: timerMinutes,
                              underline: const SizedBox.shrink(),
                              borderRadius: BorderRadius.circular(14),
                              items: ToneService.timerOptions
                                  .map(
                                    (minutes) => DropdownMenuItem(
                                  value: minutes,
                                  child: Text(_durationLabel(minutes)),
                                ),
                              )
                                  .toList(),
                              onChanged: _isBusy
                                  ? null
                                  : (minutes) {
                                if (minutes != null) {
                                  _toneService.setTimer(minutes);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              _formatTime(_elapsedSeconds),
                              style: text.labelSmall,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: (_elapsedSeconds / (timerMinutes * 60))
                                        .clamp(0.0, 1.0),
                                    minHeight: 5,
                                    backgroundColor: colors.line,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              _durationLabel(timerMinutes),
                              style: text.labelSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        GestureDetector(
                          onTap: _isBusy ? null : _togglePlay,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: _isBusy
                                  ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                                  : Icon(
                                _selectedIsPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 30,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 30),
              Text('ALL TONES', style: text.labelSmall),
              const SizedBox(height: 12),
              if (!_isLoading && _error == null)
                ..._tones.map((tone) {
                  final selected = tone.toneId == selectedTone?.toneId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      onTap: () => _selectTone(tone),
                      padding: const EdgeInsets.all(16),
                      alt: selected,
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: selected
                                  ? colors.primary.withValues(alpha: 0.14)
                                  : colors.surfaceAlt,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              _iconFor(tone),
                              color: selected ? colors.primary : colors.text,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(tone.title, style: text.bodyLarge),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tone.durationMinutes} min',
                            style: text.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}