import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class SoundsScreen extends StatefulWidget {
  const SoundsScreen({super.key});

  @override
  State<SoundsScreen> createState() => _SoundsScreenState();
}

class _SoundsScreenState extends State<SoundsScreen> {
  int _selectedIndex = 0;
  bool _isPlaying = false;

  final List<_DemoSound> _sounds = const [
    _DemoSound(
      title: 'Gentle Rain',
      description: 'Soft rainfall for a peaceful night',
      duration: '30 min',
      icon: Icons.water_drop_outlined,
    ),
    _DemoSound(
      title: 'Calm Ocean',
      description: 'Relaxing waves and ocean ambience',
      duration: '45 min',
      icon: Icons.waves_outlined,
    ),
    _DemoSound(
      title: 'Forest Night',
      description: 'Quiet nighttime sounds from the forest',
      duration: '30 min',
      icon: Icons.forest_outlined,
    ),
    _DemoSound(
      title: 'Soft Wind',
      description: 'A gentle breeze to help you unwind',
      duration: '20 min',
      icon: Icons.air,
    ),
  ];

  void _selectSound(int index) {
    setState(() {
      _selectedIndex = index;
      _isPlaying = false;
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final selectedSound = _sounds[_selectedIndex];

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
                      onTap: () => Navigator.pop(context),
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

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Text(
                          '00:00',
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
                                value: _isPlaying ? 0.35 : 0,
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
                          selectedSound.duration,
                          style: text.labelSmall,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    GestureDetector(
                      onTap: _togglePlay,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: colors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                          color: colors.onPrimary,
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

              ...List.generate(
                _sounds.length,
                    (index) {
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
                                  ? colors.primary.withValues(alpha: 0.14)
                                  : colors.surfaceAlt,
                              borderRadius: BorderRadius.circular(16),
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
                            sound.duration,
                            style: text.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'Demo sounds • Audio will be connected later',
                  style: text.labelSmall?.copyWith(
                    color: colors.muted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoSound {
  final String title;
  final String description;
  final String duration;
  final IconData icon;

  const _DemoSound({
    required this.title,
    required this.description,
    required this.duration,
    required this.icon,
  });
}