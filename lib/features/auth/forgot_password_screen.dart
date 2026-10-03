import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  final _userService = UserService();

  String? _emailError;
  String? _authError;
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    if (!emailOk) {
      setState(() {
        _authError = null;
        _emailError = 'Enter a valid email address.';
      });
      return;
    }

    setState(() {
      _emailError = null;
      _authError = null;
      _loading = true;
    });

    try {
      await _userService.sendPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sent = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        if (e.code == 'invalid-email') {
          _emailError = 'Enter a valid email address.';
        } else if (e.code == 'network-request-failed') {
          _authError = 'No internet connection. Please try again.';
        } else {
          _authError = 'Could not send the reset link. Please try again.';
        }
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _authError = 'Could not send the reset link. Please try again.';
      });
    }
  }

  Widget _banner(String message, Color color) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(message, style: text.bodyMedium!.copyWith(color: color)),
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                      'FORGOT PASSWORD',
                      style: text.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  text: 'Reset your ',
                  children: [
                    TextSpan(
                      text: 'password',
                      style: text.headlineLarge!
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                style: text.headlineLarge,
              ),
              const SizedBox(height: 14),
              if (_sent) ...[
                _banner(
                  'Reset link sent. Check your inbox at ${_email.text.trim()}.',
                  c.success,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Back to Sign In',
                  onPressed: () => Navigator.pop(context),
                ),
              ] else ...[
                Text(
                  'Enter your email and we will send you a link to reset your password.',
                  style: text.bodyMedium!.copyWith(color: c.muted),
                ),
                const SizedBox(height: 18),
                if (_authError != null) ...[
                  _banner(_authError!, c.error),
                  const SizedBox(height: 14),
                ],
                AppTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _email,
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: 'Send Reset Link',
                  loading: _loading,
                  onPressed: _submit,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}