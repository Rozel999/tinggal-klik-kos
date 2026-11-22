import 'package:material_ui/material_ui.dart';

class AppTheme {
  AppTheme._();
  static const Color teal = Color(0xFF2F7165);
  static const Color ink = Color(0xFF243B37);
  static const Color orange = Color(0xFFF1C46D);
  static const Color canvas = Color(0xFFF8F7F2);
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
        seedColor: teal,
        brightness: brightness,
        primary: teal,
        secondary: orange,
        surface: brightness == Brightness.light ? Colors.white : null);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light ? canvas : null,
      appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: canvas,
          foregroundColor: ink),
      cardTheme: CardThemeData(
          elevation: 0,
          color: brightness == Brightness.light ? Colors.white : null,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19),
              side: BorderSide(
                  color: brightness == Brightness.light
                      ? const Color(0xFFEBEAE3)
                      : Colors.white12))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFF3F5F1)
            : scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: teal, width: 1.5)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: teal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17)),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
    );
  }
}
