import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_controller.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../app_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();

  bool _isDarkMode = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final user = await _userService.getUser();

    if (!mounted) return;

    final mode = user?.themeMode ?? 'dark';

    setThemeMode(mode);

    setState(() {
      _isDarkMode = mode != 'light';
      _loading = false;
    });
  }

  Future<void> _changeTheme(bool isDark) async {
    final mode = isDark ? 'dark' : 'light';

    // Change immediately in the app.
    setThemeMode(mode);

    setState(() {
      _isDarkMode = isDark;
    });

    // Save the selected theme in Firestore.
    await _userService.updateTheme(mode);
  }

  Future<void> _signOut() async {
    await _userService.signOut();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.welcome,
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    if (_loading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: colors.gradient,
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.gradient,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Material(
                    color: colors.surfaceAlt,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.chevron_left,
                          color: colors.text,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  Text(
                    'Settings',
                    style: text.headlineLarge,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Manage your Somnia preferences',
                style: text.bodySmall,
              ),

              const SizedBox(height: 28),

              Text(
                'APPEARANCE',
                style: text.labelSmall,
              ),

              const SizedBox(height: 12),

              AppCard(
                child: Row(
                  children: [
                    Icon(
                      _isDarkMode
                          ? Icons.dark_mode_outlined
                          : Icons.light_mode_outlined,
                      color: colors.text,
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dark mode',
                            style: text.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isDarkMode
                                ? 'Dark theme is enabled'
                                : 'Light theme is enabled',
                            style: text.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    Switch(
                      value: _isDarkMode,
                      onChanged: _changeTheme,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'ACCOUNT',
                style: text.labelSmall,
              ),

              const SizedBox(height: 12),

              AppCard(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.profile,
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      color: colors.text,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Profile',
                        style: text.bodyLarge,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colors.muted,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              AppCard(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.editProfile,
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: colors.text,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Edit profile',
                        style: text.bodyLarge,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colors.muted,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Text(
                'PREFERENCES',
                style: text.labelSmall,
              ),

              const SizedBox(height: 12),

              AppCard(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.watch,
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.watch_outlined,
                      color: colors.text,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Watch',
                        style: text.bodyLarge,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colors.muted,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              AppCard(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.sounds,
                  );
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.music_note_outlined,
                      color: colors.text,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Sounds',
                        style: text.bodyLarge,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colors.muted,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              AppButton(
                label: 'Sign out',
                style: AppButtonStyle.secondary,
                onPressed: _signOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}