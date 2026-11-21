import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/user_service.dart';
import '../../services/watch_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';

class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  final _userService = UserService();
  final _watchService = WatchService();

  Stream<AppUser?>? _userStream;
  WatchInfo? _found;
  String? _busy = 'checking';
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_userService.isSignedIn) {
      _userStream = _userService.watchUser();
    }
    _find();
  }

  Future<void> _check() async {
    setState(() {
      _error = null;
      _busy = 'checking';
    });
    await _find();
  }

  Future<void> _find() async {
    final found = await _watchService.findWatch();
    if (!mounted) return;
    setState(() {
      _found = found;
      _busy = null;
    });
  }

  Future<void> _connect() async {
    setState(() {
      _error = null;
      _busy = 'searching';
    });
    final found = await _watchService.findWatch();
    if (!mounted) return;
    if (found == null) {
      setState(() {
        _found = null;
        _busy = null;
        _error = 'We could not find your watch. Check that it is switched on, nearby, that Bluetooth is on and that the Somnia watch app is installed, then try again.';
      });
      return;
    }
    setState(() {
      _found = found;
      _busy = 'connecting';
    });

    try {
      await _userService.updateWatch({
        'deviceId': found.id,
        'model': found.name,
        'connectedAt': Timestamp.now(),
      });
      if (!mounted) return;
      setState(() => _busy = null);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = null;
        _error = 'We could not connect to your watch. Check that it is switched on, nearby, and that Bluetooth is on, then try again.';
      });
    }
  }

  Future<void> _disconnect() async {
    setState(() => _error = null);
    try {
      await _userService.updateWatch(null);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not disconnect. Please try again.');
    }
  }

  void _showHelp() {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Connection ',
                  children: [
                    TextSpan(
                      text: 'help',
                      style: text.headlineLarge!.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                style: text.headlineLarge,
              ),
              const SizedBox(height: 14),
              Text(
                '1. Make sure your Galaxy Watch7 is switched on and charged.\n'
                '2. Keep the watch close to your phone.\n'
                '3. Check that Bluetooth is turned on.\n'
                '4. Wear the watch snugly on your wrist, then tap Connect again.',
                style: text.bodyMedium!.copyWith(color: c.muted),
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Got it',
                onPressed: () => Navigator.pop(dialogContext),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.gradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: StreamBuilder<AppUser?>(
              stream: _userStream,
              builder: (context, snapshot) {
                final watch = snapshot.data?.watch;
                final paired = watch != null;
                final connected = paired && _found != null;
                final busy = _busy != null;
                final failed = _error != null;

                final label = _busy == 'checking'
                    ? 'Checking…'
                    : _busy == 'searching'
                    ? 'Searching…'
                    : _busy == 'connecting'
                    ? 'Connecting…'
                    : failed
                    ? 'Connection failed'
                    : connected
                    ? 'Connected'
                    : paired
                    ? 'Out of reach'
                    : 'Not connected';
                final labelColor = busy
                    ? c.muted
                    : failed
                    ? c.error
                    : connected
                    ? c.success
                    : c.warning;
                final message = _busy == 'checking'
                    ? 'Looking for your watch…'
                    : _busy == 'searching'
                    ? 'Searching for a Galaxy Watch7. Keep the watch nearby, switched on and on your wrist.'
                    : _busy == 'connecting'
                    ? 'Galaxy Watch7 found. Connecting…'
                    : failed
                    ? _error!
                    : connected
                    ? 'Your watch is connected and ready for a sleep session.'
                    : paired
                    ? 'Your watch is paired, but Somnia cannot reach it right now. Keep it nearby with Bluetooth on, then check again.'
                    : 'Your watch is not connected. Somnia will search for a supported Galaxy Watch7 nearby.';

                return Column(
                  children: [
                    Row(
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
                            'WATCH CONNECTION',
                            style: text.labelSmall,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 40),
                    Container(
                      width: 200,
                      height: 200,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: connected && !busy ? c.primary : c.surfaceAlt,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: c.background,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: busy
                              ? SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: c.primary,
                                  ),
                                )
                              : Icon(
                                  Icons.watch_outlined,
                                  size: 64,
                                  color: c.text,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Galaxy Watch7', style: text.headlineLarge),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: labelColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: text.bodyLarge!.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        message,
                        style: text.bodyMedium!.copyWith(color: c.muted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),
                    if (!paired)
                      AppButton(
                        label: failed ? 'Try Again' : 'Connect Watch',
                        loading: busy,
                        onPressed: busy ? null : _connect,
                      ),
                    if (paired) ...[
                      if (connected)
                        AppButton(
                          label: 'Done',
                          onPressed: () => Navigator.pop(context),
                        )
                      else
                        AppButton(
                          label: 'Check Again',
                          loading: busy,
                          onPressed: busy ? null : _check,
                        ),
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Disconnect',
                        style: AppButtonStyle.tonal,
                        onPressed: _disconnect,
                      ),
                    ],
                    const SizedBox(height: 6),
                    AppButton(
                      label: 'View connection help',
                      style: AppButtonStyle.text,
                      onPressed: _showHelp,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}