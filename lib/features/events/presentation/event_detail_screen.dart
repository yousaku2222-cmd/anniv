import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/time/clock.dart';
import '../../groups/application/group_providers.dart';
import '../application/event_providers.dart';
import '../domain/countdown.dart';
import '../domain/event_templates.dart';
import 'event_presentation.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(eventId));
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('この記念日は見つかりませんでした')),
      );
    }

    final today = ref.watch(todayProvider);
    final label = CountLabel.of(event, today);
    final milestone = Countdown.upcomingMilestone(event, today);
    final color = event.displayColor;
    final groups = ref.watch(groupsProvider);
    String? groupName;
    if (event.groupId != null) {
      for (final g in groups) {
        if (g.id == event.groupId) {
          groupName = g.name;
          break;
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '編集',
            onPressed: () => context.push('/event/$eventId/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) => _onMenu(context, ref, v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'hide', child: Text('非表示にする')),
              PopupMenuItem(value: 'delete', child: Text('削除')),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            color: color.withValues(alpha: 0.10),
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: color.withValues(alpha: 0.18),
                  foregroundColor: color,
                  child: Icon(event.displayIcon, size: 30),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      label.big,
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(color: color, fontWeight: FontWeight.w800),
                    ),
                    if (label.unit.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 6),
                        child: Text(label.unit,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(label.caption,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (milestone != null)
            ListTile(
              leading: const Icon(Icons.local_fire_department_outlined),
              title: Text('次のマイルストーン：${milestone.days}日'),
              subtitle: Text(
                  '${formatFullDate(milestone.date)}（あと${milestone.daysAway}日）'),
            ),
          const Divider(height: 1),
          _row('日付', formatFullDate(event.targetDate)),
          _row('種類', EventTemplate.forType(event.type).label),
          _row('繰り返し', repeatLabel(event.repeat)),
          _row('カウント方法', countModeLabel(event.countMode)),
          if (groupName != null) _row('グループ', groupName),
          _row(
            '通知',
            event.notifications.isEmpty
                ? 'なし'
                : (event.notifications.toList()
                      ..sort((a, b) => a.offsetDays.compareTo(b.offsetDays)))
                    .map((n) =>
                        '${notificationOffsetLabel(n.offsetDays)} ${n.time.format()}')
                    .join(' / '),
          ),
          if (event.isLunar) _row('暦', '旧暦（変換は未対応）'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => ListTile(
        title: Text(label),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 220),
          child: Text(value, textAlign: TextAlign.end),
        ),
      );

  Future<void> _onMenu(BuildContext context, WidgetRef ref, String value) async {
    final notifier = ref.read(eventsProvider.notifier);
    if (value == 'hide') {
      await notifier.setHidden(eventId, hidden: true);
      if (context.mounted) context.pop();
      return;
    }
    if (value == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('削除しますか？'),
          content: const Text('この記念日を完全に削除します。元に戻せません。'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('キャンセル')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('削除')),
          ],
        ),
      );
      if (ok == true) {
        await notifier.delete(eventId);
        if (context.mounted) context.pop();
      }
    }
  }
}
