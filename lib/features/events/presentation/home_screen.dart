import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/anniv_widgets.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/time/clock.dart';
import '../../ads/presentation/banner_ad_widget.dart';
import '../../groups/application/group_providers.dart';
import '../application/event_providers.dart';
import '../domain/event.dart';
import '../domain/event_templates.dart';
import 'event_presentation.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(visibleEventsProvider);
    final groups = ref.watch(groupsProvider);
    final filter = ref.watch(groupFilterProvider);
    final today = ref.watch(todayProvider);
    final a = context.anniv;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(today: today),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
                children: [
                  _Tab(
                    label: 'すべて',
                    selected: filter == null,
                    onTap: () =>
                        ref.read(groupFilterProvider.notifier).set(null),
                  ),
                  for (final g in groups)
                    _Tab(
                      label: g.name,
                      selected: filter == g.id,
                      onTap: () =>
                          ref.read(groupFilterProvider.notifier).set(g.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: events.isEmpty
                  ? const _EmptyState()
                  : Stack(
                      children: [
                        ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.screenH, 8, AppSpacing.screenH, 108),
                          itemCount: events.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.cardGap),
                          itemBuilder: (context, i) =>
                              _EventCard(event: events[i]),
                        ),
                        Positioned(
                          right: AppSpacing.screenH,
                          bottom: 20,
                          child: GradientFab(
                            onPressed: () => context.push('/event/new'),
                          ),
                        ),
                      ],
                    ),
            ),
            Container(
              color: a.bg,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom),
              child: const BannerAdWidget(),
            ),
          ],
        ),
      ),
      floatingActionButton: events.isEmpty
          ? GradientFab(onPressed: () => context.push('/event/new'))
          : null,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.today});
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    final dateText = DateFormat('M月d日(E)', 'ja').format(today);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 12, AppSpacing.screenH, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(),
              const SizedBox(width: AppSpacing.headerGap),
              Text(
                'Anniv',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: a.ink,
                ),
              ),
              const Spacer(),
              _HeaderButton(
                icon: Icons.widgets_outlined,
                tooltip: 'ウィジェット',
                onTap: () => context.push('/widget'),
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                icon: Icons.tune_rounded,
                tooltip: '設定',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$dateText — 今日も、大切な日が近づいています',
            style: TextStyle(fontSize: 12, color: a.sub),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton(
      {required this.icon, required this.onTap, required this.tooltip});
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: a.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: a.line),
          ),
          child: Icon(icon, size: 20, color: a.ink),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: selected ? a.ink : a.surface,
            borderRadius: AppRadius.pillBr,
            border: Border.all(color: selected ? a.ink : a.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? a.bg : a.sub,
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);
    final a = context.anniv;
    final label = CountLabel.of(event, today);
    final color = event.displayColor;

    final hot = hotPillText(event, today);
    final repeat = repeatChipText(event.repeat);
    final groupName = ref.watch(groupNameProvider(event.groupId));
    final midChip = repeat ?? event.template.label;
    final trailingRaw = (hot != null || repeat != null)
        ? (groupName ?? formatDotDate(event.targetDate))
        : (groupName ?? formatShortDate(event.targetDate));
    // Don't show the same label twice (e.g. an 推し活 event in the 推し活 group).
    final trailingChip = trailingRaw == midChip ? null : trailingRaw;

    return AnnivCard(
      onTap: () => context.push('/event/${event.id}'),
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: AppSpacing.cardAccentBar,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadius.card)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                child: Row(
                  children: [
                    AnnivIconChip(icon: event.displayIcon, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: a.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (hot != null)
                                AnnivPill(hot, tone: AnnivPillTone.brand),
                              AnnivPill(midChip, tone: AnnivPillTone.neutral),
                              if (trailingChip != null)
                                AnnivPill(trailingChip,
                                    tone: AnnivPillTone.neutral),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(label.big, style: AppNumeral.card(color)),
                            if (label.unit.isNotEmpty) ...[
                              const SizedBox(width: 2),
                              Text(
                                label.unit,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: a.sub,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          label.kind,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: a.faint,
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.chevron_right_rounded, color: a.faint),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final a = context.anniv;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined, size: 64, color: a.faint),
            const SizedBox(height: 16),
            Text(
              'まだ何も登録されていません',
              style: TextStyle(
                  fontSize: 15.5, fontWeight: FontWeight.w700, color: a.ink),
            ),
            const SizedBox(height: 8),
            Text(
              '右下の「＋」から、誕生日や記念日を登録しましょう。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: a.sub),
            ),
          ],
        ),
      ),
    );
  }
}
