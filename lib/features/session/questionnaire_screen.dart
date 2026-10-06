import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../models/sleep_session.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _step = 0;
  bool _saving = false;

  int? _restedAnswer;
  int? _fallingAsleepAnswer;
  int? _wakingAnswer;
  int? _sleepQualityAnswer;

  final List<String> _restedOptions = [
    'Not at all',
    'A little',
    'Fairly',
    'Very',
  ];

  final List<String> _fallingAsleepOptions = [
    'Under 15 min',
    '15 to 30 min',
    'Over 30 min',
    'Not sure',
  ];

  final List<String> _wakingOptions = [
    'None',
    'Once',
    '2 to 3 times',
    '4 or more',
  ];

  final List<String> _sleepQualityOptions = [
    'Poor',
    'Fair',
    'Good',
    'Very good',
  ];

  String? get _sessionId {
    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is String) {
      return arguments;
    }

    return null;
  }

  bool get _isLastStep => _step == 3;

  bool get _currentAnswered {
    switch (_step) {
      case 0:
        return _restedAnswer != null;
      case 1:
        return _fallingAsleepAnswer != null;
      case 2:
        return _wakingAnswer != null;
      case 3:
        return _sleepQualityAnswer != null;
      default:
        return false;
    }
  }

  String get _question {
    switch (_step) {
      case 0:
        return 'How rested do you feel right now?';
      case 1:
        return 'How long did it take to fall asleep?';
      case 2:
        return 'How many times do you remember waking up?';
      case 3:
        return "How would you describe last night's sleep?";
      default:
        return '';
    }
  }

  List<String> get _options {
    switch (_step) {
      case 0:
        return _restedOptions;
      case 1:
        return _fallingAsleepOptions;
      case 2:
        return _wakingOptions;
      case 3:
        return _sleepQualityOptions;
      default:
        return [];
    }
  }

  int? get _selectedAnswer {
    switch (_step) {
      case 0:
        return _restedAnswer;
      case 1:
        return _fallingAsleepAnswer;
      case 2:
        return _wakingAnswer;
      case 3:
        return _sleepQualityAnswer;
      default:
        return null;
    }
  }

  void _selectAnswer(int index) {
    setState(() {
      switch (_step) {
        case 0:
          _restedAnswer = index;
          break;
        case 1:
          _fallingAsleepAnswer = index;
          break;
        case 2:
          _wakingAnswer = index;
          break;
        case 3:
          _sleepQualityAnswer = index;
          break;
      }
    });
  }

  void _next() {
    if (!_currentAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an answer first.'),
        ),
      );
      return;
    }

    if (_isLastStep) {
      _finish();
      return;
    }

    setState(() {
      _step++;
    });
  }

  void _back() {
    if (_saving) return;

    if (_step > 0) {
      setState(() {
        _step--;
      });
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _finish() async {
    if (!_currentAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an answer first.'),
        ),
      );
      return;
    }

    final sessionId = _sessionId;

    if (sessionId == null || sessionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to find this sleep session.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final questionnaire = Questionnaire(
        // Question 4: Poor / Fair / Good / Very good
        sleepQuality: (_sleepQualityAnswer ?? 0) + 1,

        // Question 1: Not at all / A little / Fairly / Very
        feeling: _restedOptions[_restedAnswer ?? 0],

        // Question 3: None / Once / 2 to 3 times / 4 or more
        easeOfWaking: (_wakingAnswer ?? 0) + 1,

        // Question 2: Under 15 / 15-30 / Over 30 / Not sure
        easeOfFallingAsleep: (_fallingAsleepAnswer ?? 0) + 1,

        submittedAt: DateTime.now(),
      );

      await SessionService().saveQuestionnaire(
        sessionId,
        questionnaire,
      );

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      // Remove questionnaire + active session from navigation stack.
      // Dashboard becomes the new screen.
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.dashboard,
            (route) => route.settings.name == AppRoutes.home,
        arguments: sessionId,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save your answers: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: c.gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Material(
                      color: c.surfaceAlt,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _back,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.chevron_left,
                            color: c.text,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'SLEEP QUESTIONNAIRE',
                        style: text.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Progress
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                      (index) {
                    final active = index == _step;
                    final completed = index < _step;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active || completed
                            ? c.primary
                            : c.surfaceAlt,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Question ${_step + 1} of 4',
                style: text.bodySmall?.copyWith(
                  color: c.muted,
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    32,
                    20,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: c.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.nightlight_round,
                            size: 44,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      Center(
                        child: Text(
                          'How did you sleep?',
                          style: text.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Center(
                        child: Text(
                          _question,
                          style: text.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 28),

                      ...List.generate(
                        _options.length,
                            (index) {
                          final selected = _selectedAnswer == index;

                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 12,
                            ),
                            child: _OptionTile(
                              label: _options[index],
                              selected: selected,
                              onTap: () => _selectAnswer(index),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  28,
                ),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: AppButton(
                  label: _isLastStep ? 'Finish' : 'Next',
                  loading: _saving,
                  onPressed: _saving ? null : _next,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    final selectedTextColor =
        Theme.of(context).colorScheme.onPrimary;

    return Material(
      color: selected ? c.primary : c.surfaceAlt,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? selectedTextColor
                        : c.text,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? selectedTextColor
                        : c.muted,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: selectedTextColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}