import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// Anniv's visual identity, transcribed from the Genspark mock (v1.0):
/// warm-cream ground, vermilion ("朱色") brand, Zen Kaku Gothic New for UI text
/// and Outfit for the count numerals.
class AppTheme {
  const AppTheme._();

  /// Legacy aliases kept so older call-sites still compile. Prefer
  /// `context.anniv.brand`.
  static const Color candle = Color(0xFFE85D43);
  static const Color plum = Color(0xFF9B7BE8);

  static ThemeData light() => _base(Brightness.light, AnnivColors.light);
  static ThemeData dark() => _base(Brightness.dark, AnnivColors.dark);

  static ThemeData _base(Brightness brightness, AnnivColors c) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: c.brand,
          brightness: brightness,
        ).copyWith(
          primary: c.brand,
          secondary: c.brand2,
          surface: c.surface,
          onSurface: c.ink,
          surfaceContainerLowest: c.surface,
          outlineVariant: c.line,
        );

    final baseText = brightness == Brightness.light
        ? Typography.blackMountainView
        : Typography.whiteMountainView;
    final textTheme = GoogleFonts.zenKakuGothicNewTextTheme(baseText).apply(
      bodyColor: c.ink,
      displayColor: c.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      textTheme: textTheme,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.ink,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.zenKakuGothicNew(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          color: c.ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: c.cardShadow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBr),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBr),
          textStyle: GoogleFonts.zenKakuGothicNew(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.line),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonBr),
          textStyle: GoogleFonts.zenKakuGothicNew(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.brand),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.chipBg,
        selectedColor: c.brand,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
        labelStyle: GoogleFonts.zenKakuGothicNew(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: c.ink,
        ),
        secondaryLabelStyle: GoogleFonts.zenKakuGothicNew(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : c.faint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.brand : c.chipBg,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.rowBr,
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.rowBr,
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.rowBr,
          borderSide: BorderSide(color: c.brand, width: 2),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      ),
    );
  }
}

/// Outfit numeral styles — the count digits on cards and the detail hero.
/// `tabular` keeps columns of digits aligned.
class AppNumeral {
  const AppNumeral._();

  static TextStyle _outfit(double size, FontWeight weight, Color color) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: 1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// 32 / w800 — the big number on a home card.
  static TextStyle card(Color color) => _outfit(32, FontWeight.w800, color);

  /// 76 / w800 — the D-Day number in the detail hero.
  static TextStyle hero(Color color) => _outfit(76, FontWeight.w800, color);

  /// Arbitrary size, w800.
  static TextStyle sized(double size, Color color) =>
      _outfit(size, FontWeight.w800, color);
}
