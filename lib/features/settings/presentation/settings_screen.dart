import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/day_time.dart';
import '../../groups/application/group_providers.dart';
import '../application/settings_providers.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const _Header('通知'),
          ListTile(
            title: const Text('既定の通知時刻'),
            subtitle: const Text('新しい通知に使われる時刻'),
            trailing: Text(settings.defaultNotifyTime.format(),
                style: Theme.of(context).textTheme.titleMedium),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: settings.defaultNotifyTime.hour,
                  minute: settings.defaultNotifyTime.minute,
                ),
              );
              if (picked != null) {
                await notifier.update((s) => s.copyWith(
                    defaultNotifyTime: DayTime(picked.hour, picked.minute)));
              }
            },
          ),
          const Divider(height: 1),
          const _Header('表示'),
          ListTile(
            title: const Text('カードの既定表示'),
            trailing: DropdownButton<DisplayFormat>(
              value: settings.displayFormat,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                    value: DisplayFormat.daysLeft, child: Text('残り日数')),
                DropdownMenuItem(value: DisplayFormat.date, child: Text('日付')),
              ],
              onChanged: (v) => v == null
                  ? null
                  : notifier.update((s) => s.copyWith(displayFormat: v)),
            ),
          ),
          ListTile(
            title: const Text('週の開始曜日'),
            trailing: DropdownButton<WeekStart>(
              value: settings.weekStart,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: WeekStart.sunday, child: Text('日曜')),
                DropdownMenuItem(value: WeekStart.monday, child: Text('月曜')),
              ],
              onChanged: (v) => v == null
                  ? null
                  : notifier.update((s) => s.copyWith(weekStart: v)),
            ),
          ),
          ListTile(
            title: const Text('テーマ'),
            trailing: DropdownButton<AppThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                    value: AppThemeMode.system, child: Text('システム')),
                DropdownMenuItem(value: AppThemeMode.light, child: Text('ライト')),
                DropdownMenuItem(value: AppThemeMode.dark, child: Text('ダーク')),
              ],
              onChanged: (v) => v == null
                  ? null
                  : notifier.update((s) => s.copyWith(themeMode: v)),
            ),
          ),
          const Divider(height: 1),
          const _Header('グループ'),
          const _GroupManager(),
          const Divider(height: 1),
          const _Header('データ'),
          const ListTile(
            title: Text('バックアップ / 復元'),
            subtitle: Text('JSON書き出し — 近日対応（Sprint 4）'),
            enabled: false,
          ),
          const ListTile(
            title: Text('広告を非表示にする'),
            subtitle: Text('買い切り — 近日対応（Sprint 5）'),
            enabled: false,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}

class _GroupManager extends ConsumerWidget {
  const _GroupManager();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    return Column(
      children: [
        for (final g in groups)
          ListTile(
            title: Text(g.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () =>
                  ref.read(groupsProvider.notifier).delete(g.id),
            ),
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('グループを追加'),
          onTap: () async {
            final name = await _promptName(context);
            if (name != null && name.trim().isNotEmpty) {
              await ref.read(groupsProvider.notifier).add(name.trim());
            }
          },
        ),
      ],
    );
  }

  Future<String?> _promptName(BuildContext context) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('グループ名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '例：家族 / 仕事'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('追加')),
        ],
      ),
    );
  }
}
