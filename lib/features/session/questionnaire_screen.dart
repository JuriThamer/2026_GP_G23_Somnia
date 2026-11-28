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
  final _sessionService = SessionService();

  String? _sessionId;
  bool _didReadArguments = false;
  bool _loading = true;
  bool _hasTone = false;
  int _step = 0;

  int? _sleepiness;
  String? _sleepInertia;
  int? _toneRelaxing;
  String? _toneReuse;
  List<String> _sleepFactors = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didReadArguments) return;

    _didReadArguments = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is String && arguments.isNotEmpty) {
      _sessionId = arguments;
    }

    _loadSession();
  }

  Future<void> _loadSession() async {
    var hasTone = false;

    if (_sessionId != null) {
      try {
        final session = await _sessionService.getSession(_sessionId!);
        hasTone = session?.hasTone ?? false;
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _hasTone = hasTone;
      _loading = false;
    });
  }

  List<int> get _questions => RestReview.questionsFor(hasTone: _hasTone);

  int get _question => _questions[_step];

  bool get _isLastStep => _step == _questions.length - 1;

  RestReview _buildReview({DateTime? submittedAt}) {
    return RestReview(
      sleepiness: _sleepiness,
      sleepInertia: _sleepInertia,
      toneRelaxing: _hasTone ? _toneRelaxing : null,
      toneReuse: _hasTone ? _toneReuse : null,
      sleepFactors: _sleepFactors,
      submittedAt: submittedAt,
    );
  }

  String get _questionText {
    switch (_question) {
      case 1:
        return 'How sleepy do you feel right now?';
      case 2:
        return 'Did you feel heavy or slow during the first minutes after waking?';
      case 3:
        return 'Did the tone help you relax?';
      case 4:
        return 'Would you use this tone again?';
      case 5:
        return 'Did anything unusual affect your sleep last night?';
      default:
        return '';
    }
  }

  List<_Option> get _options {
    switch (_question) {
      case 2:
        return RestReview.sleepInertiaOptions.entries.map((entry) {
          return _Option(
            label: entry.value,
            selected: _sleepInertia == entry.key,
            onTap: () => setState(() => _sleepInertia = entry.key),
          );
        }).toList();
      case 3:
        return List.generate(5, (index) {
          final value = index + 1;
          final label = value == 1
              ? '1 · Not at all'
              : value == 5
              ? '5 · A lot'
              : '$value';
          return _Option(
            label: label,
            selected: _toneRelaxing == value,
            onTap: () => setState(() => _toneRelaxing = value),
          );
        });
      case 4:
        return RestReview.toneReuseOptions.entries.map((entry) {
          return _Option(
            label: entry.value,
            selected: _toneReuse == entry.key,
            onTap: () => setState(() => _toneReuse = entry.key),
          );
        }).toList();
      case 5:
        return RestReview.sleepFactorOptions.entries.map((entry) {
          return _Option(
            label: entry.value,
            selected: _sleepFactors.contains(entry.key),
            onTap: () => _toggleFactor(entry.key),
          );
        }).toList();

      default:
        return [];
    }
  }

  Widget _buildRatingSlider({
    required int min,
    required int max,
    required int? value,
    required String minLabel,
    required String maxLabel,
    required ValueChanged<int> onChanged,
  }) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    final displayValue = value ?? ((min + max) ~/ 2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            value == null ? 'Select a rating' : '$value / $max',
            style: text.headlineLarge?.copyWith(
              color: c.primary,
            ),
          ),
          const SizedBox(height: 20),
          Slider(
            value: displayValue.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: max - min,
            activeColor: c.primary,
            inactiveColor: c.muted.withOpacity(0.25),
            onChanged: (newValue) {
              onChanged(newValue.round());
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  minLabel,
                  style: text.bodySmall?.copyWith(
                    color: c.muted,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  maxLabel,
                  textAlign: TextAlign.end,
                  style: text.bodySmall?.copyWith(
                    color: c.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _toggleFactor(String key) {
    setState(() {
      if (key == 'none') {
        _sleepFactors = _sleepFactors.contains('none') ? [] : ['none'];
        return;
      }

      final factors = _sleepFactors.where((f) => f != 'none').toList();

      if (factors.contains(key)) {
        factors.remove(key);
      } else {
        factors.add(key);
      }

      _sleepFactors = factors;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _next() {
    if (!_buildReview().isAnswered(_question)) {
      _showMessage('Please answer this question first.');
      return;
    }

    if (_isLastStep) {
      _submit();
      return;
    }

    setState(() {
      _step++;
    });
  }

  void _previous() {
    if (_step > 0) {
      setState(() {
        _step--;
      });
    }
  }

  void _submit() {
    final sessionId = _sessionId;

    if (sessionId == null) {
      _showMessage('Unable to find this sleep session.');
      return;
    }

    final review = _buildReview(submittedAt: DateTime.now());

    if (!review.validate(hasTone: _hasTone)) {
      final missing = _questions.indexWhere((q) => !review.isAnswered(q));
      setState(() {
        _step = missing < 0 ? 0 : missing;
      });
      _showMessage('Please answer this question first.');
      return;
    }

    _sessionService.saveRestReview(sessionId, review).catchError((_) {});

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.dashboard,
      (route) => route.settings.name == AppRoutes.home,
      arguments: sessionId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _previous();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: c.gradient),
          child: SafeArea(
            child: _loading
                ? Center(
              child: CircularProgressIndicator(color: c.primary),
            )
                : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _step > 0
                          ? Material(
                        color: c.surfaceAlt,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _previous,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              Icons.chevron_left,
                              color: c.text,
                            ),
                          ),
                        ),
                      )
                          : const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          'REST REVIEW',
                          style: text.labelSmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_questions.length, (index) {
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
                  }),
                ),
                const SizedBox(height: 12),
                Text(
                  'Question ${_step + 1} of ${_questions.length}',
                  style: text.bodySmall?.copyWith(color: c.muted),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
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
                            _questionText,
                            style: text.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (_question == 5) ...[
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              'Select all that apply.',
                              style: text.bodySmall?.copyWith(
                                color: c.muted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),

                        if (_question == 1)
                          _buildRatingSlider(
                            min: 1,
                            max: 9,
                            value: _sleepiness,
                            minLabel: 'Extremely alert',
                            maxLabel: 'Extremely sleepy',
                            onChanged: (value) {
                              setState(() => _sleepiness = value);
                            },
                          )
                        else if (_question == 3)
                          _buildRatingSlider(
                            min: 1,
                            max: 5,
                            value: _toneRelaxing,
                            minLabel: 'Not at all',
                            maxLabel: 'A lot',
                            onChanged: (value) {
                              setState(() => _toneRelaxing = value);
                            },
                          )
                        else
                          ..._options.map(
                                (option) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _OptionTile(
                                label: option.label,
                                selected: option.selected,
                                multiSelect: _question == 5,
                                onTap: option.onTap,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: AppButton(
                    label: _isLastStep ? 'Submit' : 'Next',
                    loading: false,
                    onPressed: _next,
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

class _Option {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.label,
    required this.selected,
    required this.onTap,
  });
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool multiSelect;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.multiSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    final selectedTextColor = Theme.of(context).colorScheme.onPrimary;
    final borderColor = selected ? selectedTextColor : c.muted;

    return Material(
      color: selected ? c.primary : c.surfaceAlt,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? selectedTextColor : c.text,
                  ),
                ),
              ),
              multiSelect
                  ? Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: selected
                    ? Icon(
                  Icons.check,
                  size: 16,
                  color: selectedTextColor,
                )
                    : null,
              )
                  : Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
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