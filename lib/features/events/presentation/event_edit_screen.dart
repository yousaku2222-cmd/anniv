import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../groups/application/group_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../application/event_providers.dart';
import '../domain/event.dart';
import '../domain/event_templates.dart';
import 'event_presentation.dart';

class EventEditScreen extends ConsumerStatefulWidget {
  const EventEditScreen({super.key, this.eventId});

  /// Null when creating a new event.
  final String? eventId;

  bool get isCreating => eventId == null;

  @override
  ConsumerState<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends ConsumerState<EventEditScreen> {
  late Event _draft;
  late final TextEditingController _titleController;
  bool _initialised = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    if (widget.isCreating) {
      _draft = ref.read(eventsProvider.notifier).draftFromTemplate(EventType.birthday);
    } else {
      final existing = ref.read(eventsProvider.notifier).byId(widget.eventId!);
      _draft = existing ??
          ref.read(eventsProvider.notifier).draftFromTemplate(EventType.custom);
      _titleController.text = _draft.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _applyTemplate(EventType type) {
    final t = EventTemplate.forType(type);
    setState(() {
      _draft = _draft.copyWith(
        type: type,
        repeat: t.defaultRepeat,
        countMode: t.defaultCountMode,
        notifications: t.buildNotifications(),
        milestones: t.buildMilestones(),
      );
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.targetDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _draft = _draft.copyWith(
          targetDate: DateTime(picked.year, picked.month, picked.day)));
    }
  }

  void _toggleNotification(int offsetDays, bool on) {
    final time = ref.read(settingsProvider).defaultNotifyTime;
    final next = [..._draft.notifications];
    next.removeWhere((n) => n.offsetDays == offsetDays);
    if (on) next.add(NotificationRule(offsetDays: offsetDays, time: time));
    next.sort((a, b) => a.offsetDays.compareTo(b.offsetDays));
    setState(() => _draft = _draft.copyWith(notifications: next));
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('タイトルを入力してください')));
      return;
    }
    await ref.read(eventsProvider.notifier).save(_draft.copyWith(title: title));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);
    final enabledOffsets =
        _draft.notifications.map((n) => n.offsetDays).toSet();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCreating ? '新しい記念日' : '編集'),
        actions: [
          TextButton(onPressed: _save, child: const Text('保存')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (widget.isCreating) ...[
            const _SectionLabel('テンプレート'),
            Wrap(
              spacing: 8,
              children: [
                for (final t in EventTemplate.all)
                  ChoiceChip(
                    avatar: Icon(t.icon, size: 18),
                    label: Text(t.label),
                    selected: _draft.type == t.type,
                    onSelected: (_) => _applyTemplate(t.type),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          const _SectionLabel('タイトル'),
          TextField(
            controller: _titleController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: '例：母の誕生日 / 入籍記念日',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('日付'),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Align(
              alignment: Alignment.centerLeft,
              child: Text(formatFullDate(_draft.targetDate)),
            ),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('カウント方法'),
          SegmentedButton<CountMode>(
            segments: const [
              ButtonSegment(value: CountMode.daysLeft, label: Text('あと何日')),
              ButtonSegment(value: CountMode.daysSince, label: Text('経過日数')),
            ],
            selected: {_draft.countMode},
            onSelectionChanged: (s) =>
                setState(() => _draft = _draft.copyWith(countMode: s.first)),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('繰り返し'),
          Wrap(
            spacing: 8,
            children: [
              for (final r in RepeatRule.values)
                ChoiceChip(
                  label: Text(repeatLabel(r)),
                  selected: _draft.repeat == r,
                  onSelected: (_) =>
                      setState(() => _draft = _draft.copyWith(repeat: r)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (groups.isNotEmpty) ...[
            const _SectionLabel('グループ'),
            DropdownButtonFormField<String?>(
              initialValue: _draft.groupId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('なし')),
                for (final g in groups)
                  DropdownMenuItem(value: g.id, child: Text(g.name)),
              ],
              onChanged: (v) =>
                  setState(() => _draft = _draft.copyWith(groupId: () => v)),
            ),
            const SizedBox(height: 20),
          ],
          const _SectionLabel('通知'),
          for (final offset in NotificationRule.presetOffsets)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(notificationOffsetLabel(offset)),
              value: enabledOffsets.contains(offset),
              onChanged: (v) => _toggleNotification(offset, v ?? false),
            ),
          const SizedBox(height: 8),
          Text(
            '通知時刻は設定の「既定の通知時刻」に従います。',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
}
