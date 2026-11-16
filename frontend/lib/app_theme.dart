import 'package:flutter/material.dart';

class BBTheme {
  static const Color red = Color(0xFFB4232C);
  static const Color redDark = Color(0xFF8F1D26);
  static const Color redLight = Color(0xFFD13A43);

  static const Color black = Color(0xFF0F1113);
  static const Color black2 = Color(0xFF15181C);
  static const Color black3 = Color(0xFF1B1F24);
  static const Color black4 = Color(0xFF24292F);

  static const Color white = Color(0xFFF2F0EC);
  static const Color canvas = Color(0xFF111315);
  static const Color panel = Color(0xFF191C20);
  static const Color border = Color(0xFF353A40);
  static const Color borderSoft = Color(0xFF292E34);

  static const Color text = Color(0xFFF4F2EE);
  static const Color muted = Color(0xFFA9ADB3);
  static const Color subtle = Color(0xFF777D84);
  static const Color green = Color(0xFF35A66F);
  static const Color amber = Color(0xFFD39B35);

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: red,
          brightness: Brightness.dark,
        ).copyWith(
          primary: red,
          onPrimary: Colors.white,
          secondary: red,
          onSecondary: Colors.white,
          surface: panel,
          onSurface: text,
          error: red,
          onError: Colors.white,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 32),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, fontSize: 28),
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, fontSize: 25),
        titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        bodyLarge: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
        bodySmall: TextStyle(fontWeight: FontWeight.w400, fontSize: 12),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: black2,
        foregroundColor: text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: const CardThemeData(
        color: panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderSoft),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: black3,
        hintStyle: const TextStyle(color: subtle),
        labelStyle: const TextStyle(color: muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: red, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: red,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          minimumSize: const Size(0, 42),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: panel,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: red),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: red,
        foregroundColor: Colors.white,
      ),
    );
  }
}
