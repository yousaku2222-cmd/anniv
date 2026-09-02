import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/anniv_widgets.dart';
import '../../ads/application/ad_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../domain/event_icons.dart';

/// Opens the icon picker as a bottom sheet. [onPick] receives the chosen
/// codepoint, or null for "back to template icon", and is responsible for
/// applying it (the sheet does not close itself).
Future<void> showIconPicker(
  BuildContext context, {
  required Color color,
  required int? selected,
  required ValueChanged<int?> onPick,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.anniv.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => IconPickerSheet(
      color: color,
      selected: selected,
      onPick: onPick,
    ),
  );
}

/// Icon picker with a シンプル/ライン tab. Applying a custom icon is gated behind
/// one rewarded-ad view per icon (`AppSettings.unlockedIconCodePoints`); once an
/// icon is unlocked it is free forever. "テンプレートに戻す" is always free.
class IconPickerSheet extends ConsumerStatefulWidget {
  const IconPickerSheet({
    super.key,
    required this.color,
    required this.selected,
    required this.onPick,
  });

  final Color color;
  final int? selected;

  /// null = "back to template icon".
  final ValueChanged<int?> onPick;

  @override
  ConsumerState<IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends ConsumerState<IconPickerSheet> {
  IconStyle _style = IconStyle.filled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (!ref.read(allIconsUnlockedProvider)) {
      ref.read(rewardedAdServiceProvider).preload();
    }
  }

  Future<void> _onIconTap(int codePoint) async {
    if (ref.read(iconUnlockedProvider(codePoint))) {
      widget.onPick(codePoint);
      return;
    }
    setState(() => _busy = true);
    final earned = await ref.read(rewardedAdServiceProvider).showForReward();
    if (!mounted) return;
    setState(() => _busy = false);
    if (earned) {
      await ref.read(settingsProvider.notifier).update((s) => s.copyWith(
          unlockedIconCodePoints: {...s.unlockedIconCodePoints, codePoint}));
      if (mounted) widget.onPick(codePoint);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('広告を再生できませんでした。時間をおいて、もう一度お試しください。'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    final allUnlocked = ref.watch(allIconsUnlockedProvider);
    final groups = EventIcons.groupsFor(_style);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.74,
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: a.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 12, 6),
                  child: Row(
                    children: [
                      Text('アイコン',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: a.ink)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => widget.onPick(null),
                        child: const Text('テンプレートに戻す'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: SegmentedToggle(
                    options: const {
                      false: 'シンプル',
                      true: 'ライン',
                    },
                    value: _style == IconStyle.outline,
                    onChanged: (line) => setState(() =>
                        _style = line ? IconStyle.outline : IconStyle.filled),
                  ),
                ),
                if (!allUnlocked)
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: a.brandSoft,
                      borderRadius: AppRadius.rowBr,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_outline,
                            size: 18, color: a.brand),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ロックされたアイコンは、広告を1回見るとそのアイコンだけ解放されます（以降はずっと自由）',
                            style: TextStyle(fontSize: 12, color: a.brand),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    children: [
                      for (final group in groups) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 10),
                          child: Text(
                            group.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: a.sub,
                            ),
                          ),
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final icon in group.icons)
                              _IconCell(
                                icon: icon,
                                color: widget.color,
                                selected: icon.codePoint == widget.selected,
                                locked: !ref
                                    .watch(iconUnlockedProvider(icon.codePoint)),
                                onTap: () => _onIconTap(icon.codePoint),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (_busy)
              Positioned.fill(
                child: ColoredBox(
                  color: a.surface.withValues(alpha: 0.6),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _IconCell extends StatelessWidget {
  const _IconCell({
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : a.chipBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected
                  ? color
                  : (locked ? a.ink.withValues(alpha: 0.45) : a.ink),
            ),
            if (locked)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: a.brand,
                    shape: BoxShape.circle,
                    border: Border.all(color: a.surface, width: 1.5),
                  ),
                  child: const Icon(Icons.lock, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
