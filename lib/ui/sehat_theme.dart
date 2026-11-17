import 'package:flutter/material.dart';

/// Warna loket latihan. Bukan palet logo BPJS.
abstract final class SehatWarna {
  static const ink = Color(0xFF1B3A34);
  static const inkSoft = Color(0xFF3E534E);
  static const paper = Color(0xFFF3F6F5);
  static const line = Color(0xFFD5DEDB);
  static const white = Color(0xFFFFFFFF);
}

ThemeData sehatTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: SehatWarna.ink,
    onPrimary: SehatWarna.white,
    secondary: Color(0xFF3D6B62),
    onSecondary: SehatWarna.white,
    error: Color(0xFF9B2C2C),
    onError: SehatWarna.white,
    surface: SehatWarna.white,
    onSurface: SehatWarna.ink,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  final text = base.textTheme.apply(
    bodyColor: SehatWarna.ink,
    displayColor: SehatWarna.ink,
  );

  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(10)),
    borderSide: BorderSide(color: SehatWarna.line),
  );

  return base.copyWith(
    scaffoldBackgroundColor: SehatWarna.paper,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: SehatWarna.paper,
      foregroundColor: SehatWarna.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 20,
      ),
    ),
    dividerColor: SehatWarna.line,
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: SehatWarna.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        borderSide: BorderSide(color: SehatWarna.ink, width: 1.4),
      ),
      labelStyle: TextStyle(color: SehatWarna.inkSoft),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: SehatWarna.ink,
        side: const BorderSide(color: SehatWarna.line),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: SehatWarna.white,
      indicatorColor: const Color(0xFFE5F0EC),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? SehatWarna.ink : SehatWarna.inkSoft,
        );
      }),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: SehatWarna.ink,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.standard,
        side: const WidgetStatePropertyAll(BorderSide(color: SehatWarna.line)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
      ),
    ),
  );
}
