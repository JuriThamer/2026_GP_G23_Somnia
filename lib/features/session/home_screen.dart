import 'package:flutter/material.dart';
import '../../app_router.dart';
import '../../models/app_user.dart';
import '../../models/sleep_session.dart';
import '../../services/session_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _userService = UserService();
  final _sessionService = SessionService();

  Stream<AppUser?>? _userStream;
  SleepSession? _active;
  SleepSession? _latest;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    if (_userService.isSignedIn) {
      _userStream = _userService.watchUser();
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final active = await _sessionService.getActiveSession();
      final latest = await _sessionService.getLatestCompleted();
      if (!mounted) return;
      setState(() {
        _active = active;
        _latest = latest;
      });
    } catch (_) {}
  }

  Future<void> _open(String route, {Object? arguments}) async {
    await Navigator.pushNamed(context, route, arguments: arguments);
    if (mounted) _load();
  }

  Future<void> _start() async {
    final active = _active;
    if (active != null) {
      await _open(AppRoutes.activeSession, arguments: active.sessionId);
      return;
    }

    setState(() => _starting = true);
    try {
      final id = await _sessionService.startSession();
      if (!mounted) return;
      setState(() => _starting = false);
      await _open(AppRoutes.activeSession, arguments: id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start the session. Please try again.'),
        ),
      );
    }
  }

  String _duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  String _date(DateTime? d) {
    if (d == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    if (_userStream == null) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: c.gradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sign in first', style: text.headlineLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Home needs a signed-in account.',
                    style: text.bodySmall,
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Sign In',
                    onPressed: () => Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.signIn,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.gradient),
        child: SafeArea(
          bottom: false,
          child: StreamBuilder<AppUser?>(
            stream: _userStream,
            builder: (context, snapshot) {
              final user = snapshot.data;
              final name = user?.name ?? '';
              final initial = name.isEmpty ? '?' : name[0].toUpperCase();
              final connected = user?.watch != null;
              final hasActive = _active != null;
              final ready = connected || hasActive;

              final dialTitle = hasActive
                  ? 'In progress'
                  : connected
                      ? 'Ready'
                      : 'No watch';
              final dialLine = hasActive
                  ? 'A sleep session is already running.'
                  : connected
                      ? 'Your watch is connected.'
                      : 'Connect your watch to begin.';
              final buttonLabel = hasActive
                  ? 'Resume Session'
                  : connected
                      ? 'Start Sleep Session'
                      : 'Connect Watch';
              final hint = hasActive
                  ? 'Open the running session to end it.'
                  : connected
                      ? 'Start when you are in bed and ready to sleep.'
                      : 'Somnia needs your Galaxy Watch7 to sense the night.';

              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Material(
                                color: c.surfaceAlt,
                                shape: const StadiumBorder(),
                                child: InkWell(
                                  customBorder: const StadiumBorder(),
                                  onTap: () => _open(AppRoutes.watch),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.watch_outlined,
                                          size: 18,
                                          color: c.text,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          connected
                                              ? 'Connected'
                                              : 'Not connected',
                                          style: text.bodySmall!.copyWith(
                                            color: connected
                                                ? c.success
                                                : c.warning,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Material(
                                color: c.surfaceAlt,
                                shape: const CircleBorder(),
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () => _open(AppRoutes.settings),
                                  child: SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Center(
                                      child: Text(
                                        initial,
                                        style: text.headlineSmall,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: 272,
                            height: 272,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: ready ? c.primary : c.surfaceAlt,
                              shape: BoxShape.circle,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: c.background,
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('TONIGHT', style: text.labelSmall),
                                  const SizedBox(height: 6),
                                  Text(
                                    dialTitle,
                                    style: text.headlineLarge!.copyWith(
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    dialLine,
                                    style: text.bodySmall,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -34),
                            child: Container(
                              width: 282,
                              padding: const EdgeInsets.all(6),
                              decoration: ShapeDecoration(
                                color: c.background,
                                shape: const StadiumBorder(),
                              ),
                              child: AppButton(
                                label: buttonLabel,
                                loading: _starting,
                                onPressed: ready
                                    ? _start
                                    : () => _open(AppRoutes.watch),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -20),
                            child: Text(
                              hint,
                              style: text.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _Satellite(
                                icon: Icons.watch_outlined,
                                label: 'Watch',
                                value: connected ? 'Connected' : 'Not connected',
                                onTap: () => _open(AppRoutes.watch),
                              ),
                              const SizedBox(width: 36),
                              _Satellite(
                                icon: Icons.graphic_eq,
                                label: 'Sound',
                                value: 'White noise',
                                onTap: () => _open(AppRoutes.sounds),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        AppCard(
                          alt: true,
                          onTap: _latest == null
                              ? null
                              : () => _open(AppRoutes.dashboard),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _latest == null
                                          ? 'Latest sleep'
                                          : 'Latest sleep · ${_date(_latest!.startTime)}',
                                      style: text.bodySmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _latest == null
                                          ? 'No completed session yet'
                                          : '${_duration(_latest!.summary?.totalSleepMinutes ?? 0)} asleep',
                                      style: text.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                              if (_latest != null)
                                Icon(Icons.chevron_right, color: c.text),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _DockItem(
                              icon: Icons.bar_chart_rounded,
                              label: 'Dashboard',
                              onTap: () => _open(AppRoutes.dashboard),
                            ),
                            _DockItem(
                              icon: Icons.calendar_today_outlined,
                              label: 'History',
                              onTap: () => _open(AppRoutes.history),
                            ),
                            _DockItem(
                              icon: Icons.graphic_eq,
                              label: 'Sounds',
                              onTap: () => _open(AppRoutes.sounds),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Satellite extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _Satellite({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: c.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: c.text),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: text.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(value, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DockItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Icon(icon, color: c.text),
              const SizedBox(height: 4),
              Text(label, style: text.bodySmall!.copyWith(color: c.text)),
            ],
          ),
        ),
      ),
    );
  }
}