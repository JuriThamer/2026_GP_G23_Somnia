import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'widgets/app_button.dart';
import 'widgets/app_card.dart';
import 'widgets/app_text_field.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode mode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Somnia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      home: ThemePreview(onToggle: toggleTheme),
    );
  }
}

class ThemePreview extends StatelessWidget {
  final VoidCallback onToggle;
  const ThemePreview({super.key, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: colors.gradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good evening', style: text.headlineLarge),
                const SizedBox(height: 20),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LAST NIGHT', style: text.labelSmall),
                      const SizedBox(height: 8),
                      Text('7h 5m', style: text.headlineSmall),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const AppTextField(label: 'Email', hint: 'you@example.com'),
                const SizedBox(height: 16),
                const AppTextField(
                  label: 'Password',
                  obscureText: true,
                  errorText: 'Password must be at least 8 characters',
                ),
                const Spacer(),
                AppButton(label: 'Switch theme', onPressed: onToggle),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Secondary',
                  style: AppButtonStyle.secondary,
                  onPressed: () {},
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Tonal',
                  style: AppButtonStyle.tonal,
                  onPressed: () {},
                ),
                Center(
                  child: AppButton(
                    label: 'Text button',
                    style: AppButtonStyle.text,
                    onPressed: () {},
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