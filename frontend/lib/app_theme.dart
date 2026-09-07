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
    final scheme = ColorScheme.fromSeed(
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
        headlineLarge: TextStyle(fontWeight: FontWeight.w900, fontSize: 38, shadows: [Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 1)]),
        headlineMedium: TextStyle(fontWeight: FontWeight.w900, fontSize: 31, shadows: [Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 1)]),
        headlineSmall: TextStyle(fontWeight: FontWeight.w900, fontSize: 27, shadows: [Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 1)]),
        titleLarge: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, shadows: [Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 1)]),
        titleMedium: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        titleSmall: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        bodyLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        bodyMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        labelLarge: TextStyle(fontWeight: FontWeight.w900),
        labelMedium: TextStyle(fontWeight: FontWeight.w800),
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
      ),
      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: black3,
        hintStyle: const TextStyle(color: subtle),
        labelStyle: const TextStyle(color: muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: red, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: red,
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.black, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: Colors.black, width: 1.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
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
