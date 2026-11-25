import 'package:material_ui/material_ui.dart';

class AppTheme {
  AppTheme._();
  // Palette sampled from the supplied Kos Padang UI reference.
  static const Color teal = Color(0xFF2F6B5E);
  static const Color ink = Color(0xFF1F2933);
  static const Color orange = Color(0xFFF5D88A);
  static const Color canvas = Color(0xFFFAF9F5);
  static const Color muted = Color(0xFF5F6B73);
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
        seedColor: teal,
        brightness: brightness,
        primary: teal,
        secondary: orange,
        surface: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF171E1B));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? canvas
          : const Color(0xFF0F1412),
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            bodyColor: brightness == Brightness.light
                ? const Color(0xFF1F2933)
                : const Color(0xFFF2F5F3),
            displayColor: brightness == Brightness.light
                ? const Color(0xFF1F2933)
                : const Color(0xFFF2F5F3),
            fontFamily: 'Roboto',
          ),
      appBarTheme: AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: brightness == Brightness.light
              ? canvas
              : const Color(0xFF0F1412),
          foregroundColor: brightness == Brightness.light
              ? ink
              : const Color(0xFFF2F5F3)),
      cardTheme: CardThemeData(
          elevation: 0,
          color: brightness == Brightness.light ? Colors.white : null,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                  color: brightness == Brightness.light
                      ? const Color(0xFFE6E8E7)
                      : Colors.white12))),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF171E1B),
        indicatorColor: brightness == Brightness.light
            ? const Color(0xFFDDEBE5)
            : const Color(0xFF26322D),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              color: states.contains(WidgetState.selected)
                  ? teal
                  : const Color(0xFF5F6B73),
              fontSize: 11,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            )),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? const Color(0xFFF2F5F3)
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
                  borderRadius: BorderRadius.circular(18)),
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
    );
  }
}
