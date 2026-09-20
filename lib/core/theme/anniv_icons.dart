import 'package:flutter/widgets.dart';

/// Anniv's own hand-drawn icon glyphs (`tools/iconfont/svg/*.svg`, built into
/// `assets/fonts/AnnivIcons.ttf` by `tools/iconfont/build.mjs`). Used for the
/// icon picker's "動く" tab so those icons aren't just stock Material glyphs.
///
/// Codepoints live in the Unicode Supplementary Private Use Area-B
/// (0xF0000–0xFFFFD) — well outside the PUA-A range Material Icons uses —
/// so there's no collision risk in `EventIcons`'s codepoint-keyed lookup map
/// even though it's shared across both fonts.
class AnnivIcons {
  const AnnivIcons._();

  static const rocket = IconData(0xf0001, fontFamily: 'AnnivIcons');
  static const sparkle = IconData(0xf0002, fontFamily: 'AnnivIcons');
  static const flame = IconData(0xf0003, fontFamily: 'AnnivIcons');
  static const smile = IconData(0xf0004, fontFamily: 'AnnivIcons');
  static const lantern = IconData(0xf0005, fontFamily: 'AnnivIcons');
  static const ticket = IconData(0xf0006, fontFamily: 'AnnivIcons');
  static const bolt = IconData(0xf0007, fontFamily: 'AnnivIcons');
  static const swirl = IconData(0xf0008, fontFamily: 'AnnivIcons');
  static const stars = IconData(0xf0009, fontFamily: 'AnnivIcons');
  static const toast = IconData(0xf000a, fontFamily: 'AnnivIcons');
}
