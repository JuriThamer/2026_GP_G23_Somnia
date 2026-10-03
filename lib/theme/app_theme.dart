import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color background;
  final Color backgroundMid;
  final Color backgroundEnd;
  final Color surface;
  final Color surfaceAlt;
  final Color text;
  final Color muted;
  final Color primary;
  final Color onPrimary;
  final Color line;
  final Color success;
  final Color warning;
  final Color error;

  const AppColors({
    required this.background,
    required this.backgroundMid,
    required this.backgroundEnd,
    required this.surface,
    required this.surfaceAlt,
    required this.text,
    required this.muted,
    required this.primary,
    required this.onPrimary,
    required this.line,
    required this.success,
    required this.warning,
    required this.error,
  });

  static const dark = AppColors(
    background: Color(0xFF15101F),
    backgroundMid: Color(0xFF15101F),
    backgroundEnd: Color(0xFF15101F),
    surface: Color(0xFF1F1730),
    surfaceAlt: Color(0xFF2A2040),
    text: Color(0xFFEFE6D6),
    muted: Color(0xFFB3A7C6),
    primary: Color(0xFFD9C9A8),
    onPrimary: Color(0xFF20152F),
    line: Color(0xFF382C52),
    success: Color(0xFF7FCBA4),
    warning: Color(0xFFE9B45E),
    error: Color(0xFFF2958D),
  );

  static const light = AppColors(
    background: Color(0xFFFAF5EA),
    backgroundMid: Color(0xFFF1E7D5),
    backgroundEnd: Color(0xFFDDCEB4),
    surface: Color(0xFFFFFBF3),
    surfaceAlt: Color(0xFFF1E7D4),
    text: Color(0xFF2A1B4D),
    muted: Color(0xFF5F5179),
    primary: Color(0xFF3B2667),
    onPrimary: Color(0xFFF8F1E3),
    line: Color(0xFFDACBAF),
    success: Color(0xFF256B4B),
    warning: Color(0xFF8A5A0C),
    error: Color(0xFFA93830),
  );

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [background, backgroundMid, backgroundEnd],
        stops: const [0, 0.55, 1],
      );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      other is AppColors && t >= 0.5 ? other : this;
}

class AppTheme {
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);
  static ThemeData get light => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors c, Brightness brightness) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        brightness: brightness,
      ).copyWith(
        primary: c.primary,
        onPrimary: c.onPrimary,
        surface: c.surface,
        onSurface: c.text,
        error: c.error,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.fraunces(
          fontSize: 32,
          fontWeight: FontWeight.w300,
          height: 1.12,
          letterSpacing: -0.5,
          color: c.text,
        ),
        headlineSmall: GoogleFonts.fraunces(
          fontSize: 21,
          fontWeight: FontWeight.w400,
          height: 1.25,
          color: c.text,
        ),
        bodyLarge: GoogleFonts.figtree(fontSize: 16, color: c.text),
        bodyMedium: GoogleFonts.figtree(
          fontSize: 15,
          height: 1.5,
          color: c.text,
        ),
        bodySmall: GoogleFonts.figtree(fontSize: 13, color: c.muted),
        labelSmall: GoogleFonts.figtree(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          color: c.muted,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: c.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: const StadiumBorder(),
          textStyle: GoogleFonts.figtree(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 22,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.figtree(fontSize: 16, color: c.muted),
        border: border(c.line, 1),
        enabledBorder: border(c.line, 1),
        focusedBorder: border(c.primary, 1.5),
        errorBorder: border(c.error, 1.5),
        focusedErrorBorder: border(c.error, 1.5),
      ),
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}