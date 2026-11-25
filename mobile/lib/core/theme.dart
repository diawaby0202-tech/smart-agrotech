import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette tirée des champs sénégalais : le vert de l'hivernage, le jaune du
/// mil mûr et le bleu ciel pour la météo. Couleurs unies, sans dégradés.
class Couleurs {
  // Vert de l'hivernage, du plus foncé au plus clair.
  static const vert900 = Color(0xFF14281B);
  static const vert800 = Color(0xFF1C3A26);
  static const vert700 = Color(0xFF24502F);
  static const vert600 = Color(0xFF2E6B3F);
  static const vert500 = Color(0xFF3F8551);
  static const vert400 = Color(0xFF8DC08F);
  static const vert100 = Color(0xFFDDEBDC);
  static const vert50 = Color(0xFFEEF5EC);

  // Jaune du mil mûr : boutons d'action et mises en avant.
  static const or600 = Color(0xFF8A5E06);
  static const or500 = Color(0xFFD99A1E);
  static const or400 = Color(0xFFEDBE55);
  static const or100 = Color(0xFFFAEFD3);

  // Bleu ciel : la météo.
  static const ciel700 = Color(0xFF1577B8);
  static const ciel500 = Color(0xFF1E8CD3);
  static const ciel100 = Color(0xFFDDEEFA);

  // Gris légèrement verts pour le texte, les bordures et les fonds.
  static const encre = Color(0xFF1D2420);
  static const ardoise700 = Color(0xFF3F4842);
  static const ardoise500 = Color(0xFF6B746D);
  static const ardoise400 = Color(0xFF9AA29B);
  static const ardoise200 = Color(0xFFDCE0D8);
  static const ardoise100 = Color(0xFFECEEE8);
  static const ardoise50 = Color(0xFFF4F5F1);

  static const danger = Color(0xFFB3261E);
  static const dangerClair = Color(0xFFF8E0DC);
  static const info = ciel700;
  static const infoClair = ciel100;
}

class AppTheme {
  /// Polices Bricolage Grotesque (titres) et Atkinson Hyperlegible (texte),
  /// une police dessinée pour rester lisible quand on voit mal, ici au soleil
  /// dans un champ. Désactivé dans les tests, qui n'ont pas accès à Internet.
  static bool policesWeb = true;

  /// Animations décoratives en boucle. Coupées dans les tests, qui attendent
  /// que l'écran soit immobile.
  static bool animations = true;

  static TextTheme _textes() {
    final base = ThemeData.light().textTheme.apply(
      bodyColor: Couleurs.ardoise700,
      displayColor: Couleurs.encre,
    );
    if (!policesWeb) return base;
    final corps = GoogleFonts.atkinsonHyperlegibleTextTheme(base);
    TextStyle? titre(TextStyle? style) => style == null
        ? null
        : GoogleFonts.bricolageGrotesque(
            textStyle: style,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          );
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
      scaffoldBackgroundColor: const Color(0xFFF7F8F4),
      dividerColor: Couleurs.ardoise200,
      appBarTheme: AppBarTheme(
        backgroundColor: Couleurs.ardoise50,
        foregroundColor: Couleurs.encre,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE7EAE3))),
        titleTextStyle: textes.titleLarge?.copyWith(color: Couleurs.encre),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE4E8DF)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFDFEFB),
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
          borderSide: const BorderSide(color: Couleurs.vert600, width: 1.5),
        ),
        hintStyle: const TextStyle(color: Couleurs.ardoise400),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Couleurs.vert700,
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
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Couleurs.vert700),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Couleurs.or500,
        foregroundColor: Couleurs.encre,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: Couleurs.vert700,
        secondarySelectedColor: Couleurs.vert700,
        checkmarkColor: Colors.white,
        side: const BorderSide(color: Couleurs.ardoise200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: textes.labelLarge?.copyWith(color: Couleurs.ardoise700),
        secondaryLabelStyle: textes.labelLarge?.copyWith(color: Colors.white),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Couleurs.vert100,
        surfaceTintColor: Colors.transparent,
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(
          textes.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: Couleurs.vert700,
        unselectedLabelColor: Couleurs.ardoise500,
        indicatorColor: Couleurs.vert700,
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
