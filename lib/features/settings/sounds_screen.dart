import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class SoundsScreen extends StatefulWidget {
  const SoundsScreen({super.key});

  @override
  State<SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends State<SoundsScreen>
    with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();

  List<_Sound> _sounds = [];

  int _selectedIndex = 0;
  int _elapsedSeconds = 0;
  int _selectedDurationMinutes = 60;

  bool _isPlaying = false;
  bool _isLoading = true;
  bool _isBusy = false;

  String? _error;
  String? _loadedStoragePath;

  Timer? _sessionTimer;

  _Sound? get _selectedSound {
    if (_sounds.isEmpty ||
        _selectedIndex < 0 ||
        _selectedIndex >= _sounds.length) {
      return null;
    }

    return _sounds[_selectedIndex];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSounds();
  }

  Future<void> _loadSounds() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sounds')
          .orderBy('order')
          .get();

      final sounds = snapshot.docs
          .map((doc) => _Sound.fromMap(doc.id, doc.data()))
          .where(
            (sound) =>
        sound.isActive && sound.storagePath.isNotEmpty,
      )
          .toList();

      if (!mounted) return;

      setState(() {
        _sounds = sounds;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Error loading sounds: $e');

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = 'Could not load sounds. Please try again.';
      });
    }
  }

  Future<void> _selectSound(int index) async {
    if (index < 0 || index >= _sounds.length || _isBusy) {
      return;
    }

    _sessionTimer?.cancel();

    setState(() {
      _isBusy = true;
    });

    try {
      await _player.stop();

      if (!mounted) return;

      setState(() {
        _selectedIndex = index;
        _elapsedSeconds = 0;
        _isPlaying = false;
        _isBusy = false;
        _loadedStoragePath = null;
      });
    } catch (e) {
      debugPrint('Error switching sound: $e');

      if (!mounted) return;

      setState(() {
        _isPlaying = false;
        _isBusy = false;
        _loadedStoragePath = null;
      });
    }
  }

  Future<void> _togglePlay() async {
    final sound = _selectedSound;

    if (sound == null || _isBusy) return;

    if (_isPlaying) {
      try {
        await _player.pause();
        _sessionTimer?.cancel();

        if (!mounted) return;

        setState(() {
          _isPlaying = false;
        });
      } catch (e) {
        debugPrint('Error pausing sound: $e');
      }

      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      if (_loadedStoragePath != sound.storagePath) {
        final url = await FirebaseStorage.instance
            .ref(sound.storagePath)
            .getDownloadURL();

        await _player.setUrl(url);
        await _player.setLoopMode(LoopMode.one);

        _loadedStoragePath = sound.storagePath;
        _elapsedSeconds = 0;
      }

      if (!mounted) return;

      // Start playback without waiting for the whole sound to finish.
      unawaited(_player.play());

      setState(() {
        _isPlaying = true;
        _isBusy = false;
      });

      _startSessionTimer(_selectedDurationMinutes);
    } catch (e) {
      debugPrint('Error playing sound: $e');

      if (!mounted) return;

      setState(() {
        _isPlaying = false;
        _isBusy = false;
        _error = 'Could not play this sound. Please try again.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not play this sound. Check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted && _isBusy) {
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

  void _changePlaybackDuration(int? minutes) {
    if (minutes == null || minutes == _selectedDurationMinutes) return;

    setState(() {
      _selectedDurationMinutes = minutes;
    });

    // Apply the new stop time immediately if audio is already playing.
    if (_isPlaying) {
      _startSessionTimer(_selectedDurationMinutes);
    }
  }

  void _startSessionTimer(int durationMinutes) {
    _sessionTimer?.cancel();

    final limit = durationMinutes * 60;

    _sessionTimer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) async {
        if (!mounted || !_isPlaying) {
          timer.cancel();
          return;
        }

        if (_elapsedSeconds + 1 >= limit) {
          timer.cancel();

          try {
            await _player.stop();
          } catch (e) {
            debugPrint('Error stopping sound: $e');
          }

          if (!mounted) return;

          setState(() {
            _elapsedSeconds = limit;
            _isPlaying = false;
            _loadedStoragePath = null;
          });

          return;
        }

        setState(() {
          _elapsedSeconds++;
        });
      },
    );
  }

  Future<void> _stopSound() async {
    _sessionTimer?.cancel();

    try {
      await _player.stop();
    } catch (e) {
      debugPrint('Error stopping sound: $e');
    }

    if (!mounted) return;

    setState(() {
      _isPlaying = false;
      _isBusy = false;
      _elapsedSeconds = 0;
      _loadedStoragePath = null;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause playback when the app goes into the background.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      unawaited(_stopSound());
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionTimer?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final selectedSound = _selectedSound;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.gradient,
        ),
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
                      onTap: () async {
                        await _stopSound();

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.chevron_left,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Sounds',
                    style: text.headlineLarge,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Choose a calming sound for your bedtime routine.',
                style: text.bodySmall,
              ),

              const SizedBox(height: 28),

              Text(
                'NOW PLAYING',
                style: text.labelSmall,
              ),

              const SizedBox(height: 12),

              if (_isLoading)
                const AppCard(
                  padding: EdgeInsets.all(28),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null && _sounds.isEmpty)
                AppCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isLoading = true;
                            _error = null;
                          });

                          _loadSounds();
                        },
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                )
              else if (selectedSound == null)
                  const AppCard(
                    padding: EdgeInsets.all(22),
                    child: Center(
                      child: Text(
                        'No sounds are available right now.',
                      ),
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
                            selectedSound.icon,
                            size: 34,
                            color: colors.primary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          selectedSound.title,
                          style: text.titleLarge,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 6),

                        Text(
                          selectedSound.description,
                          style: text.bodySmall,
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 18),

                        Row(
                          children: [
                            Text(
                              'Stop after',
                              style: text.bodySmall,
                            ),
                            const Spacer(),
                            DropdownButton<int>(
                              value: _selectedDurationMinutes,
                              underline: const SizedBox.shrink(),
                              borderRadius: BorderRadius.circular(14),
                              items: const [
                                DropdownMenuItem(
                                  value: 15,
                                  child: Text('15 min'),
                                ),
                                DropdownMenuItem(
                                  value: 30,
                                  child: Text('30 min'),
                                ),
                                DropdownMenuItem(
                                  value: 60,
                                  child: Text('1 hour'),
                                ),
                                DropdownMenuItem(
                                  value: 120,
                                  child: Text('2 hours'),
                                ),
                                DropdownMenuItem(
                                  value: 180,
                                  child: Text('3 hours'),
                                ),
                                DropdownMenuItem(
                                  value: 480,
                                  child: Text('8 hours'),
                                ),
                              ],
                              onChanged: _isBusy ? null : _changePlaybackDuration,
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
                                padding:
                                const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: ClipRRect(
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: _selectedDurationMinutes > 0
                                        ? (_elapsedSeconds /
                                        (_selectedDurationMinutes * 60))
                                        .clamp(0.0, 1.0)
                                        : 0,
                                    minHeight: 5,
                                    backgroundColor: colors.line,
                                    valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                      colors.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              _durationLabel(_selectedDurationMinutes),
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
                                child:
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colors.onPrimary,
                                ),
                              )
                                  : Icon(
                                _isPlaying
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

              Text(
                'RELAXING SOUNDS',
                style: text.labelSmall,
              ),

              const SizedBox(height: 12),

              if (!_isLoading && _error == null)
                ...List.generate(_sounds.length, (index) {
                  final sound = _sounds[index];
                  final selected = index == _selectedIndex;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      onTap: () => _selectSound(index),
                      padding: const EdgeInsets.all(16),
                      alt: selected,
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: selected
                                  ? colors.primary.withValues(
                                alpha: 0.14,
                              )
                                  : colors.surfaceAlt,
                              borderRadius:
                              BorderRadius.circular(16),
                            ),
                            child: Icon(
                              sound.icon,
                              color: selected
                                  ? colors.primary
                                  : colors.text,
                            ),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sound.title,
                                  style: text.bodyLarge,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  sound.description,
                                  style: text.bodySmall,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          Text(
                            '${sound.durationMinutes} min',
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

class _Sound {
  final String id;
  final String title;
  final String description;
  final int durationMinutes;
  final int order;
  final String storagePath;
  final bool isActive;

  const _Sound({
    required this.id,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.order,
    required this.storagePath,
    required this.isActive,
  });

  factory _Sound.fromMap(
      String id,
      Map<String, dynamic> data,
      ) {
    final title = data['title'] as String? ?? 'Sleep Sound';

    return _Sound(
      id: id,
      title: title,
      description: data['description'] as String? ?? '',
      durationMinutes:
      (data['durationMinutes'] as num?)?.toInt() ?? 30,
      order: (data['order'] as num?)?.toInt() ?? 0,
      storagePath: data['storagePath'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  IconData get icon {
    final value = '$title $description'.toLowerCase();

    if (value.contains('white noise') ||
        value.contains('whitenoise')) {
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
}

