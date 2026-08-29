import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock.dart';
import '../../events/application/event_providers.dart';
import '../data/home_widget_service.dart';
import '../domain/widget_snapshot.dart';

/// Bound in `main()` on mobile with [AppHomeWidgetService].
final homeWidgetServiceProvider = Provider<HomeWidgetService>(
  (ref) => const NoopHomeWidgetService(),
);

final widgetSnapshotProvider = Provider<WidgetSnapshot>((ref) {
  final events = ref.watch(eventsProvider);
  final today = ref.watch(todayProvider);
  return WidgetSnapshotBuilder.of(events, today);
});

/// Keep-alive side effect: push the snapshot to the OS widget whenever it
/// changes (and once on startup, since `AnnivApp` watches it).
final homeWidgetSyncProvider = Provider<void>((ref) {
  final service = ref.watch(homeWidgetServiceProvider);
  final snapshot = ref.watch(widgetSnapshotProvider);
  Future<void>(() => service.render(snapshot));
});
