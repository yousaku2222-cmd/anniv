import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/theme/anniv_widgets.dart';
import '../application/event_providers.dart';
import '../domain/event_templates.dart';
import 'event_presentation.dart';

/// Lists events hidden via the detail screen's "非表示" action, with a way to
/// bring each one back. Without this screen, hiding an event was a one-way
/// trip — there was no UI path back to it at all.
class HiddenEventsScreen extends ConsumerWidget {
  const HiddenEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hidden =
        ref.watch(eventsProvider).where((e) => e.isHidden).toList();
    final a = context.anniv;

    return Scaffold(
      appBar: AppBar(title: const Text('非表示にしたイベント')),
      body: hidden.isEmpty
          ? Center(
              child: Text('非表示のイベントはありません',
                  style: TextStyle(color: a.sub, fontSize: 14)),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, 12, AppSpacing.screenH, 24),
              itemCount: hidden.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final event = hidden[i];
                return AnnivCard(
                  child: Row(
                    children: [
                      AnnivIconChip(
                          icon: event.displayIcon,
                          color: event.displayColor,
                          size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.title,
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: a.ink,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(formatFullDate(event.targetDate),
                                style: TextStyle(color: a.sub, fontSize: 12)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(eventsProvider.notifier)
                            .setHidden(event.id, hidden: false),
                        child: const Text('表示に戻す'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
