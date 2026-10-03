import 'package:flutter/material.dart';

final themeController = ValueNotifier<ThemeMode>(ThemeMode.dark);

void setThemeMode(String mode) {
  themeController.value = mode == 'light' ? ThemeMode.light : ThemeMode.dark;
}

void toggleThemeMode() {
  themeController.value = themeController.value == ThemeMode.dark
      ? ThemeMode.light
      : ThemeMode.dark;
}
