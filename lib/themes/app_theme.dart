import 'package:flutter/material.dart';

class AppTheme {
  static const _pageBackground = Color(0xFF090F20);
  static const _surface = Color(0xFF141E32);
  static const _surfaceStrong = Color(0xFF141E32);
  static const _outline = Color(0xFF243047);
  static const _primary = Color(0xFF43D4C2);
  static const _textPrimary = Color(0xFFE7F0FF);
  static const _textSecondary = Color(0xFFA1AEC4);

  static ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _primary,
    scaffoldBackgroundColor: _pageBackground,
    colorScheme: const ColorScheme.dark(
      primary: _primary,
      secondary: Color(0xFFF28B50),
      surface: _surfaceStrong,
      error: Color(0xFFFF7F5B),
      onPrimary: Color(0xFF090F20),
      onSecondary: Color(0xFF090F20),
      onSurface: _textPrimary,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: _textPrimary,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: _textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: _textPrimary),
      actionsIconTheme: IconThemeData(color: _textPrimary),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: _textPrimary),
      bodyMedium: TextStyle(color: _textPrimary),
      titleLarge: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: _textSecondary, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xA60A1C3D),
      labelStyle: const TextStyle(color: _textSecondary),
      hintStyle: const TextStyle(color: _textSecondary),
      prefixIconColor: _textSecondary,
      suffixIconColor: _textSecondary,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x3346B6EC)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xCCFF7F5B)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF7F5B), width: 1.2),
      ),
    ),
    cardTheme: CardThemeData(
      color: _surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: const Color(0x40020814),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _outline),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      surfaceTintColor: Colors.transparent,
      backgroundColor: _surfaceStrong,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      titleTextStyle: const TextStyle(
        color: _textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: _textSecondary,
        fontSize: 15,
        height: 1.4,
      ),
    ),
    dividerColor: const Color(0x3346B6EC),
    listTileTheme: const ListTileThemeData(
      iconColor: _textPrimary,
      textColor: _textPrimary,
    ),
    iconTheme: const IconThemeData(color: _textPrimary),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: _primary),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _surfaceStrong,
      contentTextStyle: const TextStyle(color: _textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _primary;
        return const Color(0xFF9AB7DD);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0x6656D5FF);
        }
        return const Color(0x335E7CA6);
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: const Color(0xFF090F20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
