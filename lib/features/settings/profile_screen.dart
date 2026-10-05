import 'package:flutter/material.dart';

import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final userService = UserService();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: colors.gradient,
        ),
        child: SafeArea(
          child: StreamBuilder(
            stream: userService.watchUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final user = snapshot.data;

              if (user == null) {
                return Center(
                  child: Text(
                    'Unable to load profile.',
                    style: text.bodyLarge,
                  ),
                );
              }

              return ListView(
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
                        'Profile',
                        style: text.headlineLarge,
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Your account information',
                    style: text.bodySmall,
                  ),

                  const SizedBox(height: 28),

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NAME',
                          style: text.labelSmall,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          user.name,
                          style: text.bodyLarge,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EMAIL',
                          style: text.labelSmall,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          user.email,
                          style: text.bodyLarge,
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