import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Rounded-square icon tile ("賽箱") used on cards, list rows and the brand mark.
class AnnivIconChip extends StatelessWidget {
  const AnnivIconChip({
    super.key,
    required this.icon,
    required this.color,
    this.size = AppSpacing.iconChip,
    this.filled = false,
  });

  final IconData icon;
  final Color color;
  final double size;

  /// When true the tile is a solid [color]; otherwise a soft tint of it.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? color : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size >= 44 ? AppRadius.iconChip : 12),
      ),
      child: Icon(
        icon,
        size: size * 0.5,
        color: filled ? Colors.white : color,
      ),
    );
  }
}

/// Small pill / chip. [tone] picks the palette.
enum AnnivPillTone { neutral, brand, soft }

class AnnivPill extends StatelessWidget {
  const AnnivPill(this.text, {super.key, this.tone = AnnivPillTone.neutral, this.color});

  final String text;
  final AnnivPillTone tone;

  /// Overrides the background with a tint of this colour (tone is ignored).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    late final Color bg;
    late final Color fg;
    if (color != null) {
      bg = color!.withValues(alpha: 0.16);
      fg = color!;
    } else {
      switch (tone) {
        case AnnivPillTone.brand:
          bg = a.brand;
          fg = Colors.white;
        case AnnivPillTone.soft:
          bg = a.brandSoft;
          fg = a.brand;
        case AnnivPillTone.neutral:
          bg = a.chipBg;
          fg = a.sub;
      }
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillBr),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// The gradient brand square + wordmark shown in the home header.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 40});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: context.anniv.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.iconChip),
      ),
      child: Icon(Icons.cake_outlined, color: Colors.white, size: size * 0.5),
    );
  }
}

/// 58px circular FAB filled with the brand gradient.
class GradientFab extends StatelessWidget {
  const GradientFab({super.key, required this.onPressed, this.icon = Icons.add});

  final VoidCallback onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: AppSpacing.fab,
        height: AppSpacing.fab,
        decoration: BoxDecoration(
          gradient: a.brandGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: a.brand.withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }
}

/// Uppercase-ish section label (12 / w900, sub colour).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sectionLabelGap),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: context.anniv.sub,
            letterSpacing: 0.3,
          ),
        ),
      );
}

/// Compact size for a [FilledButton] placed in an [AlertDialog]'s `actions`.
///
/// The app-wide filled-button theme sets `minimumSize: Size.fromHeight(52)`
/// (full-width CTAs elsewhere in the app), which also stretches dialog action
/// buttons to infinite width — `actions` can't fit two of those side by side,
/// so Flutter's OverflowBar silently stacks them vertically instead.
final ButtonStyle dialogActionStyle =
    FilledButton.styleFrom(minimumSize: const Size(64, 40));

/// A standard "are you sure?" dialog for a destructive action. Returns true
/// only if the user tapped the (destructive-styled) confirm button.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'キャンセル',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: dialogActionStyle,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Rounded card surface with the mock's soft shadow.
class AnnivCard extends StatelessWidget {
  const AnnivCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return Material(
      color: a.surface,
      borderRadius: AppRadius.cardBr,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: a.surface,
            borderRadius: AppRadius.cardBr,
            boxShadow: [
              BoxShadow(
                color: a.cardShadow,
                blurRadius: 45,
                spreadRadius: -18,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

/// Two/three-way pill toggle (e.g. 単発/毎年繰り返す, シンプル/ライン).
class SegmentedToggle extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final Map<bool, String> options;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: a.chipBg,
        borderRadius: BorderRadius.circular(AppRadius.seg),
      ),
      child: Row(
        children: [
          for (final e in options.entries)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: e.key == value ? a.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.seg - 3),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: e.key == value ? a.ink : a.sub,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
