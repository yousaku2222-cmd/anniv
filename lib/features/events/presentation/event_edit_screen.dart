import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/anniv_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../ads/application/ad_providers.dart';
import '../../ads/presentation/banner_ad_widget.dart';
import '../../groups/application/group_providers.dart';
import '../../notifications/application/notification_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../application/event_providers.dart';
import '../domain/countdown.dart';
import '../domain/event.dart';
import '../domain/event_icons.dart';
import '../domain/event_templates.dart';
import 'event_presentation.dart';

/// New events go through the mock's 5-step wizard; existing events open a single
/// scroll with the same section widgets and a Save action in the app bar.
class EventEditScreen extends ConsumerStatefulWidget {
  const EventEditScreen({super.key, this.eventId});

  final String? eventId;

  bool get isCreating => eventId == null;

  @override
  ConsumerState<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends ConsumerState<EventEditScreen> {
  late Event _draft;
  final _titleController = TextEditingController();
  final _pageController = PageController();
  int _step = 0;
  bool _initialised = false;
  bool _busy = false;

  /// The 5th and every later new event costs one rewarded-ad view.
  static const int _freeEventQuota = 4;

  bool get _needsAdToSave =>
      widget.isCreating &&
      ref.read(adsEnabledProvider) &&
      ref.read(eventsProvider).length >= _freeEventQuota;

  static const _stepCount = 5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    if (widget.isCreating) {
      _draft = ref
          .read(eventsProvider.notifier)
          .draftFromTemplate(EventType.birthday);
    } else {
      final existing = ref.read(eventsProvider.notifier).byId(widget.eventId!);
      _draft = existing ??
          ref.read(eventsProvider.notifier).draftFromTemplate(EventType.custom);
    }
    _titleController.text = _draft.title;

    if (_needsAdToSave) ref.read(rewardedAdServiceProvider).preload();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _set(Event next) => setState(() => _draft = next);

  void _applyTemplate(EventType type) {
    final t = EventTemplate.forType(type);
    _set(_draft.copyWith(
      type: type,
      repeat: t.defaultRepeat,
      countMode: t.defaultCountMode,
      notifications: t.buildNotifications(),
      milestones: t.buildMilestones(),
      colorValue: () => null,
    ));
  }

  Future<void> _save() async {
    if (_busy) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _goto(0);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('タイトルを入力してください')));
      return;
    }

    if (_needsAdToSave) {
      setState(() => _busy = true);
      final earned = await ref.read(rewardedAdServiceProvider).showForReward();
      if (!mounted) return;
      setState(() => _busy = false);
      if (!earned) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('広告を再生できませんでした。もう一度お試しください。'),
          ),
        );
        return;
      }
    }

    if (_draft.notifications.isNotEmpty) {
      await ref.read(notificationServiceProvider).requestPermission();
    }
    await ref.read(eventsProvider.notifier).save(_draft.copyWith(title: title));
    if (mounted) context.pop();
  }

  void _next() {
    if (_step == 0 && _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('タイトルを入力してください')));
      return;
    }
    _goto(_step + 1);
  }

  void _goto(int step) {
    setState(() => _step = step.clamp(0, _stepCount - 1));
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.isCreating ? _buildWizard(context) : _buildEditor(context);
  }

  // ---------------------------------------------------------------- wizard ----

  Widget _buildWizard(BuildContext context) {
    final a = context.anniv;
    final isLast = _step == _stepCount - 1;
    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, 12, AppSpacing.screenH, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        _step == 0 ? context.pop() : _goto(_step - 1),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Text('STEP ${_step + 1}/$_stepCount',
                      style: TextStyle(
                          color: a.brand,
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                  Text('  —  新規作成',
                      style: TextStyle(color: a.sub, fontSize: 13)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, 8, AppSpacing.screenH, 8),
              child: Row(
                children: [
                  for (var i = 0; i < _stepCount; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(
                            right: i == _stepCount - 1 ? 0 : 6),
                        decoration: BoxDecoration(
                          color: i <= _step ? a.brand : a.line,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepScroll(
                      title: '何の日を登録しますか？', children: _templateStep()),
                  _StepScroll(title: 'いつですか？', children: _dateStep()),
                  _StepScroll(title: 'どう数えますか？', children: _countStep()),
                  _StepScroll(title: 'いつ通知しますか？', children: _notifyStep()),
                  _StepScroll(title: '見た目を整えましょう', children: _lookStep()),
                ],
              ),
            ),
            _WizardBar(
              onCancel: () => context.pop(),
              onBack: _step == 0 ? null : () => _goto(_step - 1),
              nextLabel: isLast
                  ? (_needsAdToSave ? '広告を見て保存' : '保存')
                  : '次へ',
              busy: _busy,
              onNext: isLast ? _save : _next,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- editor ----

  Widget _buildEditor(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        title: const Text('編集'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, 12, AppSpacing.screenH, 48),
        children: [
          const SectionLabel('テンプレート'),
          ..._templateStep(),
          const SizedBox(height: 24),
          const SectionLabel('日付'),
          ..._dateStep(),
          const SizedBox(height: 24),
          const SectionLabel('カウント方法'),
          ..._countStep(),
          const SizedBox(height: 24),
          const SectionLabel('通知'),
          ..._notifyStep(),
          const SizedBox(height: 24),
          const SectionLabel('見た目'),
          ..._lookStep(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- step bodies ---

  List<Widget> _templateStep() {
    final a = context.anniv;
    return [
      TextField(
        controller: _titleController,
        textInputAction: TextInputAction.done,
        onChanged: (v) => setState(() {}),
        decoration: const InputDecoration(
          labelText: 'タイトル',
          hintText: '例：ママの誕生日 / 付き合った記念日',
        ),
      ),
      const SizedBox(height: 8),
      Text('種類を選ぶと、アイコン・色・おすすめ通知が自動でセットされます。',
          style: TextStyle(fontSize: 12.5, color: a.sub, height: 1.5)),
      const SizedBox(height: 14),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: [
          for (final t in EventTemplate.all)
            _TemplateCard(
              template: t,
              selected: _draft.type == t.type,
              onTap: () => _applyTemplate(t.type),
            ),
        ],
      ),
    ];
  }

  List<Widget> _dateStep() {
    final a = context.anniv;
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    return [
      _Segmented(
        options: const {false: '単発', true: '毎年繰り返す'},
        value: _draft.repeat == RepeatRule.yearly,
        onChanged: (yearly) => _set(_draft.copyWith(
            repeat: yearly ? RepeatRule.yearly : RepeatRule.none)),
      ),
      const SizedBox(height: 16),
      AnnivCard(
        padding: const EdgeInsets.all(6),
        child: CalendarDatePicker(
          initialDate: _draft.targetDate,
          // 1900 so past birthdays / long-ago anniversaries are selectable.
          firstDate: DateTime(1900),
          lastDate: DateTime(2100),
          onDateChanged: (d) => _set(
              _draft.copyWith(targetDate: DateTime(d.year, d.month, d.day))),
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _quickChip('今日', t),
          _quickChip('1週間後', t.add(const Duration(days: 7))),
          _quickChip('1ヶ月後', DateTime(t.year, t.month + 1, t.day)),
          _quickChip(
            '年末年始',
            DateTime(
                t.isAfter(DateTime(t.year, 12, 30)) ? t.year + 1 : t.year,
                12,
                30),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const _ToggleRow(
        icon: Icons.brightness_3_outlined,
        title: '旧暦で指定',
        subtitle: 'v2 で対応予定',
        value: false,
        onChanged: null,
      ),
      const SizedBox(height: 8),
      Text('選択中：${formatFullDate(_draft.targetDate)}',
          style: TextStyle(color: a.sub, fontSize: 12.5)),
    ];
  }

  List<Widget> _countStep() {
    return [
      _RadioTile<CountMode>(
        value: CountMode.daysLeft,
        group: _draft.countMode,
        title: '残り日数',
        example: 'あと 19 日',
        onChanged: (v) => _set(_draft.copyWith(countMode: v)),
      ),
      const SizedBox(height: 10),
      _RadioTile<CountMode>(
        value: CountMode.daysSince,
        group: _draft.countMode,
        title: '経過日数',
        example: '+110 日目',
        onChanged: (v) => _set(_draft.copyWith(countMode: v)),
      ),
      const SizedBox(height: 10),
      _RadioTile<CountMode>(
        value: CountMode.repeatNext,
        group: _draft.countMode,
        title: '次の繰り返しまで',
        example: '毎年の記念日まで',
        onChanged: (v) => _set(_draft.copyWith(
            countMode: v,
            repeat: _draft.repeat == RepeatRule.none
                ? RepeatRule.yearly
                : _draft.repeat)),
      ),
    ];
  }

  List<Widget> _notifyStep() {
    final defaultTime = ref.read(settingsProvider).defaultNotifyTime;
    final enabled = _draft.notifications.map((n) => n.offsetDays).toSet();
    final hasMilestones = _draft.milestones.isNotEmpty;
    return [
      for (final offset in const [0, 1, 3, 7])
        _ToggleRow(
          icon: Icons.notifications_none_rounded,
          title: notificationOffsetLabel(offset),
          subtitle: defaultTime.format(),
          value: enabled.contains(offset),
          onChanged: (on) {
            final next = [..._draft.notifications]
              ..removeWhere((n) => n.offsetDays == offset);
            if (on) {
              next.add(NotificationRule(offsetDays: offset, time: defaultTime));
            }
            next.sort((x, y) => x.offsetDays.compareTo(y.offsetDays));
            _set(_draft.copyWith(notifications: next));
          },
        ),
      const SizedBox(height: 8),
      _ToggleRow(
        icon: Icons.flag_outlined,
        title: 'マイルストーン通知',
        subtitle: Countdown.milestoneIsBefore(_draft)
            ? '90日前・30日前・7日前'
            : '100日目・200日目・365日目',
        value: hasMilestones,
        onChanged: (on) => _set(_draft.copyWith(
          milestones: on
              ? (_draft.template.milestonePreset.isNotEmpty
                  ? _draft.template.buildMilestones()
                  : (Countdown.milestoneIsBefore(_draft)
                      ? Countdown.defaultBeforeMilestones
                      : Countdown.defaultMilestones))
              : const [],
        )),
      ),
    ];
  }

  List<Widget> _lookStep() {
    final a = context.anniv;
    final today = DateTime.now();
    final label = CountLabel.of(_draft.copyWith(title: _titleController.text),
        DateTime(today.year, today.month, today.day));
    final previewColor = _draft.displayColor;
    final swatches = <Color?>[
      null,
      ...EventType.values.map(AnnivEventColors.of),
    ];
    return [
      if (_needsAdToSave) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: a.brandSoft,
            borderRadius: AppRadius.rowBr,
          ),
          child: Row(
            children: [
              Icon(Icons.play_circle_outline, size: 18, color: a.brand),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '5個目以降の登録には、保存時に広告の視聴が必要です',
                  style: TextStyle(fontSize: 12, color: a.brand),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      Container(
        height: 150,
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardBr,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(previewColor, Colors.white, 0.18)!,
              Color.lerp(previewColor, Colors.black, 0.12)!,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(label.big, style: AppNumeral.sized(44, Colors.white)),
                const SizedBox(width: 4),
                Text(label.unit,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const Spacer(),
                Icon(_draft.displayIcon, color: Colors.white, size: 26),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _titleController.text.isEmpty ? 'タイトル' : _titleController.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900),
            ),
            Text(formatFullDate(_draft.targetDate),
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      Text('背景色', style: TextStyle(fontSize: 12.5, color: a.sub)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final c in swatches)
            GestureDetector(
              onTap: () => _set(_draft.copyWith(
                  colorValue: () => c?.toARGB32())),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c ?? _draft.template.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (_draft.colorValue == null && c == null) ||
                            (c != null && _draft.colorValue == c.toARGB32())
                        ? a.ink
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: c == null
                    ? const Icon(Icons.auto_fix_high,
                        size: 16, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Text('アイコン', style: TextStyle(fontSize: 12.5, color: a.sub)),
          if (!ref.watch(allIconsUnlockedProvider)) ...[
            const SizedBox(width: 6),
            Icon(Icons.lock, size: 12, color: a.brand),
            const SizedBox(width: 2),
            Text('広告で解放',
                style: TextStyle(fontSize: 11, color: a.brand)),
          ],
        ],
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickIcon,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: a.surface,
            borderRadius: AppRadius.rowBr,
            border: Border.all(color: a.line),
          ),
          child: Row(
            children: [
              AnnivIconChip(
                  icon: _draft.displayIcon, color: previewColor, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _draft.iconCodePoint == null
                      ? 'テンプレートのアイコン'
                      : 'カスタムアイコン',
                  style: TextStyle(color: a.ink, fontWeight: FontWeight.w700),
                ),
              ),
              if (_draft.iconCodePoint != null)
                TextButton(
                  onPressed: () =>
                      _set(_draft.copyWith(iconCodePoint: () => null)),
                  child: const Text('リセット'),
                ),
              Icon(Icons.chevron_right_rounded, color: a.faint),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      const _ToggleRow(
        icon: Icons.image_outlined,
        title: '背景写真',
        subtitle: 'v2 で対応予定',
        value: false,
        onChanged: null,
      ),
      const SizedBox(height: 16),
      _GroupPicker(
        draft: _draft,
        onChanged: (id) => _set(_draft.copyWith(groupId: () => id)),
      ),
    ];
  }

  Widget _quickChip(String label, DateTime date) {
    final selected = _draft.targetDate.year == date.year &&
        _draft.targetDate.month == date.month &&
        _draft.targetDate.day == date.day;
    return GestureDetector(
      onTap: () => _set(_draft.copyWith(
          targetDate: DateTime(date.year, date.month, date.day))),
      child: AnnivPill(label,
          tone: selected ? AnnivPillTone.brand : AnnivPillTone.neutral),
    );
  }

  Future<void> _pickIcon() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.anniv.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _IconPickerSheet(
        color: _draft.displayColor,
        selected: _draft.iconCodePoint,
        onPick: (cp) {
          _set(_draft.copyWith(iconCodePoint: () => cp));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

/// Icon picker with a シンプル/ライン tab. Applying a custom icon is gated behind
/// one rewarded-ad view per icon (`AppSettings.unlockedIconCodePoints`); once an
/// icon is unlocked it is free forever. "テンプレートに戻す" is always free.
class _IconPickerSheet extends ConsumerStatefulWidget {
  const _IconPickerSheet({
    required this.color,
    required this.selected,
    required this.onPick,
  });

  final Color color;
  final int? selected;

  /// null = "back to template icon".
  final ValueChanged<int?> onPick;

  @override
  ConsumerState<_IconPickerSheet> createState() => _IconPickerSheetState();
}

class _IconPickerSheetState extends ConsumerState<_IconPickerSheet> {
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
                  child: _Segmented(
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

// ------------------------------------------------------------------ widgets ---

class _StepScroll extends StatelessWidget {
  const _StepScroll({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 8, AppSpacing.screenH, 24),
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w900, color: a.ink)),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _WizardBar extends StatelessWidget {
  const _WizardBar({
    required this.onCancel,
    required this.onBack,
    required this.nextLabel,
    required this.onNext,
    this.busy = false,
  });

  final VoidCallback onCancel;
  final VoidCallback? onBack;
  final String nextLabel;
  final VoidCallback onNext;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.screenH, 10, AppSpacing.screenH,
          10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: a.bg,
        border: Border(top: BorderSide(color: a.line)),
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: busy ? null : (onBack ?? onCancel),
            child: Text(onBack == null ? 'キャンセル' : '戻る'),
          ),
          const Spacer(),
          SizedBox(
            width: 152,
            child: FilledButton(
              onPressed: busy ? null : onNext,
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(nextLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.selected,
    required this.onTap,
  });

  final EventTemplate template;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: a.surface,
          borderRadius: AppRadius.cardBr,
          border: Border.all(
            color: selected ? template.color : a.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnnivIconChip(icon: template.icon, color: template.color, size: 40),
            const SizedBox(height: 10),
            Text(template.label,
                style: TextStyle(
                    fontWeight: FontWeight.w900, color: a.ink, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              template.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: a.sub, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
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

class _RadioTile<T> extends StatelessWidget {
  const _RadioTile({
    required this.value,
    required this.group,
    required this.title,
    required this.example,
    required this.onChanged,
  });

  final T value;
  final T group;
  final String title;
  final String example;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    final selected = value == group;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: a.surface,
          borderRadius: AppRadius.rowBr,
          border: Border.all(
              color: selected ? a.brand : a.line, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? a.brand : a.faint,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w900, color: a.ink)),
                  const SizedBox(height: 2),
                  Text(example,
                      style: TextStyle(color: a.sub, fontSize: 12.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: a.surface,
        borderRadius: AppRadius.rowBr,
        border: Border.all(color: a.line),
      ),
      child: Row(
        children: [
          AnnivIconChip(icon: icon, color: a.sub, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w900, color: a.ink)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(color: a.sub, fontSize: 12)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _GroupPicker extends ConsumerWidget {
  const _GroupPicker({required this.draft, required this.onChanged});
  final Event draft;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    if (groups.isEmpty) return const SizedBox.shrink();
    return DropdownButtonFormField<String?>(
      initialValue: draft.groupId,
      decoration: const InputDecoration(labelText: 'グループ'),
      items: [
        const DropdownMenuItem(value: null, child: Text('なし')),
        for (final g in groups)
          DropdownMenuItem(value: g.id, child: Text(g.name)),
      ],
      onChanged: onChanged,
    );
  }
}
