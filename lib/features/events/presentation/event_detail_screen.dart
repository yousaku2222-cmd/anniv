import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/anniv_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/clock.dart';
import '../../ads/presentation/banner_ad_widget.dart';
import '../../groups/application/group_providers.dart';
import '../application/event_providers.dart';
import '../domain/countdown.dart';
import '../domain/event.dart';
import '../domain/event_templates.dart';
import 'event_presentation.dart';

class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventByIdProvider(eventId));
    final a = context.anniv;
    if (event == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('この記念日は見つかりませんでした')),
      );
    }

    final today = ref.watch(todayProvider);
    final label = CountLabel.of(event, today);
    final milestone = Countdown.upcomingMilestone(event, today);
    final milestones = Countdown.allMilestones(event, today);
    final color = event.displayColor;
    final groupName = ref.watch(groupNameProvider(event.groupId));

    return Scaffold(
      bottomNavigationBar: const BannerAdSlot(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Hero(
            event: event,
            label: label,
            color: color,
            groupName: groupName,
            milestone: milestone,
            onBack: () => context.pop(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, 18, AppSpacing.screenH, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActionRow(
                  onEdit: () => context.push('/event/$eventId/edit'),
                  onShare: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('共有（画像化）は近日対応します')),
                  ),
                  onHide: () => _hide(context, ref),
                  onDelete: () => _confirmDelete(context, ref),
                ),
                const SizedBox(height: 18),
                SectionLabel('基本情報'),
                AnnivCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'グループ',
                        trailing: groupName == null
                            ? Text('なし', style: TextStyle(color: a.sub))
                            : AnnivPill(groupName),
                      ),
                      _divider(a),
                      _InfoRow(
                        label: 'カウント方法',
                        value: countModeLabel(event.countMode),
                      ),
                      _divider(a),
                      _InfoRow(
                        label: '繰り返し',
                        value: repeatValueLabel(event.repeat),
                      ),
                      _divider(a),
                      _InfoRow(
                        label: '登録日',
                        value: formatDotDate(event.createdAt),
                      ),
                      if (event.isLunar) ...[
                        _divider(a),
                        _InfoRow(label: '暦', value: '旧暦（変換は未対応）'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SectionLabel('通知スケジュール'),
                AnnivCard(
                  child: event.notifications.isEmpty
                      ? Row(
                          children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 18, color: a.faint),
                            const SizedBox(width: 8),
                            Text('通知はオフです', style: TextStyle(color: a.sub)),
                          ],
                        )
                      : Column(
                          children: [
                            for (final n in ([...event.notifications]
                              ..sort((x, y) =>
                                  x.offsetDays.compareTo(y.offsetDays))))
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Icon(Icons.notifications_active_outlined,
                                        size: 18, color: color),
                                    const SizedBox(width: 10),
                                    Text(
                                      notificationOffsetLabel(n.offsetDays),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: a.ink),
                                    ),
                                    const Spacer(),
                                    Text(n.time.format(),
                                        style: TextStyle(color: a.sub)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                ),
                if (milestones.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  SectionLabel('マイルストーン'),
                  AnnivCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < milestones.length; i++) ...[
                          if (i > 0) _divider(a),
                          _MilestoneRow(
                            entry: milestones[i],
                            before: Countdown.milestoneIsBefore(event),
                            color: color,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(AnnivColors a) => Divider(height: 18, color: a.line);

  Future<void> _hide(BuildContext context, WidgetRef ref) async {
    await ref.read(eventsProvider.notifier).setHidden(eventId, hidden: true);
    if (context.mounted) context.pop();
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
      await ref.read(eventsProvider.notifier).delete(eventId);
      if (context.mounted) context.pop();
    }
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.event,
    required this.label,
    required this.color,
    required this.groupName,
    required this.milestone,
    required this.onBack,
  });

  final Event event;
  final CountLabel label;
  final Color color;
  final String? groupName;
  final ({int days, DateTime date, int daysAway})? milestone;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(AppSpacing.screenH, top + 8, AppSpacing.screenH, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, 0.18)!,
            Color.lerp(color, Colors.black, 0.12)!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.18),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: Text(label.big, style: AppNumeral.hero(Colors.white)),
                ),
              ),
              if (label.unit.isNotEmpty) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    label.unit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Text(
            event.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                formatFullDate(Countdown.nextOccurrence(
                    event, DateTime.now())),
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
              if (groupName != null) ...[
                const SizedBox(width: 8),
                _GlassPill(text: groupName!),
              ],
            ],
          ),
          if (milestone != null) ...[
            const SizedBox(height: 16),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: AppRadius.rowBr,
                border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Text('🎌 ', style: TextStyle(fontSize: 13)),
                  Expanded(
                    child: Text(
                      milestonePillText(milestone!, event),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: AppRadius.pillBr,
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onEdit,
    required this.onShare,
    required this.onHide,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onHide;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return Row(
      children: [
        _action(context, Icons.edit_outlined, '編集', onEdit, a.ink),
        _action(context, Icons.ios_share, '共有', onShare, a.ink),
        _action(
            context, Icons.visibility_off_outlined, '非表示', onHide, a.ink),
        _action(context, Icons.delete_outline, '削除', onDelete,
            const Color(0xFFD8503C)),
      ],
    );
  }

  Widget _action(BuildContext context, IconData icon, String label,
      VoidCallback onTap, Color tint) {
    final a = context.anniv;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.rowBr,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: a.surface,
              borderRadius: AppRadius.rowBr,
              border: Border.all(color: a.line),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: tint),
                const SizedBox(height: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: tint)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, this.value, this.trailing});
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return Row(
      children: [
        Text(label, style: TextStyle(color: a.sub, fontSize: 13)),
        const Spacer(),
        trailing ??
            Text(
              value ?? '',
              style: TextStyle(
                  color: a.ink, fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
      ],
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow(
      {required this.entry, required this.before, required this.color});

  final ({int days, DateTime date, int daysAway, bool passed}) entry;
  final bool before;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    final noun = before ? '${entry.days}日前' : '${entry.days}日目';
    return Row(
      children: [
        Icon(
          entry.passed ? Icons.check_circle : Icons.flag_outlined,
          size: 18,
          color: entry.passed ? a.faint : color,
        ),
        const SizedBox(width: 10),
        Text(noun,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: entry.passed ? a.faint : a.ink)),
        const Spacer(),
        Text(
          entry.passed
              ? '通過済み'
              : (entry.daysAway == 0 ? '今日' : 'あと${entry.daysAway}日'),
          style: TextStyle(
              color: entry.passed ? a.faint : a.sub, fontSize: 12.5),
        ),
        const SizedBox(width: 8),
        Text(formatDotDate(entry.date),
            style: TextStyle(color: a.faint, fontSize: 11)),
      ],
    );
  }
}
