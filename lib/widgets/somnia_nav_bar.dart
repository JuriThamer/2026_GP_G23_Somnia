import 'package:flutter/material.dart';

import '../app_router.dart';
import '../models/app_user.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

/// The four main sections of the bottom navigation bar.
/// [NavTab.none] is used on pages that show the bar without a selected tab
/// (Settings, Profile, Edit Profile, Watch, Smart Alarm).
enum NavTab { home, dashboard, history, tones, none }

/// Bottom navigation bar shown on every signed-in page except the active
/// sleep session and the Rest Review that follows it.
class SomniaNavBar extends StatelessWidget {
  final NavTab current;

  const SomniaNavBar({super.key, this.current = NavTab.none});

  static const _items = [
    (NavTab.home, Icons.home_rounded, 'Home', AppRoutes.home),
    (NavTab.dashboard, Icons.bar_chart_rounded, 'Dashboard', AppRoutes.dashboard),
    (NavTab.history, Icons.calendar_today_outlined, 'History', AppRoutes.history),
  ];

  void _go(BuildContext context, NavTab tab, String route) {
    if (tab == current) return;
    if (tab == NavTab.home) {
      // Home is the root page after sign-in, so go back to it.
      Navigator.popUntil(context, ModalRoute.withName(AppRoutes.home));
      return;
    }
    // Open the section on top of Home and close everything in between,
    // so the back stack never grows when moving between sections.
    Navigator.pushNamedAndRemoveUntil(
      context,
      route,
      ModalRoute.withName(AppRoutes.home),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Row(
            children: [
              for (final (tab, icon, label, route) in _items)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: tab == current,
                    label: label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _go(context, tab, route),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: tab == current
                                    ? c.primary.withValues(alpha: 0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                icon,
                                color: tab == current ? c.primary : c.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall!.copyWith(
                                color: tab == current ? c.primary : c.muted,
                                fontWeight: tab == current
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
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

/// The user's initial in a circle with a small gear badge.
/// Shown at the top of Home, Dashboard, History and Tranquil Tones;
/// opens Settings.
class SettingsAvatar extends StatelessWidget {
  const SettingsAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return StreamBuilder<AppUser?>(
      stream: UserService().watchUser(),
      builder: (context, snapshot) {
        final name = snapshot.data?.name ?? '';
        final initial = name.isEmpty ? '?' : name[0].toUpperCase();

        return Tooltip(
          message: 'Settings',
          child: Semantics(
            button: true,
            label: 'Settings',
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Material(
                    color: c.surfaceAlt,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.settings),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: Text(initial, style: text.headlineSmall),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: IgnorePointer(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.background, width: 2),
                        ),
                        child: Icon(
                          Icons.settings,
                          size: 11,
                          color: c.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}