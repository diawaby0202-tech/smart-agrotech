import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Couleurs du site web (variables CSS de `frontend/src/styles.css`), pour que
/// l'app mobile et le site aient la même identité.
class Couleurs {
  static const vert900 = Color(0xFF0F2E1C);
  static const vert800 = Color(0xFF14532D);
  static const vert700 = Color(0xFF166534);
  static const vert600 = Color(0xFF15803D);
  static const vert500 = Color(0xFF16A34A);
  static const vert400 = Color(0xFF22C55E);
  static const vert100 = Color(0xFFDCFCE7);
  static const vert50 = Color(0xFFF0FDF4);

  static const or600 = Color(0xFFB45309);
  static const or500 = Color(0xFFD97706);
  static const or400 = Color(0xFFF59E0B);
  static const or100 = Color(0xFFFEF3C7);

  static const encre = Color(0xFF0B1220);
  static const ardoise700 = Color(0xFF334155);
  static const ardoise500 = Color(0xFF64748B);
  static const ardoise400 = Color(0xFF94A3B8);
  static const ardoise200 = Color(0xFFE2E8F0);
  static const ardoise100 = Color(0xFFF1F5F9);
  static const ardoise50 = Color(0xFFF8FAFC);

  static const danger = Color(0xFFDC2626);
  static const dangerClair = Color(0xFFFEE2E2);
  static const info = Color(0xFF0284C7);
  static const infoClair = Color(0xFFE0F2FE);

  /// Dégradé « marque » des boutons, logos et bandeaux.
  static const degradeMarque = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [vert500, vert600, vert900],
    stops: [0, 0.55, 1],
  );

  /// Dégradé bleu de la carte météo.
  static const degradeMeteo = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF0369A1)],
  );
}

/// Ombre douce des cartes (`--ombre-sm` du site).
const ombreCarte = [
  BoxShadow(color: Color(0x140F2E1C), blurRadius: 8, offset: Offset(0, 2)),
];

class AppTheme {
  /// Polices Sora (titres) et Inter (texte), comme sur le site. Désactivé
  /// dans les tests, qui n'ont pas accès à Internet.
  static bool policesWeb = true;

  static TextTheme _textes() {
    final base = ThemeData.light().textTheme.apply(
      bodyColor: Couleurs.ardoise700,
      displayColor: Couleurs.encre,
    );
    if (!policesWeb) return base;
    final corps = GoogleFonts.interTextTheme(base);
    TextStyle? titre(TextStyle? style) => style == null
        ? null
        : GoogleFonts.sora(textStyle: style, fontWeight: FontWeight.w700);
    return corps.copyWith(
      displaySmall: titre(corps.displaySmall),
      headlineLarge: titre(corps.headlineLarge),
      headlineMedium: titre(corps.headlineMedium),
      headlineSmall: titre(corps.headlineSmall),
      titleLarge: titre(corps.titleLarge),
      titleMedium: corps.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  static ThemeData clair() {
    final rayon = BorderRadius.circular(14);
    final schema = ColorScheme.fromSeed(
      seedColor: Couleurs.vert600,
      primary: Couleurs.vert600,
      onPrimary: Colors.white,
      secondary: Couleurs.or500,
      error: Couleurs.danger,
      surface: Colors.white,
    );
    final textes = _textes();

    return ThemeData(
      colorScheme: schema,
      textTheme: textes,
      scaffoldBackgroundColor: Couleurs.ardoise50,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Couleurs.encre,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textes.titleLarge?.copyWith(color: Couleurs.encre),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Couleurs.ardoise200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: rayon,
          borderSide: const BorderSide(color: Couleurs.ardoise200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: rayon,
          borderSide: const BorderSide(color: Couleurs.ardoise200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: rayon,
          borderSide: const BorderSide(color: Couleurs.vert500, width: 2),
        ),
        hintStyle: const TextStyle(color: Couleurs.ardoise400),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Couleurs.vert600,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: rayon),
          textStyle: textes.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Couleurs.vert700,
          side: const BorderSide(color: Couleurs.ardoise200),
          shape: RoundedRectangleBorder(borderRadius: rayon),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Couleurs.vert600,
        foregroundColor: Colors.white,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: Couleurs.vert600,
        secondarySelectedColor: Couleurs.vert600,
        checkmarkColor: Colors.white,
        side: const BorderSide(color: Couleurs.ardoise200),
        shape: const StadiumBorder(),
        labelStyle: textes.labelLarge?.copyWith(color: Couleurs.ardoise700),
        secondaryLabelStyle: textes.labelLarge?.copyWith(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Couleurs.vert100,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          textes.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Couleurs.vert700,
        unselectedLabelColor: Couleurs.ardoise500,
        indicatorColor: Couleurs.vert600,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Couleurs.vert600,
        linearTrackColor: Couleurs.ardoise100,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Couleurs.vert900,
      ),
    );
  }
}
