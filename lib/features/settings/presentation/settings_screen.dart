import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/app_info.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/anniv_widgets.dart';
import '../../../core/time/day_time.dart';
import '../../ads/application/ad_providers.dart';
import '../../ads/presentation/banner_ad_widget.dart';
import '../../backup/application/backup_controller.dart';
import '../../backup/domain/backup_codec.dart';
import '../../groups/application/group_providers.dart';
import '../../purchase/application/purchase_providers.dart';
import '../application/settings_providers.dart';
import '../domain/app_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      appBar: AppBar(
        title: Text('設定',
            style: TextStyle(
                color: context.anniv.brand,
                fontSize: 16,
                fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, 8, AppSpacing.screenH, 40),
        children: [
          const SectionLabel('通知'),
          _Group(children: [
            _Row(
              icon: Icons.schedule,
              title: '既定の通知時刻',
              subtitle: '新規イベントの通知時刻',
              trailing: Text(settings.defaultNotifyTime.format(),
                  style: _valueStyle(context)),
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
            _Row(
              icon: Icons.calendar_today_outlined,
              title: '表示形式',
              subtitle: '一覧の日付の見せ方',
              trailing: _InlineDropdown<DisplayFormat>(
                value: settings.displayFormat,
                items: const {
                  DisplayFormat.daysLeft: '残り日数',
                  DisplayFormat.date: '日付',
                },
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(displayFormat: v)),
              ),
            ),
            _Row(
              icon: Icons.view_week_outlined,
              title: '週の開始曜日',
              trailing: _InlineDropdown<WeekStart>(
                value: settings.weekStart,
                items: const {
                  WeekStart.sunday: '日曜',
                  WeekStart.monday: '月曜',
                },
                onChanged: (v) =>
                    notifier.update((s) => s.copyWith(weekStart: v)),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          const SectionLabel('テーマ'),
          _Group(children: [
            _Row(
              icon: Icons.dark_mode_outlined,
              title: 'ダークモード',
              trailing: Switch(
                value: settings.themeMode == AppThemeMode.dark,
                onChanged: (on) => notifier.update((s) => s.copyWith(
                    themeMode:
                        on ? AppThemeMode.dark : AppThemeMode.light)),
              ),
            ),
            _Row(
              icon: Icons.brightness_auto_outlined,
              title: '端末の設定に合わせる',
              trailing: Switch(
                value: settings.themeMode == AppThemeMode.system,
                onChanged: (on) => notifier.update((s) => s.copyWith(
                    themeMode:
                        on ? AppThemeMode.system : AppThemeMode.light)),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          const SectionLabel('グループ'),
          _Group(children: [const _GroupManager()]),
          const SizedBox(height: 20),
          const SectionLabel('データ'),
          _Group(children: [
            _Row(
              icon: Icons.upload_outlined,
              title: 'バックアップ',
              subtitle: '全イベントを JSON で書き出し',
              onTap: () => _exportBackup(context, ref),
            ),
            _Row(
              icon: Icons.download_outlined,
              title: '復元',
              subtitle: 'バックアップから読み込み',
              onTap: () => _restoreBackup(context, ref),
            ),
            _Row(
              icon: Icons.visibility_off_outlined,
              title: '非表示にしたイベント',
              subtitle: '表示に戻すにはここから',
              onTap: () => context.push('/settings/hidden-events'),
            ),
          ]),
          const SizedBox(height: 20),
          const SectionLabel('アプリ'),
          _Group(children: [
            const _RemoveAdsRow(),
            _Row(
              icon: Icons.info_outline,
              title: 'バージョン',
              trailing: Text(AppInfo.version, style: _valueStyle(context)),
            ),
            _Row(
              icon: Icons.privacy_tip_outlined,
              title: 'プライバシーポリシー',
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _openUrl(context, AppInfo.privacyPolicyUrl),
            ),
            _Row(
              icon: Icons.description_outlined,
              title: 'オープンソースライセンス',
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppInfo.appName,
                applicationVersion: AppInfo.version,
                applicationLegalese: AppInfo.legalese,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  static TextStyle _valueStyle(BuildContext context) => TextStyle(
        color: context.anniv.ink,
        fontWeight: FontWeight.w900,
        fontSize: 14,
      );

  Future<void> _openUrl(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
      if (!ok) {
        messenger.showSnackBar(
            const SnackBar(content: Text('ページを開けませんでした')));
      }
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('ページを開けませんでした')));
    }
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(backupControllerProvider).shareBackup();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('書き出しに失敗しました：$e')));
    }
  }

  Future<void> _restoreBackup(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    final source = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('バックアップから復元'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('書き出した JSON を貼り付けてください。'
                '現在のデータはすべて置き換えられます。'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: '{ "app": "anniv", ... }',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          FilledButton(
              style: dialogActionStyle,
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('復元')),
        ],
      ),
    );

    if (source == null || source.trim().isEmpty) return;
    try {
      final count =
          await ref.read(backupControllerProvider).restoreFromJson(source);
      messenger.showSnackBar(
          SnackBar(content: Text('$count 件の記念日を復元しました')));
    } on BackupFormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('復元に失敗しました：$e')));
    }
  }
}

/// A rounded card wrapping a set of [_Row]s, dividers drawn between them.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return AnnivCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: a.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            AnnivIconChip(icon: icon, color: a.sub, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: a.ink)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(fontSize: 12, color: a.sub)),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

class _InlineDropdown<T> extends StatelessWidget {
  const _InlineDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final Map<T, String> items;
  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      underline: const SizedBox.shrink(),
      style: SettingsScreen._valueStyle(context),
      items: [
        for (final e in items.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (v) => v == null ? null : onChanged(v),
    );
  }
}

class _RemoveAdsRow extends ConsumerWidget {
  const _RemoveAdsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = context.anniv;
    final removed = ref.watch(adsRemovedProvider);
    if (removed) {
      return _Row(
        icon: Icons.check_circle_outline,
        title: '広告を非表示にしました',
        subtitle: 'ご購入ありがとうございます',
      );
    }

    final purchase = ref.watch(purchaseControllerProvider);
    final controller = ref.read(purchaseControllerProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    if (!purchase.storeAvailable) {
      return _Row(
        icon: Icons.block_outlined,
        title: '広告を除去する',
        subtitle: '現在ストアに接続できません',
      );
    }

    final price =
        purchase.priceLabel.isEmpty ? '買い切り' : purchase.priceLabel;

    return Column(
      children: [
        _Row(
          icon: Icons.block_outlined,
          title: '広告を除去する',
          subtitle: 'バナー除去（一度の購入でずっと）',
          trailing: purchase.pending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(price,
                  style: TextStyle(
                      color: a.brand,
                      fontWeight: FontWeight.w900,
                      fontSize: 14)),
          onTap: (purchase.pending || purchase.removeAdsProduct == null)
              ? null
              : () {
                  if (purchase.error != null) {
                    messenger.showSnackBar(
                        SnackBar(content: Text(purchase.error!)));
                  }
                  controller.buyRemoveAds();
                },
        ),
        Divider(height: 1, color: a.line),
        _Row(
          icon: Icons.restore,
          title: '購入を復元',
          onTap: purchase.pending ? null : () => controller.restore(),
        ),
      ],
    );
  }
}

class _GroupManager extends ConsumerStatefulWidget {
  const _GroupManager();

  @override
  ConsumerState<_GroupManager> createState() => _GroupManagerState();
}

class _GroupManagerState extends ConsumerState<_GroupManager> {
  bool _busy = false;

  Future<void> _addGroup() async {
    if (_busy) return;
    final messenger = ScaffoldMessenger.of(context);

    // Every group-add costs one rewarded-ad view (unless ads are removed).
    if (ref.read(adsEnabledProvider)) {
      setState(() => _busy = true);
      final earned = await ref.read(rewardedAdServiceProvider).showForReward();
      if (!mounted) return;
      setState(() => _busy = false);
      if (!earned) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('広告を再生できませんでした。もう一度お試しください。'),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    final name = await _promptName(context);
    if (name != null && name.trim().isNotEmpty) {
      await ref.read(groupsProvider.notifier).add(name.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    final groups = ref.watch(groupsProvider);
    final adGated = ref.watch(adsEnabledProvider);
    return Column(
      children: [
        for (final g in groups)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(Icons.folder_outlined, size: 18, color: a.sub),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(g.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: a.ink)),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline, color: a.faint),
                  onPressed: () async {
                    final ok = await confirmDialog(
                      context,
                      title: 'グループを削除しますか？',
                      message: '「${g.name}」を削除します。このグループに属するイベント自体は削除されません。',
                      confirmLabel: '削除',
                    );
                    if (ok) {
                      await ref.read(groupsProvider.notifier).delete(g.id);
                    }
                  },
                ),
              ],
            ),
          ),
        InkWell(
          onTap: _busy ? null : _addGroup,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(Icons.add, size: 18, color: a.brand),
                const SizedBox(width: 12),
                Text('グループを追加',
                    style: TextStyle(
                        color: a.brand, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (_busy)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (adGated) ...[
                  Icon(Icons.play_circle_outline, size: 14, color: a.sub),
                  const SizedBox(width: 4),
                  Text('広告を見る',
                      style: TextStyle(fontSize: 11, color: a.sub)),
                ],
              ],
            ),
          ),
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
              style: dialogActionStyle,
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('追加')),
        ],
      ),
    );
  }
}
