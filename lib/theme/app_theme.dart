import 'package:flutter/material.dart';

/// Colore dei testi secondari: date, dettagli, suggerimenti
const Color grigioTesto = Colors.white60;

const TextStyle testoSecondario = TextStyle(color: grigioTesto);

/// Margine intorno al contenuto delle pagine
const EdgeInsets marginePagina = EdgeInsets.all(20);

/// Tema scuro "grafite" dell'app: sfondo quasi nero e dettagli lilla a pillola
ThemeData graphiteTheme() {
  const ink = Color(0xFF131217); // sfondo
  const surface = Color(0xFF1E1D24); // pannelli
  const lilla = Color(0xFFC8B6F6); // colore principale
  const chiaro = Color(0xFFF4F3F0); // testi e icone
  const pillola = StadiumBorder();

  // Palette generata da Flutter, con i colori principali sostituiti
  final paletteBase = ColorScheme.fromSeed(seedColor: lilla, brightness: Brightness.dark);
  final scheme = paletteBase.copyWith(
    primary: lilla,
    onPrimary: ink,
    surface: surface,
    onSurface: chiaro,
    secondary: lilla,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: ink,
    appBarTheme: const AppBarTheme(
      backgroundColor: ink,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ink,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lilla,
        foregroundColor: ink,
        minimumSize: const Size(44, 52),
        shape: pillola,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      indicator: ShapeDecoration(color: lilla, shape: pillola),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: ink,
      unselectedLabelColor: chiaro,
      labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontSize: 15),
      splashBorderRadius: BorderRadius.all(Radius.circular(24)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: lilla,
        selectedForegroundColor: ink,
        side: const BorderSide(color: Colors.white24),
        shape: pillola,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: lilla.withValues(alpha: 0.25),
      iconTheme: WidgetStateProperty.resolveWith(
        (stati) => IconThemeData(color: stati.contains(WidgetState.selected) ? lilla : chiaro),
      ),
    ),
  );
}
