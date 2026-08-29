import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/time/clock.dart';
import '../../events/application/event_providers.dart';
import '../../settings/application/settings_providers.dart';
import '../data/notification_service.dart';
import '../domain/notification_plan.dart';

/// Bound in `main()` on mobile with [FlutterLocalNotificationService]. The
/// default no-ops so tests and desktop dev builds don't need the plugin.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => const NoopNotificationService(),
);

/// The bounded, time-ordered notification set derived from the current events
/// and settings. Recomputes whenever either changes.
final notificationPlanProvider = Provider<List<ScheduledNotification>>((ref) {
  final events = ref.watch(eventsProvider);
  final settings = ref.watch(settingsProvider);
  final now = ref.watch(clockProvider).now();
  return NotificationPlanner.plan(events: events, settings: settings, now: now);
});

/// Keep-alive side effect: mirror [notificationPlanProvider] onto the OS
/// scheduler. Watching this once (in `AnnivApp`) also triggers the
/// reschedule-on-startup pass.
final notificationSyncProvider = Provider<void>((ref) {
  final service = ref.watch(notificationServiceProvider);
  final plan = ref.watch(notificationPlanProvider);
  Future<void>(() => service.sync(plan));
});
