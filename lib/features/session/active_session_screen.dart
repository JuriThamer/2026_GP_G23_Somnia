import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../models/app_user.dart';
import '../../services/session_service.dart';
import '../../services/user_service.dart';
import '../../services/watch_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';

class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  final _userService = UserService();
  final _sessionService = SessionService();
  final _watchService = WatchService();

  Stream<AppUser?>? _userStream;
  Timer? _timer;
  String? _sessionId;
  DateTime? _start;
  Duration _elapsed = Duration.zero;
  bool _loading = true;
  bool _ending = false;
  bool _started = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    _load(args is String ? args : null);
  }

  Future<void> _load(String? id) async {
    if (!_userService.isSignedIn) {
      setState(() => _loading = false);
      return;
    }
    _userStream = _userService.watchUser();

    try {
      final session = id != null
          ? await _sessionService.getSession(id)
          : await _sessionService.getActiveSession();
      if (!mounted) return;

      if (session == null || !session.isActive) {
        setState(() => _loading = false);
        return;
      }

      setState(() {
        _sessionId = session.sessionId;
        _start = session.startTime;
        _elapsed = DateTime.now().difference(_start!);
        _loading = false;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed = DateTime.now().difference(_start!));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String get _clock {
    final s = _elapsed.isNegative ? 0 : _elapsed.inSeconds;
    return '${_two(s ~/ 3600)}:${_two((s ~/ 60) % 60)}:${_two(s % 60)}';
  }

  String get _startedLine {
    final d = _start;
    if (d == null) return '';
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
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final period = d.hour < 12 ? 'AM' : 'PM';
    return 'Started $hour:${_two(d.minute)} $period · ${d.day} ${months[d.month - 1]}';
  }

  Future<void> _askEnd() async {
    if (_ending) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Theme(
        data: AppTheme.dark,
        child: Builder(
          builder: (themed) {
            final c = themed.colors;
            final text = Theme.of(themed).textTheme;
            return Dialog(
              backgroundColor: c.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'End sleep ',
                        children: [
                          TextSpan(
                            text: 'session',
                            style: text.headlineLarge!.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const TextSpan(text: '?'),
                        ],
                      ),
                      style: text.headlineLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your watch will stop recording for this session and you will continue to a short questionnaire.',
                      style: text.bodyMedium!.copyWith(color: c.muted),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'End Session',
                      onPressed: () => Navigator.pop(dialogContext, true),
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Keep Sleeping',
                      style: AppButtonStyle.secondary,
                      onPressed: () => Navigator.pop(dialogContext, false),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _ending = true;
      _error = null;
    });

    try {
      await _sessionService.endSession(_sessionId!);
      await _watchService.stopRecording(_sessionId!);
      _timer?.cancel();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.questionnaire,
        arguments: _sessionId,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ending = false;
        _error = 'The session could not be ended, so it is still open. Check your connection and try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark,
      child: Builder(builder: _content),
    );
  }

  Widget _content(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    const night = Color(0xFF0E0A16);

    if (_loading) {
      return Scaffold(
        backgroundColor: night,
        body: Center(child: CircularProgressIndicator(color: c.primary)),
      );
    }

    if (_sessionId == null) {
      return Scaffold(
        backgroundColor: night,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('No active session', style: text.headlineLarge),
                const SizedBox(height: 8),
                Text('Start a sleep session from Home.', style: text.bodySmall),
                const SizedBox(height: 32),
                AppButton(
                  label: 'Back',
                  style: AppButtonStyle.secondary,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: night,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: c.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text.rich(
                          TextSpan(
                            text: 'Sleep session ',
                            children: [
                              TextSpan(
                                text: 'active',
                                style: text.headlineSmall!.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          style: text.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: 272,
                      height: 272,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: night,
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('ELAPSED', style: text.labelSmall),
                            const SizedBox(height: 6),
                            Text(
                              _clock,
                              style: text.headlineLarge!.copyWith(
                                fontSize: 50,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(_startedLine, style: text.bodySmall),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Keep your watch on your wrist. You can lock your phone and go to sleep.',
                      style: text.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    StreamBuilder<AppUser?>(
                      stream: _userStream,
                      builder: (context, snapshot) {
                        final connected = snapshot.data?.watch != null;
                        final color = connected ? c.success : c.error;
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: c.surfaceAlt,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Galaxy Watch7', style: text.bodySmall),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    connected ? 'Connected' : 'Connection lost',
                                    style: text.bodyMedium!.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: c.error),
                        ),
                        child: Text(
                          _error!,
                          style: text.bodyMedium!.copyWith(color: c.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: AppButton(
                label: 'End Sleep Session',
                style: AppButtonStyle.secondary,
                loading: _ending,
                onPressed: _askEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }
}