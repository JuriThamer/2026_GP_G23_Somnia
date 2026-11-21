import 'package:flutter/material.dart';

import '../../app_router.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    String route;

    if (!_userService.isSignedIn) {
      route = AppRoutes.welcome;
    } else {
      bool verified;

      try {
        verified = await _userService.reloadEmailVerified();
      } catch (_) {
        verified = _userService.isEmailVerified;
      }

      if (!_userService.isSignedIn) {
        route = AppRoutes.welcome;
      } else if (!verified) {
        route = AppRoutes.verifyEmail;
      } else {
        try {
          final user = await _userService.getUser();
          if (user != null) {
            setThemeMode(user.themeMode);
          }
        } catch (_) {}
        route = AppRoutes.home;
      }
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: c.gradient),
        child: Center(
          child: CircularProgressIndicator(color: c.primary),
        ),
      ),
    );
  }
}
