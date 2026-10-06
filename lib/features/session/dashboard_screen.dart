import 'package:flutter/material.dart';

import '../../models/sleep_session.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _sessionService = SessionService();

  SleepSession? _session;
  bool _loading = true;
  String? _error;

  String? _sessionId;
  bool _didReadArguments = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didReadArguments) return;

    _didReadArguments = true;

    final arguments = ModalRoute.of(context)?.settings.arguments;

    if (arguments is String && arguments.isNotEmpty) {
      _sessionId = arguments;
    }

    _load();
  }

  Future<void> _load() async {
    try {
      SleepSession? session;

      if (_sessionId != null) {
        session = await _sessionService.getSession(_sessionId!);
      } else {
        session = await _sessionService.getLatestCompleted();
      }

      if (!mounted) return;

      setState(() {
        _session = session;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load your sleep data.';
      });
    }
  }

  String _duration(int minutes) {
    if (minutes <= 0) return '—';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) {
      return '${mins}m';
    }

    if (mins == 0) {
      return '${hours}h';
    }

    return '${hours}h ${mins}m';
  }

  String _date(DateTime? date) {
    if (date == null) return '—';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _time(DateTime? date) {
    if (date == null) return '—';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  String _stageName(String key) {
    switch (key.toLowerCase()) {
      case 'wake':
        return 'Wake';
      case 'light':
        return 'Light';
      case 'deep':
        return 'Deep';
      case 'rem':
        return 'REM';
      default:
        return key;
    }
  }

  String _questionnaireSleepQuality(int value) {
    const options = [
      'Unknown',
      'Poor',
      'Fair',
      'Good',
      'Very good',
    ];

    if (value >= 0 && value < options.length) {
      return options[value];
    }

    return '—';
  }

  String _questionnaireScale(
      int value,
      List<String> options,
      ) {
    final index = value - 1;

    if (index >= 0 && index < options.length) {
      return options[index];
    }

    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: c.gradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _Header(),

              Expanded(
                child: _loading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: c.primary,
                  ),
                )
                    : _error != null
                    ? _ErrorState(
                  message: _error!,
                  onRetry: _load,
                )
                    : _session == null
                    ? const _EmptyState()
                    : RefreshIndicator(
                  onRefresh: _load,
                  color: c.primary,
                  child: _DashboardContent(
                    session: _session!,
                    duration: _duration,
                    date: _date,
                    time: _time,
                    stageName: _stageName,
                    questionnaireSleepQuality:
                    _questionnaireSleepQuality,
                    questionnaireScale:
                    _questionnaireScale,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Padding(
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
                child: Icon(
                  Icons.chevron_left,
                  color: c.text,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'SLEEP DASHBOARD',
              style: text.labelSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final SleepSession session;

  final String Function(int) duration;
  final String Function(DateTime?) date;
  final String Function(DateTime?) time;
  final String Function(String) stageName;

  final String Function(int) questionnaireSleepQuality;
  final String Function(int, List<String>) questionnaireScale;

  const _DashboardContent({
    required this.session,
    required this.duration,
    required this.date,
    required this.time,
    required this.stageName,
    required this.questionnaireSleepQuality,
    required this.questionnaireScale,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    final summary = session.summary;
    final questionnaire = session.questionnaire;

    if (summary == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
        children: [
          Text(
            'Your latest sleep',
            style: text.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            date(session.startTime),
            style: text.bodySmall,
          ),
          const SizedBox(height: 28),
          AppCard(
            child: Column(
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  size: 48,
                  color: c.text,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sleep results are not ready yet',
                  style: text.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Somnia has not received the sleep summary for this session yet.',
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      children: [
        Text(
          'Your latest sleep',
          style: text.headlineLarge,
        ),
        const SizedBox(height: 6),
        Text(
          date(session.startTime),
          style: text.bodySmall,
        ),

        const SizedBox(height: 24),

        // Main sleep duration
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.primary,
            shape: BoxShape.circle,
          ),
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: c.background,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'TOTAL SLEEP',
                    style: text.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    duration(summary.totalSleepMinutes),
                    style: text.headlineLarge?.copyWith(
                      fontSize: 42,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Wearable-based estimate',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Basic facts
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.bed_outlined,
                title: 'In bed',
                value: duration(summary.inBedMinutes),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.nightlight_outlined,
                title: 'Sleep time',
                value: time(summary.sleepTime),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.wb_sunny_outlined,
                title: 'Wake time',
                value: time(summary.wakeTime),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.calendar_today_outlined,
                title: 'Date',
                value: date(session.startTime),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        Text(
          'Body signals',
          style: text.titleLarge,
        ),
        const SizedBox(height: 12),

        _SignalCard(
          icon: Icons.favorite_border,
          title: 'Average heart rate',
          value: summary.avgHeartRate == null
              ? '—'
              : '${summary.avgHeartRate!.toStringAsFixed(0)} BPM',
        ),

        const SizedBox(height: 10),

        _SignalCard(
          icon: Icons.thermostat_outlined,
          title: 'Skin temperature',
          value: summary.avgSkinTemp == null
              ? '—'
              : '${summary.avgSkinTemp!.toStringAsFixed(1)} °C',
        ),

        const SizedBox(height: 10),

        _SignalCard(
          icon: Icons.self_improvement_outlined,
          title: 'Stillness',
          value: summary.stillnessPercent == null
              ? '—'
              : '${summary.stillnessPercent!.toStringAsFixed(0)}%',
        ),

        const SizedBox(height: 28),

        Text(
          'Sleep stages',
          style: text.titleLarge,
        ),
        const SizedBox(height: 12),

        AppCard(
          alt: true,
          child: summary.stages.isEmpty
              ? SizedBox(
            height: 180,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 42,
                  color: c.muted,
                ),
                const SizedBox(height: 12),
                Text(
                  'Sleep stage results are not ready yet',
                  style: text.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Your Light and Deep sleep data will appear here after analysis.',
                  style: text.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
              : Column(
            children: summary.stages.entries.map((entry) {
              final stage = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stageName(entry.key),
                        style: text.bodyLarge,
                      ),
                    ),
                    Text(
                      duration(stage.minutes),
                      style: text.bodyMedium,
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${stage.percent}%',
                        textAlign: TextAlign.end,
                        style: text.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        if (questionnaire != null) ...[
          const SizedBox(height: 28),

          Text(
            'You reported',
            style: text.titleLarge,
          ),
          const SizedBox(height: 12),

          AppCard(
            alt: true,
            child: Column(
              children: [
                _AnswerRow(
                  title: 'Sleep quality',
                  value: questionnaireSleepQuality(
                    questionnaire.sleepQuality,
                  ),
                ),
                const Divider(),
                _AnswerRow(
                  title: 'How rested you feel',
                  value: questionnaire.feeling,
                ),
                const Divider(),
                _AnswerRow(
                  title: 'Remembered awakenings',
                  value: questionnaireScale(
                    questionnaire.easeOfWaking,
                    [
                      'None',
                      'Once',
                      '2 to 3 times',
                      '4 or more',
                    ],
                  ),
                ),
                const Divider(),
                _AnswerRow(
                  title: 'Time to fall asleep',
                  value: questionnaireScale(
                    questionnaire.easeOfFallingAsleep,
                    [
                      'Under 15 min',
                      '15 to 30 min',
                      'Over 30 min',
                      'Not sure',
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return AppCard(
      alt: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: c.text,
            size: 24,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: text.bodySmall,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SignalCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return AppCard(
      alt: true,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: c.text,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: text.bodyLarge,
            ),
          ),
          Text(
            value,
            style: text.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String title;
  final String value;

  const _AnswerRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: text.bodyMedium,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: text.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.nightlight_outlined,
                size: 48,
                color: c.text,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No sleep data yet',
              style: text.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first sleep session and your results will appear here.',
              style: text.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: c.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}