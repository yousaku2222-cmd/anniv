import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anniv'),
        actions: [
          IconButton(
            tooltip: '設定',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/event/new'),
        icon: const Icon(Icons.add),
        label: const Text('追加'),
      ),
      body: Column(
        children: [
          if (groups.isNotEmpty)
            _GroupFilterBar(
              selected: filter,
              onSelected: (id) => ref.read(groupFilterProvider.notifier).set(id),
            ),
          Expanded(
            child: events.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: events.length,
                    itemBuilder: (context, i) => _EventCard(event: events[i]),
                  ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class _GroupFilterBar extends ConsumerWidget {
  const _GroupFilterBar({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('すべて'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final g in groups)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(g.name),
                selected: selected == g.id,
                onSelected: (_) => onSelected(g.id),
              ),
            ),
        ],
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
    final label = CountLabel.of(event, today);
    final color = event.displayColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/event/${event.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                foregroundColor: color,
                child: Icon(event.displayIcon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label.caption,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    label.big,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (label.unit.isNotEmpty) ...[
                    const SizedBox(width: 2),
                    Text(label.unit,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('まだ何も登録されていません',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              '右下の「追加」から、誕生日や記念日を登録しましょう。',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
