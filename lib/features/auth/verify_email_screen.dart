import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/app_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _userService = UserService();

  bool _checking = false;
  bool _resending = false;
  String? _message;
  bool _messageIsError = false;

  void _show(String message, {bool error = false}) {
    setState(() {
      _message = message;
      _messageIsError = error;
    });
  }

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _message = null;
    });

    try {
      final verified = await _userService.reloadEmailVerified();

      if (!mounted) return;

      if (!verified) {
        setState(() => _checking = false);
        _show(
          'Your email is not verified yet. Open the link we sent you, then try again.',
          error: true,
        );
        return;
      }

      final user = await _userService.getUser();
      if (user != null) {
        setThemeMode(user.themeMode);
      }

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      _show(
        e.code == 'network-request-failed'
            ? 'No internet connection. Please try again.'
            : 'Could not check your email. Please try again.',
        error: true,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _checking = false);
      _show('Could not check your email. Please try again.', error: true);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _message = null;
    });

    try {
      await _userService.sendEmailVerification();
      if (!mounted) return;
      setState(() => _resending = false);
      _show('A new verification link has been sent to your email.');
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _resending = false);
      if (e.code == 'too-many-requests') {
        _show(
          'Too many requests. Please wait a moment before asking for another link.',
          error: true,
        );
      } else if (e.code == 'network-request-failed') {
        _show('No internet connection. Please try again.', error: true);
      } else {
        _show('Could not send the link. Please try again.', error: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _resending = false);
      _show('Could not send the link. Please try again.', error: true);
    }
  }

  Future<void> _backToSignIn() async {
    await _userService.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.signIn,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final email = _userService.email ?? 'your email';
    final busy = _checking || _resending;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: c.gradient),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                SizedBox(
                  height: 48,
                  child: Center(
                    child: Text(
                      'VERIFY EMAIL',
                      style: text.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text.rich(
                  TextSpan(
                    text: 'Check your ',
                    children: [
                      TextSpan(
                        text: 'email',
                        style: text.headlineLarge!.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  style: text.headlineLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a verification link to $email. Open the link, then come back and tap the button below.',
                  style: text.bodyMedium,
                ),
                const SizedBox(height: 18),
                if (_message != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _messageIsError ? c.error : c.success,
                      ),
                    ),
                    child: Text(
                      _message!,
                      style: text.bodyMedium!.copyWith(
                        color: _messageIsError ? c.error : c.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 10),
                AppButton(
                  label: "I've verified my email",
                  loading: _checking,
                  onPressed: busy ? null : _check,
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Resend link',
                  style: AppButtonStyle.secondary,
                  loading: _resending,
                  onPressed: busy ? null : _resend,
                ),
                const SizedBox(height: 8),
                Center(
                  child: AppButton(
                    label: 'Back to sign in',
                    style: AppButtonStyle.text,
                    onPressed: busy ? null : _backToSignIn,
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
