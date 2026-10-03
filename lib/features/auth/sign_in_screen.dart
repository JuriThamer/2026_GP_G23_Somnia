import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../app_router.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _userService = UserService();

  String? _emailError;
  String? _passwordError;
  String? _authError;
  bool _showPassword = false;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _email.text.trim();
    final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    setState(() {
      _authError = null;
      _emailError = email.isEmpty
          ? 'Enter your email address.'
          : emailOk
              ? null
              : 'Enter a valid email address.';
      _passwordError = _password.text.isEmpty ? 'Enter your password.' : null;
    });

    return _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _loading = true);

    try {
      await _userService.signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _loading = false;
        if (e.code == 'network-request-failed') {
          _authError = 'No internet connection. Please try again.';
        } else if (e.code == 'too-many-requests') {
          _authError = 'Too many attempts. Please try again later.';
        } else {
          _authError = 'Email or password is incorrect. Please try again.';
        }
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _authError = 'Could not sign you in. Please try again.';
      });
    }
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
                      'SIGN IN',
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
                  text: 'Welcome ',
                  children: [
                    TextSpan(
                      text: 'back',
                      style: text.headlineLarge!
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                style: text.headlineLarge,
              ),
              const SizedBox(height: 18),
              if (_authError != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.error),
                  ),
                  child: Text(
                    _authError!,
                    style: text.bodyMedium!.copyWith(color: c.error),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              AppTextField(
                label: 'Email',
                hint: 'you@example.com',
                controller: _email,
                errorText: _emailError,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Password',
                hint: 'Your password',
                controller: _password,
                errorText: _passwordError,
                obscureText: !_showPassword,
                suffix: TextButton(
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  child: Text(
                    _showPassword ? 'Hide' : 'Show',
                    style: text.bodyMedium!.copyWith(
                      color: c.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Sign In',
                loading: _loading,
                onPressed: _submit,
              ),
              const SizedBox(height: 8),
              Center(
                child: AppButton(
                  label: 'Forgot password?',
                  style: AppButtonStyle.text,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.forgotPassword,
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