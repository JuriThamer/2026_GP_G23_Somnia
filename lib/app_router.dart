import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'widgets/app_button.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/auth/sign_in_screen.dart';
class AppRoutes {
  static const dev = '/dev';
  static const welcome = '/welcome';
  static const signIn = '/signin';
  static const signUp = '/signup';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const watch = '/watch';
  static const activeSession = '/active-session';
  static const dashboard = '/dashboard';
  static const history = '/history';
  static const questionnaire = '/questionnaire';
  static const profile = '/profile';
  static const editProfile = '/edit-profile';
  static const settings = '/settings';
  static const sounds = '/sounds';

  static const screens = [
    welcome,
    signIn,
    signUp,
    forgotPassword,
    home,
    watch,
    activeSession,
    dashboard,
    history,
    questionnaire,
    profile,
    editProfile,
    settings,
    sounds,
  ];
}

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      AppRoutes.dev: (_) => const DevMenuScreen(),
      AppRoutes.welcome: (_) => const WelcomeScreen(),
      AppRoutes.signIn: (_) => const SignInScreen(),
      AppRoutes.signUp: (_) => const SignUpScreen(),
      AppRoutes.forgotPassword: (_) => const PlaceholderScreen('Forgot password'),
      AppRoutes.home: (_) => const PlaceholderScreen('Home'),
      AppRoutes.watch: (_) => const PlaceholderScreen('Watch'),
      AppRoutes.activeSession: (_) => const PlaceholderScreen('Active session'),
      AppRoutes.dashboard: (_) => const PlaceholderScreen('Dashboard'),
      AppRoutes.history: (_) => const PlaceholderScreen('History'),
      AppRoutes.questionnaire: (_) => const PlaceholderScreen('Questionnaire'),
      AppRoutes.profile: (_) => const PlaceholderScreen('Profile'),
      AppRoutes.editProfile: (_) => const PlaceholderScreen('Edit profile'),
      AppRoutes.settings: (_) => const PlaceholderScreen('Settings'),
      AppRoutes.sounds: (_) => const PlaceholderScreen('Sounds'),
    };
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.colors.gradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: text.headlineLarge),
                const SizedBox(height: 8),
                Text('Not built yet', style: text.bodySmall),
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
      ),
    );
  }
}

class DevMenuScreen extends StatelessWidget {
  const DevMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: context.colors.gradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Somnia', style: text.headlineLarge),
              const SizedBox(height: 4),
              Text('Developer menu', style: text.bodySmall),
              const SizedBox(height: 20),
              const AppButton(
                label: 'Switch theme',
                onPressed: toggleThemeMode,
              ),
              const SizedBox(height: 24),
              Text('SCREENS', style: text.labelSmall),
              const SizedBox(height: 12),
              for (final route in AppRoutes.screens)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppButton(
                    label: route,
                    style: AppButtonStyle.tonal,
                    onPressed: () => Navigator.pushNamed(context, route),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
