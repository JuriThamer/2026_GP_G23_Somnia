import 'package:flutter/material.dart';
import '../../app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final title = text.headlineLarge!.copyWith(fontSize: 36);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.gradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Container(
                    width: 280,
                    height: 280,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F1E3),
                        shape: BoxShape.circle,
                      ),
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Image.asset('assets/images/logo.png'),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                ),
                child: Column(
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'One night,\nfrom sensing ',
                        children: [
                          TextSpan(
                            text: 'to insight.',
                            style: title.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                      style: title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your Galaxy Watch7 senses the night. Somnia shows your estimated sleep stages in the morning.',
                      style: text.bodyMedium!.copyWith(color: c.muted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Create Account',
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.signUp),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: 'Sign In',
                      style: AppButtonStyle.secondary,
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoutes.signIn),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}