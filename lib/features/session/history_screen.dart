import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../models/sleep_session.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _sessionService = SessionService();

  List<SleepSession> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sessions = await _sessionService.getSessions();

      final completedSessions =
      sessions.where((session) => session.isCompleted).toList();

      if (!mounted) return;

      setState(() {
        _sessions = completedSessions;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load your sleep history.';
      });
    }
  }

  String _duration(int minutes) {
    if (minutes <= 0) return '—';

    final hours = minutes ~/ 60;
    final mins = minutes % 60;

    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';

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
    final period = date.hour < 12 ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  void _openSession(SleepSession session) {
    Navigator.pushNamed(
      context,
      AppRoutes.dashboard,
      arguments: session.sessionId,
    );
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
                          child: Icon(
                            Icons.chevron_left,
                            color: c.text,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'SLEEP HISTORY',
                        style: text.labelSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

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
                    : _sessions.isEmpty
                    ? const _EmptyHistory()
                    : RefreshIndicator(
                  onRefresh: _load,
                  color: c.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      32,
                      20,
                      28,
                    ),
                    children: [
                      Text(
                        'Your sleep',
                        style: text.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_sessions.length} completed '
                            '${_sessions.length == 1 ? 'session' : 'sessions'}',
                        style: text.bodySmall,
                      ),
                      const SizedBox(height: 24),

                      ..._sessions.map(
                            (session) => Padding(
                          padding:
                          const EdgeInsets.only(bottom: 12),
                          child: _SleepHistoryCard(
                            date: _date(session.startTime),
                            startTime:
                            _time(session.startTime),
                            duration: _duration(
                              session.summary
                                  ?.totalSleepMinutes ??
                                  0,
                            ),
                            onTap: () =>
                                _openSession(session),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      AppCard(
                        alt: true,
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: c.text,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Tap a night to view its sleep details.',
                                style: text.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _SleepHistoryCard extends StatelessWidget {
  final String date;
  final String startTime;
  final String duration;
  final VoidCallback onTap;

  const _SleepHistoryCard({
    required this.date,
    required this.startTime,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return AppCard(
      alt: true,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.nightlight_outlined,
              color: c.text,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: text.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Started at $startTime',
                  style: text.bodySmall,
                ),
                const SizedBox(height: 8),
                Text(
                  duration,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Icon(
            Icons.chevron_right,
            color: c.muted,
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

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
                Icons.history,
                size: 48,
                color: c.text,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No sleep history yet',
              style: text.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first sleep session and it will appear here.',
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