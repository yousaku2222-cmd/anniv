import 'package:flutter/material.dart';

/// Design tokens transcribed from `Annivデザイン/design-tokens.json` (mock v1.0).
///
/// Colours that differ between light and dark live on [AnnivColors], a
/// [ThemeExtension] read via `Theme.of(context).extension<AnnivColors>()!` or
/// the [BuildContext] shortcut in `context.anniv`. Metrics that don't change
/// with brightness are plain consts on [AppRadius] / [AppSpacing].
@immutable
class AnnivColors extends ThemeExtension<AnnivColors> {
  const AnnivColors({
    required this.bg,
    required this.surface,
    required this.line,
    required this.ink,
    required this.sub,
    required this.faint,
    required this.chipBg,
    required this.brand,
    required this.brand2,
    required this.brandSoft,
    required this.cardShadow,
  });

  final Color bg;
  final Color surface;
  final Color line;
  final Color ink;
  final Color sub;
  final Color faint;
  final Color chipBg;
  final Color brand;
  final Color brand2;
  final Color brandSoft;
  final Color cardShadow;

  static const AnnivColors light = AnnivColors(
    bg: Color(0xFFFBF7F0),
    surface: Color(0xFFFFFFFF),
    line: Color(0xFFEFE5D8),
    ink: Color(0xFF2D2620),
    sub: Color(0xFF8A7A6B),
    faint: Color(0xFFC9BBA9),
    chipBg: Color(0xFFF4ECDF),
    brand: Color(0xFFE85D43),
    brand2: Color(0xFFC94A32),
    brandSoft: Color(0xFFFBEAE4),
    cardShadow: Color(0x593E2A19), // rgba(62,42,25,.35)
  );

  static const AnnivColors dark = AnnivColors(
    bg: Color(0xFF1C1713),
    surface: Color(0xFF28211B),
    line: Color(0xFF3B322A),
    ink: Color(0xFFF5EEE5),
    sub: Color(0xFFA49381),
    faint: Color(0xFF6F6456),
    chipBg: Color(0xFF33291F),
    brand: Color(0xFFF0785D),
    brand2: Color(0xFFFF8A6E),
    brandSoft: Color(0xFF3A241E),
    cardShadow: Color(0xA6000000), // rgba(0,0,0,.65)
  );

  /// 135° brand gradient used on the FAB, brand mark and primary buttons.
  LinearGradient get brandGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [brand, brand2],
      );

  @override
  AnnivColors copyWith({
    Color? bg,
    Color? surface,
    Color? line,
    Color? ink,
    Color? sub,
    Color? faint,
    Color? chipBg,
    Color? brand,
    Color? brand2,
    Color? brandSoft,
    Color? cardShadow,
  }) {
    return AnnivColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      sub: sub ?? this.sub,
      faint: faint ?? this.faint,
      chipBg: chipBg ?? this.chipBg,
      brand: brand ?? this.brand,
      brand2: brand2 ?? this.brand2,
      brandSoft: brandSoft ?? this.brandSoft,
      cardShadow: cardShadow ?? this.cardShadow,
    );
  }

  @override
  AnnivColors lerp(ThemeExtension<AnnivColors>? other, double t) {
    if (other is! AnnivColors) return this;
    return AnnivColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      line: Color.lerp(line, other.line, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      sub: Color.lerp(sub, other.sub, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brand2: Color.lerp(brand2, other.brand2, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
    );
  }
}

/// Corner radii (px), brightness-independent.
class AppRadius {
  const AppRadius._();

  static const double card = 24;
  static const double row = 18;
  static const double button = 18;
  static const double iconChip = 16;
  static const double pill = 999;
  static const double seg = 14;

  static const BorderRadius cardBr = BorderRadius.all(Radius.circular(card));
  static const BorderRadius rowBr = BorderRadius.all(Radius.circular(row));
  static const BorderRadius buttonBr = BorderRadius.all(Radius.circular(button));
  static const BorderRadius pillBr = BorderRadius.all(Radius.circular(pill));
}

/// Spacing / layout metrics (px), brightness-independent.
class AppSpacing {
  const AppSpacing._();

  static const double screenH = 20;
  static const double cardGap = 12;
  static const double sectionLabelGap = 9;
  static const double headerGap = 10;

  static const double iconChip = 46;
  static const double iconChipSmall = 40;
  static const double cardAccentBar = 5;
  static const double fab = 58;

  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: screenH);
}

extension AnnivColorsX on BuildContext {
  /// Shortcut for `Theme.of(context).extension<AnnivColors>()!`.
  AnnivColors get anniv => Theme.of(this).extension<AnnivColors>()!;
}
